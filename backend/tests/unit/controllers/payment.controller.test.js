process.env.STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY || 'sk_test_wave4_not_real';
process.env.STRIPE_WEBHOOK_SECRET = process.env.STRIPE_WEBHOOK_SECRET || 'whsec_wave4_not_real';
process.env.WAVE_SIGNING_SECRET = process.env.WAVE_SIGNING_SECRET || 'wave4_hmac_secret';

jest.mock('stripe', () => {
  const instance = {
    paymentIntents: {
      create: jest.fn(),
      retrieve: jest.fn(),
    },
    refunds: { create: jest.fn() },
    webhooks: { constructEvent: jest.fn() },
  };
  const Stripe = jest.fn(() => instance);
  Stripe.__instance = instance;
  return Stripe;
});

const crypto = require('crypto');
const request = require('supertest');
const Stripe = require('stripe');
const app = require('../../../src/app');
const waveService = require('../../../src/services/wave.service');
const cinetPayService = require('../../../src/services/cinetpay.service');
const { verifyWaveWebhookHmac } = require('../../../src/utils/wave-webhook-signature.util');
const Payment = require('../../../src/models/payment.model');
const CancellationPolicy = require('../../../src/models/cancellationPolicy.model');
const {
  createClient,
  createPartner,
  createAdmin,
  authHeader,
  createResidence,
  createReservation,
  createPayment,
} = require('../../helpers/factories');

const stripeApi = Stripe.__instance;
const WAVE_SECRET = process.env.WAVE_SIGNING_SECRET;
const AMOUNT = 15000;

function waveSig(raw) {
  const buf = Buffer.isBuffer(raw) ? raw : Buffer.from(raw);
  return crypto.createHmac('sha256', WAVE_SECRET).update(buf).digest('hex');
}

async function seed() {
  const client = await createClient();
  const other = await createClient();
  const partner = await createPartner({ isPhoneVerified: true, phoneNumber: '0700000001' });
  const admin = await createAdmin();
  const policy = await CancellationPolicy.create({
    name: `pol-${Date.now()}`,
    description: 'Politique test Wave 4',
    isDefault: false,
    createdBy: partner._id,
    rules: [{ timeBeforeCheckIn: 0, refundPercentage: 100, description: 'full' }],
  });
  const residence = await createResidence(partner, { cancellationPolicy: policy._id });
  const reservation = await createReservation(client, residence, {
    partner: partner._id,
    numberOfGuests: 2,
    totalPrice: AMOUNT,
    cancellationPolicy: policy._id,
  });
  return { client, other, partner, admin, residence, reservation };
}

describe('Payment HTTP — contrat actuel (boundary PSP)', () => {
  beforeEach(() => {
    jest.spyOn(waveService, 'initiatePayment').mockResolvedValue({
      success: true,
      transactionId: `wave_${Date.now()}`,
      status: 'pending',
      paymentUrl: 'https://pay.wave.test/s',
      paymentToken: 'tok',
    });
    jest.spyOn(waveService, 'checkPaymentStatus').mockResolvedValue({
      success: true,
      status: 'pending',
    });
    jest.spyOn(cinetPayService, 'initiatePayment').mockResolvedValue({
      success: true,
      transactionId: `cp_${Date.now()}`,
      status: 'pending',
      paymentUrl: 'https://checkout.cinetpay.test/s',
      paymentToken: 'cptok',
    });
    jest.spyOn(cinetPayService, 'checkPaymentStatus').mockResolvedValue({
      success: true,
      status: 'pending',
      data: {},
    });
    jest.spyOn(cinetPayService, 'verifyNotificationHmac').mockReturnValue(false);
    jest.spyOn(waveService, 'verifySignature').mockImplementation((raw, sig) =>
      verifyWaveWebhookHmac(raw, sig, WAVE_SECRET)
    );
    stripeApi.refunds.create.mockReset().mockResolvedValue({
      id: 're_test',
      status: 'succeeded',
      amount: AMOUNT,
    });
    stripeApi.webhooks.constructEvent.mockReset();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('POST /api/payments/create-payment-intent', () => {
    it('ownership : Client B ne paie pas la réservation de A — 0 appel Wave', async () => {
      const { other, reservation } = await seed();
      const res = await request(app)
        .post('/api/payments/create-payment-intent')
        .set('Authorization', authHeader(other))
        .send({
          reservationId: reservation._id.toString(),
          paymentMethod: 'wave',
          phoneNumber: '0700000000',
        });
      expect(res.status).toBe(403);
      expect(waveService.initiatePayment).not.toHaveBeenCalled();
      expect(cinetPayService.initiatePayment).not.toHaveBeenCalled();
    });

    it('body.amount n’est pas un champ du DTO actuel (Joi)', async () => {
      const { client, reservation } = await seed();
      const res = await request(app)
        .post('/api/payments/create-payment-intent')
        .set('Authorization', authHeader(client))
        .send({
          reservationId: reservation._id.toString(),
          paymentMethod: 'wave',
          phoneNumber: '0700000000',
          amount: 1,
        });
      expect(res.status).toBe(400);
      expect(waveService.initiatePayment).not.toHaveBeenCalled();
    });

    it('montant dérivé de Reservation.totalPrice', async () => {
      const { client, reservation } = await seed();
      const res = await request(app)
        .post('/api/payments/create-payment-intent')
        .set('Authorization', authHeader(client))
        .send({
          reservationId: reservation._id.toString(),
          paymentMethod: 'wave',
          phoneNumber: '0700000000',
        });
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(waveService.initiatePayment).toHaveBeenCalledTimes(1);
      const [paymentData] = waveService.initiatePayment.mock.calls[0];
      expect(paymentData.amount).toBe(AMOUNT);
      const stored = await Payment.findById(res.body.data.paymentId);
      expect(stored.amount).toBe(AMOUNT);
    });

    it('CinetPay (orange_money) : transaction id / amount au boundary', async () => {
      const { client, reservation } = await seed();
      const res = await request(app)
        .post('/api/payments/create-payment-intent')
        .set('Authorization', authHeader(client))
        .send({
          reservationId: reservation._id.toString(),
          paymentMethod: 'orange_money',
          phoneNumber: '0700000000',
        });
      expect(res.status).toBe(200);
      expect(cinetPayService.initiatePayment).toHaveBeenCalledTimes(1);
      expect(waveService.initiatePayment).not.toHaveBeenCalled();
      const [paymentData] = cinetPayService.initiatePayment.mock.calls[0];
      expect(paymentData.amount).toBe(AMOUNT);
      expect(String(paymentData.reservation._id)).toBe(String(reservation._id));
    });

    it('idempotence : second intent frais + même montant → pas de 2e appel PSP', async () => {
      const { client, reservation } = await seed();
      await createPayment(reservation, {
        amount: AMOUNT,
        paymentMethod: 'wave',
        paymentProvider: 'wave',
        status: 'pending',
        transactionId: `wave_existing_${Date.now()}`,
        phoneNumber: '0700000000',
      });
      const res = await request(app)
        .post('/api/payments/create-payment-intent')
        .set('Authorization', authHeader(client))
        .send({
          reservationId: reservation._id.toString(),
          paymentMethod: 'wave',
          phoneNumber: '0700000000',
        });
      expect(res.status).toBe(200);
      expect(waveService.initiatePayment).not.toHaveBeenCalled();
    });

    it('réservation inconnue → 404, 0 PSP', async () => {
      const { client } = await seed();
      const res = await request(app)
        .post('/api/payments/create-payment-intent')
        .set('Authorization', authHeader(client))
        .send({
          reservationId: '507f1f77bcf86cd799439011',
          paymentMethod: 'wave',
          phoneNumber: '0700000000',
        });
      expect(res.status).toBe(404);
      expect(waveService.initiatePayment).not.toHaveBeenCalled();
    });
  });

  describe('POST /api/payments/:paymentId/confirm', () => {
    it('Client B ne confirme pas le paiement de A — 0 check Wave', async () => {
      const { reservation, other } = await seed();
      const payment = await createPayment(reservation, {
        amount: AMOUNT,
        paymentMethod: 'wave',
        paymentProvider: 'wave',
        transactionId: `wave_conf_${Date.now()}`,
        phoneNumber: '0700000000',
      });
      const res = await request(app)
        .post(`/api/payments/${payment._id}/confirm`)
        .set('Authorization', authHeader(other))
        .send({ otp: '123456' });
      expect(res.status).toBe(403);
      expect(waveService.checkPaymentStatus).not.toHaveBeenCalled();
    });

    it('owner : check au boundary avec le transactionId stocké', async () => {
      const { client, reservation } = await seed();
      const tx = `wave_ok_${Date.now()}`;
      const payment = await createPayment(reservation, {
        amount: AMOUNT,
        paymentMethod: 'wave',
        paymentProvider: 'wave',
        transactionId: tx,
        phoneNumber: '0700000000',
      });
      const res = await request(app)
        .post(`/api/payments/${payment._id}/confirm`)
        .set('Authorization', authHeader(client))
        .send({ otp: '123456' });
      expect(res.status).toBe(200);
      expect(waveService.checkPaymentStatus).toHaveBeenCalledWith(tx);
    });
  });

  describe('GET /api/payments/cinetpay/verify/:transactionId', () => {
    it('ownership avant verify PSP', async () => {
      const { reservation, other, client } = await seed();
      const tx = `cp_verify_${Date.now()}`;
      await createPayment(reservation, {
        amount: AMOUNT,
        paymentMethod: 'orange_money',
        paymentProvider: 'cinetpay',
        transactionId: tx,
        phoneNumber: '0700000000',
      });
      const stolen = await request(app)
        .get(`/api/payments/cinetpay/verify/${tx}`)
        .set('Authorization', authHeader(other));
      expect(stolen.status).toBe(403);
      expect(cinetPayService.checkPaymentStatus).not.toHaveBeenCalled();

      const own = await request(app)
        .get(`/api/payments/cinetpay/verify/${tx}`)
        .set('Authorization', authHeader(client));
      expect(own.status).toBe(200);
      expect(cinetPayService.checkPaymentStatus).toHaveBeenCalledWith(tx);
    });
  });

  describe('POST /api/payments/:paymentId/refund', () => {
    it('cross-user 403 et client owner 501 — 0 refund Stripe', async () => {
      const { client, other, reservation } = await seed();
      const payment = await createPayment(reservation, {
        amount: AMOUNT,
        status: 'paid',
        paymentMethod: 'card',
        paymentProvider: 'stripe',
        transactionId: `pi_${Date.now()}`,
      });
      const stolen = await request(app)
        .post(`/api/payments/${payment._id}/refund`)
        .set('Authorization', authHeader(other))
        .send({ reason: 'Remboursement test motif assez long' });
      expect(stolen.status).toBe(403);

      const own = await request(app)
        .post(`/api/payments/${payment._id}/refund`)
        .set('Authorization', authHeader(client))
        .send({ reason: 'Remboursement test motif assez long' });
      expect(own.status).toBe(501);
      expect(stripeApi.refunds.create).not.toHaveBeenCalled();
    });

    it('staff + paid : amount / payment_intent dérivés du Payment', async () => {
      const { admin, reservation } = await seed();
      const intentId = `pi_staff_${Date.now()}`;
      const payment = await createPayment(reservation, {
        amount: AMOUNT,
        status: 'paid',
        paymentMethod: 'card',
        paymentProvider: 'stripe',
        transactionId: intentId,
      });
      const res = await request(app)
        .post(`/api/payments/${payment._id}/refund`)
        .set('Authorization', authHeader(admin))
        .send({ reason: 'Remboursement staff motif assez long' });
      expect(res.status).toBe(200);
      expect(stripeApi.refunds.create).toHaveBeenCalledTimes(1);
      const args = stripeApi.refunds.create.mock.calls[0][0];
      expect(args.payment_intent).toBe(intentId);
      expect(args.amount).toBe(AMOUNT);
    });

    it('montant body > Payment.amount rejeté — 0 Stripe', async () => {
      const { admin, reservation } = await seed();
      const payment = await createPayment(reservation, {
        amount: AMOUNT,
        status: 'paid',
        paymentMethod: 'card',
        paymentProvider: 'stripe',
        transactionId: `pi_over_${Date.now()}`,
      });
      const res = await request(app)
        .post(`/api/payments/${payment._id}/refund`)
        .set('Authorization', authHeader(admin))
        .send({
          reason: 'Remboursement staff motif assez long',
          amount: AMOUNT * 10,
        });
      expect(res.status).toBe(400);
      expect(stripeApi.refunds.create).not.toHaveBeenCalled();
    });
  });

  describe('GET /api/payments/my-payments', () => {
    it('ne liste que les paiements des réservations du client', async () => {
      const { client, other, reservation } = await seed();
      await createPayment(reservation, {
        amount: AMOUNT,
        transactionId: `mine_${Date.now()}`,
        phoneNumber: '0700000000',
      });
      const mine = await request(app)
        .get('/api/payments/my-payments')
        .set('Authorization', authHeader(client));
      expect(mine.status).toBe(200);
      expect(mine.body.data.length).toBe(1);

      const theirs = await request(app)
        .get('/api/payments/my-payments')
        .set('Authorization', authHeader(other));
      expect(theirs.status).toBe(200);
      expect(theirs.body.data.length).toBe(0);
    });
  });

  describe('webhooks (pas de JWT)', () => {
    it('Wave : signature invalide → 400, sans Authorization', async () => {
      const raw = JSON.stringify({
        event: 'checkout.session.completed',
        data: { id: 'sess_bad', payment_status: 'succeeded' },
      });
      const res = await request(app)
        .post('/api/payments/wave/webhook')
        .set('Content-Type', 'application/json')
        .set('x-wave-signature', 'deadbeef')
        .send(raw);
      expect(res.status).toBe(400);
    });

    it('Wave : HMAC + double callback → une transition logique (duplicate)', async () => {
      const raw = JSON.stringify({
        event: 'checkout.session.completed',
        data: { id: `sess_dup_${Date.now()}`, payment_status: 'succeeded' },
      });
      const sig = waveSig(raw);
      const once = await request(app)
        .post('/api/payments/wave/webhook')
        .set('Content-Type', 'application/json')
        .set('x-wave-signature', sig)
        .send(raw);
      expect(once.status).toBe(200);
      expect(once.body.received).toBe(true);

      const twice = await request(app)
        .post('/api/payments/wave/webhook')
        .set('Content-Type', 'application/json')
        .set('x-wave-signature', sig)
        .send(raw);
      expect(twice.status).toBe(200);
      expect(twice.body.duplicate).toBe(true);
    });

    it('Stripe : pas de signature → 401 ; JWT absent volontairement', async () => {
      const res = await request(app)
        .post('/api/payments/webhook')
        .set('Content-Type', 'application/json')
        .send('{}');
      expect(res.status).toBe(401);
      expect(stripeApi.webhooks.constructEvent).not.toHaveBeenCalled();
    });

    it('CinetPay : x-token manquant → 401', async () => {
      const res = await request(app)
        .post('/api/payments/cinetpay/webhook')
        .type('form')
        .send({ cpm_trans_id: 'x', cpm_result: '00', cpm_amount: String(AMOUNT) });
      expect(res.status).toBe(401);
      expect(cinetPayService.verifyNotificationHmac).not.toHaveBeenCalled();
    });
  });
});
