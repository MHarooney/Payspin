import { normalizeIban } from '@payspin/validators';
import { EncryptionService } from '../../../infrastructure/encryption/encryption.service';

type EncryptedBankAccount = {
  id: string;
  ibanEncrypted: string;
  ibanIv: string;
};

/** Find a user's bank account whose decrypted IBAN matches (normalized). */
export function findBankAccountByIban<T extends EncryptedBankAccount>(
  accounts: T[],
  normalizedIban: string,
  encryption: Pick<EncryptionService, 'decrypt'>,
): T | undefined {
  const target = normalizeIban(normalizedIban);
  return accounts.find(
    (a) => normalizeIban(encryption.decrypt(a.ibanEncrypted, a.ibanIv)) === target,
  );
}
