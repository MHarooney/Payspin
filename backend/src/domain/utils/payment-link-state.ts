import { PaymentLinkStatus, PaymentLinkType } from '@prisma/client';

/** Statuses in which a link can still accept a payment. */
const PAYABLE_STATUSES: PaymentLinkStatus[] = [
  PaymentLinkStatus.ACTIVE,
  PaymentLinkStatus.COLLECTING,
];

export function isPayableStatus(status: PaymentLinkStatus): boolean {
  return PAYABLE_STATUSES.includes(status);
}

export function hasReachedMaxUses(link: {
  maxUses: number | null;
  useCount: number;
}): boolean {
  return link.maxUses != null && link.useCount >= link.maxUses;
}

/**
 * Status a link should hold AFTER a successful payment increments its useCount.
 * SINGLE links settle immediately; MULTI links keep collecting until maxUses.
 */
export function nextStatusAfterPayment(link: {
  linkType: PaymentLinkType;
  maxUses: number | null;
  useCount: number;
}): PaymentLinkStatus {
  if (link.linkType === PaymentLinkType.SINGLE) {
    return PaymentLinkStatus.SETTLED;
  }
  const nextCount = link.useCount + 1;
  if (link.maxUses != null && nextCount >= link.maxUses) {
    return PaymentLinkStatus.SETTLED;
  }
  return PaymentLinkStatus.COLLECTING;
}
