export const OPS_ACTIONS = Object.freeze({
  CANCEL: 'cancel',
  CHECKIN: 'checkin',
  CHECKOUT: 'checkout',
  CONFIRM_MANUAL_REFUND: 'confirm_manual_refund',
});

/**
 * Le Dashboard n'autorise que les actions renvoyées par le Backend.
 * Jamais de PATCH status libre, jamais confirmed → completed.
 */
export function visibleOpsActions(allowedActions = []) {
  const set = new Set(Array.isArray(allowedActions) ? allowedActions : []);
  return {
    canCancel: set.has(OPS_ACTIONS.CANCEL),
    canCheckin: set.has(OPS_ACTIONS.CHECKIN),
    canCheckout: set.has(OPS_ACTIONS.CHECKOUT),
    canConfirmManualRefund: set.has(OPS_ACTIONS.CONFIRM_MANUAL_REFUND),
    canMarkCompletedFromConfirmed: false,
  };
}

export function assertNoFreeStatusPatch(payload = {}) {
  if (Object.prototype.hasOwnProperty.call(payload, 'status')) {
    throw new Error('PATCH status libre interdit depuis le Dashboard');
  }
  return true;
}
