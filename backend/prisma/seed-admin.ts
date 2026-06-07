/**
 * Seeds the Ops Admin Portal: a default admin user, feature flags, platform
 * config, app-controls config, and Phase 2 demo data (compliance alerts,
 * disputes, support threads). Idempotent — safe to run repeatedly.
 *
 *   cd backend && pnpm ops:seed-admin
 *
 * Override the default credentials with ADMIN_SEED_EMAIL / ADMIN_SEED_PASSWORD.
 */
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

const ADMIN_EMAIL = (process.env.ADMIN_SEED_EMAIL ?? 'admin@payspin.app').toLowerCase();
const ADMIN_PASSWORD = process.env.ADMIN_SEED_PASSWORD ?? 'PayspinOps!2026';

const FEATURE_FLAGS = [
  { key: 'rosca_circles', label: 'ROSCA savings circles', description: 'Enable group savings smart contracts', enabled: true, category: 'platform' },
  { key: 'payment_links', label: 'Shareable payment links', description: 'Tikkie-style request links', enabled: true, category: 'platform' },
  { key: 'new_signups', label: 'New signups', description: 'Allow onboarding of new users', enabled: true, category: 'platform' },
  { key: 'maintenance_mode', label: 'Maintenance mode', description: 'Show banner, pause writes', enabled: false, category: 'platform' },
  { key: 'float_yield', label: 'Float yield (Aave/Morpho)', description: 'Route idle float to earn yield', enabled: false, category: 'platform' },
  // App-controls modules (category: app)
  { key: 'app_send_request', label: 'Send / Request money', description: 'Core P2P payment links', enabled: true, category: 'app' },
  { key: 'app_circles_tile', label: 'Circles / ROSCA tile', description: 'Group savings entry point', enabled: true, category: 'app' },
  { key: 'app_activity_feed', label: 'Recent activity feed', description: 'Show last transactions', enabled: true, category: 'app' },
  { key: 'app_referral_banner', label: 'Referral banner', description: 'Invite-a-friend promo', enabled: false, category: 'app' },
  { key: 'app_float_card', label: 'Float yield card', description: 'Show earnings on balance', enabled: false, category: 'app' },
];

const PLATFORM_CONFIG = [
  { key: 'per_tx_max_kyc1', label: 'Per-transaction max (KYC1)', value: '500', valueType: 'eur', group: 'limits' },
  { key: 'daily_limit_kyc1', label: 'Daily limit (KYC1)', value: '1000', valueType: 'eur', group: 'limits' },
  { key: 'per_tx_max_kyc2', label: 'Per-transaction max (KYC2)', value: '5000', valueType: 'eur', group: 'limits' },
  { key: 'travel_rule_threshold', label: 'Travel Rule threshold', value: '1000', valueType: 'eur', group: 'limits' },
  { key: 'velocity_alert_5min', label: 'Velocity alert (tx / 5min)', value: '10', valueType: 'number', group: 'limits' },
  { key: 'escrow_hold_days', label: 'Escrow hold period (ROSCA)', value: '30', valueType: 'days', group: 'limits' },
  // App-side defaults (group: app)
  { key: 'app_quick_send', label: 'Default quick-send amounts', value: '10,25,50', valueType: 'string', group: 'app' },
  { key: 'app_min_version', label: 'Min app version (force update)', value: '1.4.0', valueType: 'string', group: 'app' },
  { key: 'app_onboarding_variant', label: 'Onboarding flow variant', value: 'B (3-step)', valueType: 'string', group: 'app' },
  { key: 'app_banner_text', label: 'Active in-app banner', value: 'Circles 2.0 is live — invite up to 12 members!', valueType: 'string', group: 'app' },
];

async function seedAdmin() {
  const passwordHash = await bcrypt.hash(ADMIN_PASSWORD, 10);
  const admin = await prisma.adminUser.upsert({
    where: { email: ADMIN_EMAIL },
    update: { passwordHash, isActive: true, role: 'SUPER_ADMIN' },
    create: {
      email: ADMIN_EMAIL,
      passwordHash,
      displayName: 'Ops Admin',
      role: 'SUPER_ADMIN',
    },
  });
  console.log(`✓ Admin user: ${admin.email} (SUPER_ADMIN)`);
}

async function seedFlagsAndConfig() {
  for (const f of FEATURE_FLAGS) {
    await prisma.featureFlag.upsert({ where: { key: f.key }, update: { label: f.label, description: f.description, category: f.category }, create: f });
  }
  for (const c of PLATFORM_CONFIG) {
    await prisma.platformConfig.upsert({ where: { key: c.key }, update: { label: c.label, valueType: c.valueType, group: c.group }, create: c });
  }
  console.log(`✓ ${FEATURE_FLAGS.length} feature flags, ${PLATFORM_CONFIG.length} config keys`);
}

async function seedPhase2() {
  if ((await prisma.complianceAlert.count()) === 0) {
    await prisma.complianceAlert.createMany({
      data: [
        { type: 'Velocity', subject: 'User #4821', rule: '14 tx / 5 min', severity: 'HIGH', status: 'INVESTIGATING' },
        { type: 'Structuring', subject: 'User #3902', rule: '6x €990 under threshold', severity: 'HIGH', status: 'OPEN' },
        { type: 'Travel Rule', subject: 'tx_9a2eff', subjectRef: 'tx_9a2eff', rule: 'Transfer >= €1,000', severity: 'MEDIUM', status: 'AUTO_COLLECTED' },
      ],
    });
  }

  if ((await prisma.dispute.count()) === 0) {
    await prisma.dispute.createMany({
      data: [
        { caseRef: 'dsp_0091', type: 'Disputed payment', amountCents: 31000, parties: 'Fatima Z. vs Tom R.', status: 'AWAITING_EVIDENCE' },
        { caseRef: 'dsp_0090', type: 'ROSCA escrow', amountCents: 99000, parties: 'Circle crc_0299 (5 members)', status: 'ESCROW_LOCKED' },
      ],
    });
  }

  if ((await prisma.supportThread.count()) === 0) {
    const t1 = await prisma.supportThread.create({
      data: {
        userRef: 'User #5012', subjectName: 'Karim Demir', meta: 'KYC2 pending · linked to tx_9a2eff', status: 'OPEN', unread: true,
        messages: {
          create: [
            { direction: 'IN', authorName: 'Karim', body: 'Hi, my payment of €1,240 to Sara is still pending after 20 minutes. Is something wrong?' },
            { direction: 'IN', authorName: 'Karim', body: 'It says "authorized" but hasn\'t completed.' },
            { direction: 'OUT', authorName: 'Ops Admin', body: 'Hi Karim — I can see tx_9a2eff is awaiting bank confirmation via Yapily. This usually clears within the hour for SEPA Instant.' },
          ],
        },
      },
    });
    await prisma.supportThread.create({
      data: {
        userRef: 'User #4102', subjectName: 'Lena Bauer', meta: 'KYC2 · circle crc_0312', status: 'OPEN', unread: true,
        messages: { create: [{ direction: 'IN', authorName: 'Lena', body: 'When does my circle pay out? I am next in line.' }] },
      },
    });
    await prisma.supportThread.update({ where: { id: t1.id }, data: { lastMessageAt: new Date() } });
  }
  console.log('✓ Phase 2 demo data (compliance, disputes, support threads)');
}

async function main() {
  await seedAdmin();
  await seedFlagsAndConfig();
  await seedPhase2();
  console.log('\nLogin at http://localhost:3003/login');
  console.log(`  email:    ${ADMIN_EMAIL}`);
  console.log(`  password: ${ADMIN_PASSWORD}`);
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
