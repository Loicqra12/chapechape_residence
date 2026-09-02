/**
 * Trust proxy — jamais `true` aveugle (spoof X-Forwarded-For).
 *
 * TRUST_PROXY=0|false     → connexion directe, req.ip = socket
 * TRUST_PROXY_HOPS=1      → Nginx / 1 hop (défaut prod-like)
 * TRUST_PROXY=10.0.0.0/8  → CIDR (liste séparée par virgules)
 * TRUST_PROXY_ALLOW_TRUE=1 + TRUST_PROXY=true → uniquement si le réseau est entièrement privé
 */
function resolveTrustProxySetting(env = process.env) {
  const allowTrue = env.TRUST_PROXY_ALLOW_TRUE === '1';
  const raw = env.TRUST_PROXY != null ? String(env.TRUST_PROXY).trim() : '';

  if (raw === '0' || raw.toLowerCase() === 'false') {
    return false;
  }
  if (raw.toLowerCase() === 'true') {
    if (allowTrue) return true;
    const hops = Number(env.TRUST_PROXY_HOPS || 1);
    return Number.isFinite(hops) && hops >= 0 ? hops : 1;
  }
  if (raw.includes('/') || raw.includes(',')) {
    return raw.split(',').map((s) => s.trim()).filter(Boolean);
  }
  if (/^\d+$/.test(raw)) {
    return Number(raw);
  }

  const hops = env.TRUST_PROXY_HOPS != null ? Number(env.TRUST_PROXY_HOPS) : 1;
  if (!Number.isFinite(hops) || hops < 0) return 1;
  return hops;
}

module.exports = { resolveTrustProxySetting };
