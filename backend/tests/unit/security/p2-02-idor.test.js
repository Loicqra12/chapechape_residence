process.env.JWT_SECRET = process.env.JWT_SECRET || 'test_secret_for_ci_at_least_32_chars_ok';

const request = require('supertest');
const express = require('express');
const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const Reservation = require('../../../src/models/reservation.model');
const Payment = require('../../../src/models/payment.model');
const CancellationPolicy = require('../../../src/models/cancellationPolicy.model');
const { Conversation, Message } = require('../../../src/models/message.model');
const { generateAccessToken } = require('../../../src/utils/jwt');
const { errorHandler } = require('../../../src/middlewares/error.middleware');
const { residenceAttrs } = require('../../helpers/residence.fixture');
const messageRoutes = require('../../../src/routes/message.routes');
const paymentRoutes = require('../../../src/routes/payment.routes');
const reservationRoutes = require('../../../src/routes/reservation.routes');
const mediaRoutes = require('../../../src/routes/media.routes');
const residenceRoutes = require('../../../src/routes/residence.routes');
const payoutRoutes = require('../../../src/routes/payout.routes');
const reviewRoutes = require('../../../src/routes/review.routes');
const availabilityRoutes = require('../../../src/routes/availability.routes');
const pricingRoutes = require('../../../src/routes/pricing.routes');
const supportRoutes = require('../../../src/routes/support.routes');
const Review = require('../../../src/models/review.model');
const Partner = require('../../../src/models/partner.model');
const fs = require('fs');
const path = require('path');
const Payout = require('../../../src/models/payout.model');
const Availability = require('../../../src/models/availability.model');
const { denyPublicPrivateUploads } = require('../../../src/security/private-uploads');
const { getInstance: getWavePayoutService } = require('../../../src/services/wave-payout.service');
const {
  canAccessConversation,
  canAccessPayment,
  canAccessReservation,
} = require('../../../src/security/resource-access');

jest.setTimeout(120000);

function authHeader(user) {
  return `Bearer ${generateAccessToken(user._id.toString(), user.role)}`;
}

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/api/messages', messageRoutes);
  app.use('/api/payments', paymentRoutes);
  app.use('/api/reservations', reservationRoutes);
  app.use('/api/media', mediaRoutes);
  app.use('/api/residences', residenceRoutes);
  app.use('/api/payouts', payoutRoutes);
  app.use('/api/reviews', reviewRoutes);
  app.use('/api/availability', availabilityRoutes);
  app.use('/api/pricing', pricingRoutes);
  app.use('/api/support', supportRoutes);
  app.use('/uploads', denyPublicPrivateUploads, (req, res) => res.json({ public: true }));
  app.use(errorHandler);
  return app;
}

async function makeUser(role, extra = {}) {
  const stamp = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  return User.create({
    email: `${role}-${stamp}@test.com`,
    password: 'Test1234',
    firstName: role,
    lastName: 'User',
    role,
    ...extra,
  });
}

async function seedStay() {
  const client = await makeUser('client');
  const otherClient = await makeUser('client');
    const partner = await makeUser('partner', { isPhoneVerified: true, phoneNumber: '+2250700000000' });
    const otherPartner = await makeUser('partner', { isPhoneVerified: true, phoneNumber: '+2250500000000' });
  const policy = await CancellationPolicy.create({
    name: `pol-${Date.now()}`,
    description: 'Test policy',
    isDefault: false,
    createdBy: partner._id,
    rules: [{ timeBeforeCheckIn: 0, refundPercentage: 100, description: 'full' }],
  });
  const residence = await Residence.create(residenceAttrs({
    partner: partner._id,
    cancellationPolicy: policy._id,
  }));
  const otherResidence = await Residence.create(residenceAttrs({
    partner: otherPartner._id,
    title: 'Other partner residence',
    cancellationPolicy: policy._id,
  }));
  const checkIn = new Date(Date.now() + 86400000);
  const checkOut = new Date(Date.now() + 2 * 86400000);
  const reservation = await Reservation.create({
    residence: residence._id,
    user: client._id,
    partner: partner._id,
    checkIn,
    checkOut,
    numberOfGuests: 1,
    totalPrice: 10000,
    reservationModeSnapshot: 'instant',
    ttlSnapshot: { paymentTTLMinutes: 60, hostAcceptTTLMinutes: 480 },
    cancellationPolicy: policy._id,
    status: 'pending',
  });
  const payment = await Payment.create({
    reservation: reservation._id,
    amount: 10000,
    status: 'pending',
    paymentMethod: 'wave',
    paymentProvider: 'cinetpay',
    transactionId: `tx-${Date.now()}-${Math.random().toString(16).slice(2)}`,
    phoneNumber: '0700000000',
  });
  return {
    client, otherClient, partner, otherPartner, residence, otherResidence, reservation, payment,
  };
}

describe('P2-02D IDOR', () => {
  it('helpers : participant / reservation / payment', async () => {
    const a = { _id: 'aaaaaaaaaaaaaaaaaaaaaaaa', role: 'client' };
    const b = { _id: 'bbbbbbbbbbbbbbbbbbbbbbbb', role: 'client' };
    const conv = { participants: [a._id] };
    expect(canAccessConversation(conv, a)).toBe(true);
    expect(canAccessConversation(conv, b)).toBe(false);
    expect(canAccessConversation(conv, { ...b, role: 'admin' })).toBe(true);

    const resa = { user: a._id, partner: 'cccccccccccccccccccccccc' };
    expect(canAccessReservation(resa, a)).toBe(true);
    expect(canAccessReservation(resa, b)).toBe(false);
    expect(canAccessPayment({}, resa, a)).toBe(true);
    expect(canAccessPayment({}, resa, b)).toBe(false);
  });

  it('Client A ne lit pas / ne mute pas la conversation de Client B', async () => {
    const app = createApp();
    const { client, otherClient } = await seedStay();
    const conv = await Conversation.create({
      participants: [client._id],
      title: 'Privée',
    });
    await Message.create({
      conversation: conv._id,
      sender: client._id,
      content: 'secret entre A et le partner',
    });

    const asB = authHeader(otherClient);
    const getMsgs = await request(app)
      .get(`/api/messages/conversations/${conv._id}/messages`)
      .set('Authorization', asB);
    expect(getMsgs.status).toBe(403);

    const read = await request(app)
      .patch(`/api/messages/conversations/${conv._id}/read`)
      .set('Authorization', asB);
    expect(read.status).toBe(403);

    const send = await request(app)
      .post(`/api/messages/conversations/${conv._id}/messages`)
      .set('Authorization', asB)
      .send({ content: 'intrusion' });
    expect(send.status).toBe(403);

    const asA = await request(app)
      .get(`/api/messages/conversations/${conv._id}/messages`)
      .set('Authorization', authHeader(client));
    expect(asA.status).toBe(200);
    expect(asA.body.data.messages.length).toBeGreaterThan(0);
  });

  it('createConversation n’ajoute pas un participant arbitraire', async () => {
    const app = createApp();
    const { client, otherClient } = await seedStay();
    const res = await request(app)
      .post('/api/messages/conversations')
      .set('Authorization', authHeader(client))
      .send({ participants: [otherClient._id.toString()], initialMessage: 'hello' });
    expect(res.status).toBe(201);
    const ids = (res.body.data.participants || []).map((p) => String(p._id || p));
    expect(ids).toContain(String(client._id));
    expect(ids).not.toContain(String(otherClient._id));
  });

  it('Client A ne lit pas la réservation / le paiement de Client B', async () => {
    const app = createApp();
    const { client, otherClient, reservation, payment } = await seedStay();

    const resaB = await request(app)
      .get(`/api/reservations/${reservation._id}`)
      .set('Authorization', authHeader(otherClient));
    expect(resaB.status).toBe(403);

    const resaA = await request(app)
      .get(`/api/reservations/${reservation._id}`)
      .set('Authorization', authHeader(client));
    expect(resaA.status).toBe(200);

    const payB = await request(app)
      .get(`/api/payments/status/${payment.transactionId}`)
      .set('Authorization', authHeader(otherClient));
    expect(payB.status).toBe(403);

    const payA = await request(app)
      .get(`/api/payments/status/${payment.transactionId}`)
      .set('Authorization', authHeader(client));
    expect(payA.status).toBe(200);

    const verifyB = await request(app)
      .get(`/api/payments/cinetpay/verify/${payment.transactionId}`)
      .set('Authorization', authHeader(otherClient));
    expect(verifyB.status).toBe(403);
  });

  it('Partner A ne lit pas la résidence unlisted / réservation de Partner B', async () => {
    const app = createApp();
    const { otherPartner, reservation } = await seedStay();

    const resa = await request(app)
      .get(`/api/reservations/${reservation._id}`)
      .set('Authorization', authHeader(otherPartner));
    expect(resa.status).toBe(403);
  });

  it('Client ne signe pas un dossier documents Cloudinary d’un autre Partner', async () => {
    const app = createApp();
    const { client, partner } = await seedStay();
    const asClient = await request(app)
      .get('/api/media/cloudinary-signature')
      .query({ folder: `chapechape/documents/${partner._id}` })
      .set('Authorization', authHeader(client));
    expect(asClient.status).toBe(403);

    const asPartnerOther = await request(app)
      .get('/api/media/cloudinary-signature')
      .query({ folder: `chapechape/documents/${client._id}` })
      .set('Authorization', authHeader(partner));
    expect(asPartnerOther.status).toBe(403);
  });

  it('WhatsApp test : un client ne peut pas envoyer vers un numéro arbitraire', async () => {
    const app = createApp();
    const { client } = await seedStay();
    const res = await request(app)
      .post('/api/messages/whatsapp/test')
      .set('Authorization', authHeader(client))
      .send({ phoneNumber: '+2250700000000', message: 'spam' });
    expect(res.status).toBe(403);
  });

  it('GET /uploads/documents est refusé sans auth ; résidences restent publiques', async () => {
    const app = createApp();
    const priv = await request(app).get('/uploads/documents/secret.pdf');
    expect(priv.status).toBe(401);
    const pub = await request(app).get('/uploads/residences/photo.jpg');
    expect(pub.status).toBe(200);
    expect(pub.body.public).toBe(true);
  });

  it('Wave transfer refuse le body free-form et l’IDOR payout', async () => {
    const app = createApp();
    const { partner, otherPartner, payment } = await seedStay();
    const createPayoutSpy = jest.spyOn(getWavePayoutService(), 'createPayout');
    const payout = await Payout.create({
      payout_id: `po-${Date.now()}`,
      partner: partner._id,
      source_transactions: [payment._id],
      gross_amount: 10000,
      commission_amount: 1000,
      commission_rate: 0.1,
      net_amount: 9000,
      channel: 'wave',
      recipient_info: {
        phone_prefix: '225',
        phone_number: '07000000',
        full_name: 'Partner Test',
        email: 'payout@test.com',
      },
      status: 'PAYOUT_PENDING',
      scheduled_for: new Date(),
    });

    const missingId = await request(app)
      .post('/api/payouts/wave/transfer')
      .set('Authorization', authHeader(partner))
      .send({ amount: 500000, mobile: '+2250101010101', name: 'Hacker' });
    expect(missingId.status).toBe(400);

    const stolen = await request(app)
      .post('/api/payouts/wave/transfer')
      .set('Authorization', authHeader(otherPartner))
      .send({ payout_id: payout.payout_id, amount: 500000, mobile: '+2250101010101' });
    expect(stolen.status).toBe(403);
    expect(createPayoutSpy).not.toHaveBeenCalled();
    createPayoutSpy.mockRestore();
  });

  it('Client A ne review pas avec la reservationId de B ; Partner ne note pas sa résidence', async () => {
    const app = createApp();
    const { client, otherClient, partner, residence, reservation } = await seedStay();
    await Reservation.findByIdAndUpdate(reservation._id, { status: 'completed' });

    const asB = await request(app)
      .post('/api/reviews')
      .set('Authorization', authHeader(otherClient))
      .send({
        residenceId: residence._id.toString(),
        reservationId: reservation._id.toString(),
        rating: 5,
        comment: 'Volé',
      });
    expect(asB.status).toBe(403);

    const asPartner = await request(app)
      .post('/api/reviews')
      .set('Authorization', authHeader(partner))
      .send({
        residenceId: residence._id.toString(),
        reservationId: reservation._id.toString(),
        rating: 5,
        comment: 'Auto-review',
      });
    expect(asPartner.status).toBe(403);

    const asOwner = await request(app)
      .post('/api/reviews')
      .set('Authorization', authHeader(client))
      .send({
        residenceId: residence._id.toString(),
        reservationId: reservation._id.toString(),
        rating: 5,
        comment: 'Séjour OK',
      });
    expect(asB.status).toBe(403);
    expect(asPartner.status).toBe(403);
    expect(asOwner.status).not.toBe(403);
  });

  it('PUT /residences/:id/ratings refuse un reservationId étranger et un Partner', async () => {
    const app = createApp();
    const { client, otherClient, partner, residence, reservation } = await seedStay();
    await Reservation.findByIdAndUpdate(reservation._id, { status: 'completed' });

    const asPartner = await request(app)
      .put(`/api/residences/${residence._id}/ratings`)
      .set('Authorization', authHeader(partner))
      .send({ overall: 5, reservationId: reservation._id.toString() });
    expect(asPartner.status).toBe(403);

    const asB = await request(app)
      .put(`/api/residences/${residence._id}/ratings`)
      .set('Authorization', authHeader(otherClient))
      .send({ overall: 5, reservationId: reservation._id.toString() });
    expect(asB.status).toBe(403);
  });

  it('Client C n’upload pas de pièce jointe dans une conversation A/B', async () => {
    const app = createApp();
    const { client, otherClient, partner } = await seedStay();
    const conversation = await Conversation.create({
      participants: [client._id, partner._id],
    });
    const res = await request(app)
      .post(`/api/messages/conversations/${conversation._id}/attachments`)
      .set('Authorization', authHeader(otherClient))
      .send({ fileUrl: 'https://res.cloudinary.com/demo/image/upload/x.jpg', fileName: 'x.jpg' });
    expect(res.status).toBe(403);
  });

  it('Partner A ne change pas le pricing de la résidence B', async () => {
    const app = createApp();
    const { partner, otherPartner, residence } = await seedStay();
    const day = new Date('2026-09-01T00:00:00.000Z');
    await Availability.create({
      residenceId: residence._id,
      date: day,
      status: 'available',
      price: 1000,
    });

    const asB = await request(app)
      .put('/api/availability/pricing')
      .set('Authorization', authHeader(otherPartner))
      .send({ residenceId: residence._id.toString(), date: day.toISOString(), price: 1 });
    expect(asB.status).toBe(403);

    const asA = await request(app)
      .put('/api/availability/pricing')
      .set('Authorization', authHeader(partner))
      .send({ residenceId: residence._id.toString(), date: day.toISOString(), price: 2500 });
    expect(asA.status).toBe(200);
    expect(asA.body.data.price).toBe(2500);
  });

  it('GET /pricing/partner/:partnerId/stats est scoped au partner', async () => {
    const app = createApp();
    const { partner, otherPartner } = await seedStay();
    const asA = await request(app)
      .get(`/api/pricing/partner/${partner._id}/stats`)
      .set('Authorization', authHeader(partner));
    expect(asA.status).toBe(200);

    const asB = await request(app)
      .get(`/api/pricing/partner/${partner._id}/stats`)
      .set('Authorization', authHeader(otherPartner));
    expect(asB.status).toBe(403);

    const admin = await makeUser('admin');
    const asAdmin = await request(app)
      .get(`/api/pricing/partner/${partner._id}/stats`)
      .set('Authorization', authHeader(admin));
    expect(asAdmin.status).toBe(200);
  });

  it('Partner A ne modifie pas images / FAQ / vidéo de la résidence B', async () => {
    const app = createApp();
    const { partner, otherPartner, residence } = await seedStay();
    residence.images = ['https://res.cloudinary.com/demo/image/upload/a.jpg'];
    residence.videos = [{
      url: 'https://res.cloudinary.com/demo/video/upload/v.mp4',
      publicId: 'chapechape/videos/v',
      status: 'pending_review',
    }];
    residence.faqs = [{ question: 'Q', answer: 'A' }];
    await residence.save();
    const videoId = residence.videos[0]._id;

    const img = await request(app)
      .delete(`/api/residences/${residence._id}/images/0`)
      .set('Authorization', authHeader(otherPartner));
    expect(img.status).toBe(403);

    const faq = await request(app)
      .put(`/api/residences/${residence._id}/faqs`)
      .set('Authorization', authHeader(otherPartner))
      .send({ faqs: [{ question: 'Hijack FAQ', answer: 'not allowed here' }] });
    expect(faq.status).toBe(403);

    const vid = await request(app)
      .delete(`/api/residences/${residence._id}/videos/${videoId}`)
      .set('Authorization', authHeader(otherPartner));
    expect(vid.status).toBe(403);

    const ownFaq = await request(app)
      .put(`/api/residences/${residence._id}/faqs`)
      .set('Authorization', authHeader(partner))
      .send({ faqs: [{ question: 'Question deux', answer: 'Reponse deux valide' }] });
    expect(ownFaq.status).toBe(200);
  });

  it('deux reviews pour la même réservation : unicité garantie', async () => {
    const app = createApp();
    const { client, residence, reservation } = await seedStay();
    await Reservation.findByIdAndUpdate(reservation._id, { status: 'completed' });
    const payload = {
      residenceId: residence._id.toString(),
      reservationId: reservation._id.toString(),
      rating: 5,
      comment: 'Séjour OK',
    };
    const first = await request(app)
      .post('/api/reviews')
      .set('Authorization', authHeader(client))
      .send(payload);
    expect([200, 201]).toContain(first.status);
    const second = await request(app)
      .post('/api/reviews')
      .set('Authorization', authHeader(client))
      .send({ ...payload, comment: 'Second' });
    expect(second.status).toBe(409);
    expect(await Review.countDocuments({ reservation: reservation._id })).toBe(1);
  });

  it('refund client : ownership avant PSP ; support tickets = 501', async () => {
    const app = createApp();
    const { client, otherClient, payment } = await seedStay();
    const stolen = await request(app)
      .post(`/api/payments/${payment._id}/refund`)
      .set('Authorization', authHeader(otherClient))
      .send({ reason: 'Remboursement test IDOR motif assez long' });
    expect(stolen.status).toBe(403);

    const own = await request(app)
      .post(`/api/payments/${payment._id}/refund`)
      .set('Authorization', authHeader(client))
      .send({ reason: 'Remboursement test IDOR motif assez long' });
    expect([403, 501]).toContain(own.status);

    const stub = await request(app)
      .post('/api/support/tickets/507f1f77bcf86cd799439011/reply')
      .set('Authorization', authHeader(client))
      .send({ message: 'hello' });
    expect(stub.status).toBe(501);
  });

  it('GET /api/media/private/documents : filename du Partner A inaccessible à B', async () => {
    const app = createApp();
    const stamp = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
    const filename = `idor-${stamp}.txt`;
    const dir = path.resolve(__dirname, '../../../uploads/documents');
    fs.mkdirSync(dir, { recursive: true });
    const filePath = path.join(dir, filename);
    fs.writeFileSync(filePath, 'private');

    const owner = await Partner.create({
      email: `p-doc-${stamp}@test.com`,
      password: 'Test1234',
      firstName: 'Doc',
      lastName: 'Owner',
      role: 'partner',
      isPhoneVerified: true,
      phoneNumber: '+2250700111222',
      company: { name: 'Co', registrationNumber: 'RC1' },
      partnerType: 'owner',
      documents: [{ type: 'identity', url: `/uploads/documents/${filename}` }],
    });
    const other = await makeUser('partner', { isPhoneVerified: true, phoneNumber: '+2250500111222' });

    try {
      const asB = await request(app)
        .get(`/api/media/private/documents/${filename}`)
        .set('Authorization', authHeader(other));
      expect(asB.status).toBe(403);

      const asA = await request(app)
        .get(`/api/media/private/documents/${filename}`)
        .set('Authorization', authHeader(owner));
      expect(asA.status).toBe(200);
    } finally {
      if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    }
  });
});
