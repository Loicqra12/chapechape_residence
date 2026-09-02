import { visibleOpsActions, assertNoFreeStatusPatch, OPS_ACTIONS } from './reservationActions';

describe('P1-07 Dashboard ops actions', () => {
  it('n’autorise jamais completed depuis confirmed', () => {
    const confirmed = visibleOpsActions(['cancel', 'checkin']);
    expect(confirmed.canCheckin).toBe(true);
    expect(confirmed.canCheckout).toBe(false);
    expect(confirmed.canMarkCompletedFromConfirmed).toBe(false);
  });

  it('n’affiche checkout que si le Backend l’autorise (in_stay)', () => {
    const inStay = visibleOpsActions(['cancel', 'checkout']);
    expect(inStay.canCheckout).toBe(true);
    expect(inStay.canCheckin).toBe(false);
  });

  it('refuse un PATCH status libre', () => {
    expect(() => assertNoFreeStatusPatch({ status: 'completed' })).toThrow(/interdit/);
    expect(assertNoFreeStatusPatch({ reason: 'ok' })).toBe(true);
  });

  it('ne déduit pas d’actions d’un enum local', () => {
    expect(visibleOpsActions([]).canCancel).toBe(false);
    expect(visibleOpsActions(undefined).canCheckin).toBe(false);
    expect(OPS_ACTIONS.CHECKOUT).toBe('checkout');
  });
});
