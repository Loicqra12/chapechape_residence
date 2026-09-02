import React, { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { opsService } from '../../services/opsService';

const LABELS = {
  paidPlusExpired: 'Paid + expired',
  confirmedUnpaid: 'Confirmed / in_stay non paid',
  staleAwaitingApproval: 'Awaiting approval trop long',
  overduePaymentPending: 'payment_pending dépassé',
  refundOpsRequired: 'Refunds Ops Required',
  refundFailed: 'Refunds failed',
  historicalOverlaps: 'Overlaps historiques',
  danglingAvailability: 'Availability sans Reservation',
};

const AnomaliesPage = () => {
  const [report, setReport] = useState(null);
  const [loading, setLoading] = useState(false);

  const load = async () => {
    try {
      setLoading(true);
      setReport(await opsService.listAnomalies());
    } catch (error) {
      toast.error(error.message || 'Impossible de charger les anomalies');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  return (
    <div className="p-6 space-y-4">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Anomalies Ops</h1>
          <p className="text-sm text-gray-500">Detect → Inspect. Aucune réparation automatique.</p>
        </div>
        <button onClick={load} className="px-4 py-2 bg-white border rounded-lg">Rafraîchir</button>
      </div>

      {loading && <p>Chargement…</p>}
      {report && (
        <>
          <p className="text-xs text-gray-400">Généré {report.generatedAt}</p>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
            {Object.entries(report.summary || {}).map(([key, count]) => (
              <div key={key} className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow-sm">
                <div className="text-sm text-gray-500">{LABELS[key] || key}</div>
                <div className="text-2xl font-semibold">{count}</div>
              </div>
            ))}
          </div>
          {Object.entries(report.findings || {}).map(([key, rows]) => (
            <div key={key} className="bg-white dark:bg-gray-800 rounded-lg p-4">
              <h2 className="font-medium mb-2">{LABELS[key] || key}</h2>
              {(!rows || rows.length === 0) ? (
                <p className="text-sm text-gray-500">Aucune occurrence (échantillon)</p>
              ) : (
                <pre className="text-xs overflow-x-auto">{JSON.stringify(rows.slice(0, 8), null, 2)}</pre>
              )}
            </div>
          ))}
        </>
      )}
    </div>
  );
};

export default AnomaliesPage;
