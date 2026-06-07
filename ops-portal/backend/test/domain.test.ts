import assert from 'node:assert/strict';
import { test } from 'node:test';
import { eur, trendPct } from '../src/domain/money';
import { periodRanges, volumeBuckets } from '../src/domain/periods';

test('eur formats compact currency', () => {
  assert.equal(eur(1500), '€15');
  assert.equal(eur(4_823_000), '€48k');
  assert.equal(eur(142_000_000), '€1.42M');
});

test('trendPct reports direction and percentage', () => {
  assert.deepEqual(trendPct(110, 100), { trend: '▲ 10.0%', direction: 'up' });
  assert.deepEqual(trendPct(90, 100), { trend: '▼ 10.0%', direction: 'down' });
  assert.deepEqual(trendPct(0, 0), { trend: 'stable', direction: 'flat' });
  assert.deepEqual(trendPct(5, 0), { trend: 'new', direction: 'up' });
});

test('periodRanges produces adjacent current and previous windows', () => {
  const now = new Date('2026-06-08T12:00:00.000Z');
  const { current, previous } = periodRanges('week', now);
  assert.equal(current.end.getTime(), now.getTime());
  assert.equal(previous.end.getTime(), current.start.getTime());
  assert.ok(current.start.getTime() > previous.start.getTime());
});

test('volumeBuckets returns the expected count per period', () => {
  assert.equal(volumeBuckets('today', new Date('2026-06-08T12:00:00Z')).length, 24);
  assert.equal(volumeBuckets('week', new Date('2026-06-08T12:00:00Z')).length, 7);
  assert.equal(volumeBuckets('month', new Date('2026-06-08T12:00:00Z')).length, 30);
});
