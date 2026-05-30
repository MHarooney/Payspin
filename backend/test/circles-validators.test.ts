import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { createCircleSchema, joinCircleSchema } from '@payspin/validators';

describe('circle validators', () => {
  it('accepts valid create input', () => {
    const parsed = createCircleSchema.parse({
      name: 'Weekend trip',
      contributionCents: 2500,
      cycleDurationDays: 30,
      memberCount: 4,
    });
    assert.equal(parsed.name, 'Weekend trip');
    assert.equal(parsed.memberCount, 4);
  });

  it('rejects too few members', () => {
    assert.throws(() =>
      createCircleSchema.parse({
        name: 'X',
        contributionCents: 100,
        cycleDurationDays: 30,
        memberCount: 1,
      }),
    );
  });

  it('accepts join invite code', () => {
    const parsed = joinCircleSchema.parse({ inviteCode: 'abc12345' });
    assert.equal(parsed.inviteCode, 'abc12345');
  });
});
