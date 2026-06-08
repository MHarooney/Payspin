/**
 * One-off maintenance: merge duplicate bank_accounts rows that share the same
 * user + normalized IBAN (common when Yapily connect ran before dedup existed).
 *
 * Usage:
 *   pnpm --filter @payspin/backend ops:dedupe-bank-accounts          # dry-run
 *   pnpm --filter @payspin/backend ops:dedupe-bank-accounts -- --apply
 */
import { PrismaClient } from '@prisma/client';
import { normalizeIban } from '@payspin/validators';
import { createDecipheriv } from 'node:crypto';

const prisma = new PrismaClient();
const apply = process.argv.includes('--apply');

function decryptIban(ciphertext: string, iv: string): string {
  const keyHex = process.env.IBAN_ENCRYPTION_KEY;
  if (!keyHex || keyHex.length !== 64) {
    throw new Error('IBAN_ENCRYPTION_KEY must be a 64-char hex string (32 bytes)');
  }
  const key = Buffer.from(keyHex, 'hex');
  const ivBuffer = Buffer.from(iv, 'base64');
  const payload = Buffer.from(ciphertext, 'base64');
  const tag = payload.subarray(payload.length - 16);
  const data = payload.subarray(0, payload.length - 16);
  const decipher = createDecipheriv('aes-256-gcm', key, ivBuffer);
  decipher.setAuthTag(tag);
  return Buffer.concat([decipher.update(data), decipher.final()]).toString('utf8');
}

type AccountRow = Awaited<ReturnType<typeof prisma.bankAccount.findMany>>[number];

function pickKeeper(accounts: AccountRow[]): AccountRow {
  return [...accounts].sort((a, b) => {
    if (a.isPrimary !== b.isPrimary) return a.isPrimary ? -1 : 1;
    if (a.verified !== b.verified) return a.verified ? -1 : 1;
    if (a.verificationSource === 'YAPILY' && b.verificationSource !== 'YAPILY') return -1;
    if (b.verificationSource === 'YAPILY' && a.verificationSource !== 'YAPILY') return 1;
    return a.createdAt.getTime() - b.createdAt.getTime();
  })[0];
}

async function main() {
  const accounts = await prisma.bankAccount.findMany({ orderBy: { createdAt: 'asc' } });
  const byUserIban = new Map<string, AccountRow[]>();

  for (const account of accounts) {
    let iban: string;
    try {
      iban = normalizeIban(decryptIban(account.ibanEncrypted, account.ibanIv));
    } catch (err) {
      console.warn(`skip ${account.id}: decrypt failed (${(err as Error).message})`);
      continue;
    }
    const key = `${account.userId}::${iban}`;
    const group = byUserIban.get(key) ?? [];
    group.push(account);
    byUserIban.set(key, group);
  }

  const duplicateGroups = [...byUserIban.values()].filter((g) => g.length > 1);
  if (!duplicateGroups.length) {
    console.log('No duplicate IBANs found.');
    return;
  }

  console.log(`${apply ? 'APPLY' : 'DRY-RUN'}: ${duplicateGroups.length} duplicate IBAN group(s)`);

  let removed = 0;
  let linksMoved = 0;
  let connectionsMoved = 0;

  for (const group of duplicateGroups) {
    const keeper = pickKeeper(group);
    const dupes = group.filter((a) => a.id !== keeper.id);
    const ibanLabel = `user=${keeper.userId} last4=${keeper.ibanLast4} keeper=${keeper.id}`;
    console.log(`\n${ibanLabel} — removing ${dupes.length} duplicate(s)`);

    for (const dupe of dupes) {
      const linkCount = await prisma.paymentLink.count({ where: { bankAccountId: dupe.id } });
      const connCount = await prisma.bankConnection.count({ where: { bankAccountId: dupe.id } });

      if (apply) {
        if (linkCount > 0) {
          const moved = await prisma.paymentLink.updateMany({
            where: { bankAccountId: dupe.id },
            data: { bankAccountId: keeper.id },
          });
          linksMoved += moved.count;
        }
        if (connCount > 0) {
          const moved = await prisma.bankConnection.updateMany({
            where: { bankAccountId: dupe.id },
            data: { bankAccountId: keeper.id },
          });
          connectionsMoved += moved.count;
        }
        await prisma.bankAccount.delete({ where: { id: dupe.id } });
      } else {
        console.log(`  would delete ${dupe.id} (links=${linkCount}, connections=${connCount})`);
      }
      removed += 1;
    }

    // Ensure keeper stays verified when any duplicate was Yapily-verified.
    const anyVerified = group.some((a) => a.verified);
    if (apply && anyVerified && !keeper.verified) {
      await prisma.bankAccount.update({
        where: { id: keeper.id },
        data: { verified: true, verificationSource: keeper.verificationSource ?? 'YAPILY' },
      });
    }
  }

  // One primary per user after cleanup.
  const userIds = [...new Set(duplicateGroups.flat().map((a) => a.userId))];
  for (const userId of userIds) {
    const remaining = await prisma.bankAccount.findMany({ where: { userId }, orderBy: { createdAt: 'asc' } });
    const primaries = remaining.filter((a) => a.isPrimary);
    if (primaries.length <= 1) continue;
    const keeperPrimary = primaries.sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime())[0];
    console.log(`\nuser ${userId}: demote extra primaries, keep ${keeperPrimary.id}`);
    if (apply) {
      await prisma.bankAccount.updateMany({
        where: { userId, id: { not: keeperPrimary.id } },
        data: { isPrimary: false },
      });
    }
  }

  console.log(
    `\nDone. duplicates ${removed}, links moved ${linksMoved}, connections moved ${connectionsMoved}` +
      (apply ? '' : ' (dry-run — pass --apply to execute)'),
  );
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
