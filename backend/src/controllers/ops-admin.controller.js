const asyncHandler = require('../middlewares/async.middleware');
const opsAdminService = require('../services/ops-admin.service');

exports.listReservations = asyncHandler(async (req, res) => {
  const result = await opsAdminService.listReservations(req.query);
  res.status(200).json({ success: true, ...result });
});

exports.getReservation = asyncHandler(async (req, res) => {
  const data = await opsAdminService.getReservation(req.params.id);
  res.status(200).json({ success: true, data });
});

exports.cancelReservation = asyncHandler(async (req, res) => {
  const data = await opsAdminService.cancelReservation(
    req.params.id,
    req.user,
    req.body,
    req
  );
  res.status(200).json({ success: true, data });
});

exports.checkinReservation = asyncHandler(async (req, res) => {
  const data = await opsAdminService.checkinReservation(
    req.params.id,
    req.user,
    req.body,
    req
  );
  res.status(200).json({ success: true, data });
});

exports.checkoutReservation = asyncHandler(async (req, res) => {
  const data = await opsAdminService.checkoutReservation(
    req.params.id,
    req.user,
    req.body,
    req
  );
  res.status(200).json({ success: true, data });
});

exports.listRefunds = asyncHandler(async (req, res) => {
  const result = await opsAdminService.listRefunds(req.query);
  res.status(200).json({ success: true, ...result });
});

exports.confirmRefund = asyncHandler(async (req, res) => {
  const data = await opsAdminService.confirmRefund(
    req.params.id,
    req.user,
    req.body,
    req
  );
  res.status(200).json({ success: true, data });
});

exports.getInventoryCalendar = asyncHandler(async (req, res) => {
  const data = await opsAdminService.getInventoryCalendar(
    req.user,
    req.params.residenceId,
    req.query.startDate || req.query.start,
    req.query.endDate || req.query.end
  );
  res.status(200).json({ success: true, data });
});

exports.listAnomalies = asyncHandler(async (req, res) => {
  const data = await opsAdminService.listAnomalies();
  res.status(200).json({ success: true, data });
});

exports.listAudit = asyncHandler(async (req, res) => {
  const result = await opsAdminService.listAudit(req.query);
  res.status(200).json({ success: true, ...result });
});
