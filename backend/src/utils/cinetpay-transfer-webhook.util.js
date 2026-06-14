/**
 * URL de notification CinetPay Transfer (notify_url).
 * Le secret n'existe pas dans le back-office CinetPay : on le génère nous-mêmes
 * et on le passe en query ?token= pour que CinetPay appelle l'URL sécurisée.
 */
function getApiBaseUrl() {
    return (
        process.env.APP_URL ||
        process.env.PRODUCTION_API_URL ||
        'https://api.chapechaperesidence.com'
    ).replace(/\/$/, '');
}

function getCinetPayTransferWebhookUrl() {
    const baseUrl = `${getApiBaseUrl()}/api/payouts/cinetpay/webhook`;
    const secret = process.env.CINETPAY_TRANSFER_WEBHOOK_SECRET;

    if (secret) {
        return `${baseUrl}?token=${encodeURIComponent(secret)}`;
    }

    return baseUrl;
}

function verifyCinetPayTransferWebhookToken(req) {
    const expected = process.env.CINETPAY_TRANSFER_WEBHOOK_SECRET;

    if (process.env.NODE_ENV === 'production' && !expected) {
        return { ok: false, status: 503, message: 'CINETPAY_TRANSFER_WEBHOOK_SECRET manquant en production' };
    }

    if (!expected) {
        return { ok: true, devMode: true };
    }

    const incoming =
        req.query?.token ||
        req.get('x-webhook-secret') ||
        req.get('x-cinetpay-secret');

    if (!incoming || incoming !== expected) {
        return { ok: false, status: 403, message: 'Token webhook transfer invalide' };
    }

    return { ok: true };
}

module.exports = {
    getApiBaseUrl,
    getCinetPayTransferWebhookUrl,
    verifyCinetPayTransferWebhookToken,
};
