import React, { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { opsService } from '../../services/opsService';
import { adminService } from '../../services/adminService';

const SOURCE_LABELS = {
  reservation: 'ChapeChape Reservation',
  manual_block: 'Partner manual block',
  external_reservation: 'External reservation',
};

const SOURCE_COLORS = {
  reservation: 'bg-green-100 text-green-800',
  manual_block: 'bg-amber-100 text-amber-800',
  external_reservation: 'bg-indigo-100 text-indigo-800',
};

const InventoryOpsPage = () => {
  const [residences, setResidences] = useState([]);
  const [residenceId, setResidenceId] = useState('');
  const [calendar, setCalendar] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    (async () => {
      const result = await adminService.getAllProperties({ limit: 100 });
      const list = result.data || [];
      setResidences(Array.isArray(list) ? list : list.residences || []);
    })();
  }, []);

  const load = async () => {
    if (!residenceId) {
      toast.error('Choisissez une résidence');
      return;
    }
    try {
      setLoading(true);
      const start = new Date();
      start.setUTCDate(start.getUTCDate() - 7);
      const end = new Date();
      end.setUTCDate(end.getUTCDate() + 21);
      const data = await opsService.getInventoryCalendar(
        residenceId,
        start.toISOString(),
        end.toISOString()
      );
      setCalendar(data);
    } catch (error) {
      toast.error(error.message || 'Calendrier inventaire indisponible');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-6 space-y-4">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Inventory Ops</h1>
        <p className="text-sm text-gray-500">
          Projection Backend P1-04 — Reservation / AvailabilityBlock / ExternalReservation. Pas de 4e calendrier local.
        </p>
      </div>

      <div className="flex gap-2">
        <select
          className="border rounded-lg px-3 py-2 dark:bg-gray-800 min-w-[280px]"
          value={residenceId}
          onChange={(e) => setResidenceId(e.target.value)}
        >
          <option value="">Résidence…</option>
          {residences.map((residence) => (
            <option key={residence._id} value={residence._id}>
              {residence.title}
            </option>
          ))}
        </select>
        <button onClick={load} className="px-4 py-2 bg-primary text-white rounded-lg">
          Charger la projection
        </button>
      </div>

      {loading && <p>Chargement…</p>}
      {calendar && (
        <div className="space-y-3">
          <p className="text-xs text-gray-500">timezone {calendar.timezone} · {calendar.start} → {calendar.end}</p>
          <div className="space-y-2">
            {(calendar.occupations || []).map((occ) => (
              <div key={`${occ.sourceType}-${occ.id}`} className="bg-white dark:bg-gray-800 rounded-lg p-3 flex justify-between">
                <div>
                  <span className={`text-xs px-2 py-1 rounded ${SOURCE_COLORS[occ.sourceType] || 'bg-gray-100'}`}>
                    {SOURCE_LABELS[occ.sourceType] || occ.sourceType}
                  </span>
                  <div className="text-sm mt-1">{occ.start} → {occ.end}</div>
                </div>
                <div className="text-sm text-gray-500">{occ.status} · {occ.bookingType}</div>
              </div>
            ))}
            {(calendar.occupations || []).length === 0 && (
              <p className="text-sm text-gray-500">Aucune occupation sur la fenêtre.</p>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default InventoryOpsPage;
