/**
 * Fixtures Residence alignées sur le schéma actuel (locationData requis).
 */
function residenceAttrs(overrides = {}) {
  return {
    title: 'Test Residence',
    description: 'Description test résidence assez longue',
    price: 1000,
    address: 'Rue Test 1',
    city: 'Abidjan',
    locationData: {
      address: 'Rue Test 1',
      city: 'Abidjan',
      country: 'CI',
    },
    type: 'apartment',
    bedrooms: 1,
    bathrooms: 1,
    area: 40,
    ...overrides,
  };
}

function reservationSnapshotAttrs(overrides = {}) {
  return {
    reservationModeSnapshot: 'instant',
    ttlSnapshot: {
      paymentTTLMinutes: 60,
      hostAcceptTTLMinutes: 480,
    },
    ...overrides,
  };
}

module.exports = { residenceAttrs, reservationSnapshotAttrs };
