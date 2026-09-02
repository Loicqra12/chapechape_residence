import React, { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { opsService } from '../../services/opsService';
import { visibleOpsActions } from '../../ops/reservationActions';

const BUCKETS = [
  { id: 'ops_required', label: 'Ops Required' },
  { id: 'required', label: 'Required' },
  { id: 'pending', label: 'Pending' },
  { id: 'failed', label: 'Failed' },
  { id: 'refunded', label: 'Refunded' },
];

const RefundsPage = () => {
  const [bucket, setBucket] = useState('ops_required');
  const [rows, setRows] = useState([]);
  const [counts, setCounts] = useState({});
  const [loading, setLoading] = useState(false);
  const [dialog, setDialog] = useState(null);
  const [note, setNote] = useState('');
  const [externalReference, setExternalReference] = useState('');

  const load = async (nextBucket = bucket) => {
    try {
      setLoading(true);
      const result = await opsService.listRefunds({ bucket: nextBucket, limit: 50 });
      setRows(result.data || []);
      setCounts(result.counts || {});
    } catch (error) {
      toast.error(error.message || 'Impossible de charger la file refunds');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load(bucket);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [bucket]);

  const submitConfirm = async () => {
    try {
      await opsService.confirmRefund(dialog._id, { note, externalReference });
      toast.success('Remboursement marqué traité (audit Backend)');
      setDialog(null);
      setNote('');
      setExternalReference('');
      load(bucket);
    } catch (error) {
      toast.error(error.message || 'Confirmation refusée par le Backend');
    }
  };

  return (
    <div className="p-6 space-y-4">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Finance · Refunds</h1>
        <p className="text-sm text-gray-500">Wave / CinetPay : refundOpsRequired ne doit pas pouvoir être manqué.</p>
      </div>

      <div className="flex flex-wrap gap-2">
        {BUCKETS.map((item) => (
          <button
            key={item.id}
            onClick={() => setBucket(item.id)}
            className={`px-3 py-2 rounded-lg text-sm ${
              bucket === item.id
                ? item.id === 'ops_required'
                  ? 'bg-red-600 text-white'
                  : 'bg-primary text-white'
                : 'bg-white dark:bg-gray-800 border'
            }`}
          >
            {item.label} ({counts[item.id] || 0})
          </button>
        ))}
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-lg shadow overflow-x-auto">
        <table className="min-w-full text-sm">
          <thead className="bg-gray-50 dark:bg-gray-900">
            <tr>
              <th className="px-4 py-3 text-left">Payment</th>
              <th className="px-4 py-3 text-left">Reservation / Client</th>
              <th className="px-4 py-3 text-left">Montant</th>
              <th className="px-4 py-3 text-left">Provider</th>
              <th className="px-4 py-3 text-left">transactionId</th>
              <th className="px-4 py-3 text-left">reason</th>
              <th className="px-4 py-3 text-left">retry</th>
              <th className="px-4 py-3 text-left">Action</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td className="px-4 py-6" colSpan={8}>Chargement…</td></tr>
            ) : rows.length === 0 ? (
              <tr><td className="px-4 py-6" colSpan={8}>Aucun remboursement dans cette file</td></tr>
            ) : rows.map((row) => {
              const actions = visibleOpsActions(row.allowedActions);
              return (
                <tr key={row._id} className={row.refundOpsRequired ? 'bg-red-50 dark:bg-red-950/30' : ''}>
                  <td className="px-4 py-3 font-mono text-xs">{row._id}</td>
                  <td className="px-4 py-3">
                    {row.reservation?._id}<br />
                    {row.reservation?.client?.name || '—'}
                  </td>
                  <td className="px-4 py-3">{row.amount} {row.currency}</td>
                  <td className="px-4 py-3">{row.provider}</td>
                  <td className="px-4 py-3 font-mono text-xs">{row.transactionId || '—'}</td>
                  <td className="px-4 py-3">{row.reason || '—'}</td>
                  <td className="px-4 py-3">{row.retryCount} · {row.lastAttemptAt ? new Date(row.lastAttemptAt).toLocaleString() : '—'}</td>
                  <td className="px-4 py-3">
                    {actions.canConfirmManualRefund && (
                      <button
                        className="px-3 py-1 bg-red-600 text-white rounded"
                        onClick={() => setDialog(row)}
                      >
                        Marquer comme traité
                      </button>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {dialog && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white dark:bg-gray-800 rounded-xl p-6 max-w-lg w-full space-y-3">
            <h2 className="text-lg font-semibold">Confirmer un remboursement manuel</h2>
            <p className="text-sm text-gray-500">
              Cette action passe le Payment à refunded côté Backend. Référence Wave/CinetPay obligatoire.
            </p>
            <textarea
              className="w-full border rounded p-2 dark:bg-gray-700"
              rows={4}
              placeholder="Note d'audit (min. 8 caractères)"
              value={note}
              onChange={(e) => setNote(e.target.value)}
            />
            <input
              className="w-full border rounded p-2 dark:bg-gray-700"
              placeholder="Référence externe (ex. WV-REF-…)"
              value={externalReference}
              onChange={(e) => setExternalReference(e.target.value)}
            />
            <div className="flex justify-end gap-2">
              <button className="px-3 py-2" onClick={() => setDialog(null)}>Fermer</button>
              <button className="px-3 py-2 bg-red-600 text-white rounded" onClick={submitConfirm}>
                Confirmer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default RefundsPage;
