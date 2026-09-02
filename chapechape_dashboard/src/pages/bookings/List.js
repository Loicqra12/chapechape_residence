import React, { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { bookingService } from '../../services/bookingService';
import toast from 'react-hot-toast';
import {
  ChevronUpDownIcon,
  MagnifyingGlassIcon,
  FunnelIcon,
  ArrowDownTrayIcon,
  EyeIcon,
  CheckIcon,
  XMarkIcon,
  ClockIcon,
} from '@heroicons/react/24/outline';
import format from 'date-fns/format';
import {
  FILTERABLE_RESERVATION_STATUSES,
  reservationStatusColor,
  reservationStatusLabel,
} from '../../constants/reservationStatus';
import { visibleOpsActions } from '../../ops/reservationActions';
import { opsService } from '../../services/opsService';

const StatusBadge = ({ status }) => {
  return (
    <span className={`px-3 py-1 rounded-full text-sm font-medium ${reservationStatusColor(status)}`}>
      {reservationStatusLabel(status)}
    </span>
  );
};

const BookingDetails = ({ booking, onClose, onStatusChange }) => {
  if (!booking) return null;
  const actions = visibleOpsActions(booking.allowedActions);
  const fmt = (value) => (value ? format(new Date(value), 'dd/MM/yyyy HH:mm') : '—');

  const runAction = async (kind) => {
    try {
      const reason = window.prompt(
        kind === 'cancel' ? 'Motif d\'annulation (obligatoire)' : 'Motif Ops (obligatoire)',
        kind === 'cancel' ? 'Annulation Ops Dashboard' : 'Action Ops Dashboard'
      );
      if (!reason) return;
      let response;
      if (kind === 'cancel') response = await opsService.cancelReservation(booking._id, reason);
      if (kind === 'checkin') response = await opsService.checkinReservation(booking._id, reason);
      if (kind === 'checkout') response = await opsService.checkoutReservation(booking._id, reason);
      onStatusChange(response);
      toast.success('Action Ops enregistrée');
    } catch (error) {
      toast.error(error.message || 'Erreur lors de l\'action Ops');
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: 20 }}
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
    >
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-xl max-w-3xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white">
              Réservation {booking._id}
            </h3>
            <button
              onClick={onClose}
              className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
            >
              <XMarkIcon className="w-6 h-6" />
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div>
              <h4 className="font-medium text-gray-900 dark:text-white mb-1">Client</h4>
              <p className="text-gray-600 dark:text-gray-300">{booking.client?.name} · {booking.client?.email}</p>
            </div>
            <div>
              <h4 className="font-medium text-gray-900 dark:text-white mb-1">Partenaire</h4>
              <p className="text-gray-600 dark:text-gray-300">{booking.partner?.name || '—'}</p>
            </div>
            <div>
              <h4 className="font-medium text-gray-900 dark:text-white mb-1">Résidence</h4>
              <p className="text-gray-600 dark:text-gray-300">{booking.residence?.title}</p>
            </div>
            <div>
              <h4 className="font-medium text-gray-900 dark:text-white mb-1">Séjour</h4>
              <p className="text-gray-600 dark:text-gray-300">{fmt(booking.checkIn)} → {fmt(booking.checkOut)} ({booking.bookingType})</p>
            </div>
            <div>
              <h4 className="font-medium text-gray-900 dark:text-white mb-1">Reservation status</h4>
              <StatusBadge status={booking.status} />
            </div>
            <div>
              <h4 className="font-medium text-gray-900 dark:text-white mb-1">Payment status</h4>
              <p className="text-gray-600 dark:text-gray-300">{booking.paymentStatus || '—'}</p>
            </div>
            <div>
              <h4 className="font-medium text-gray-900 dark:text-white mb-1">Mode / deadlines</h4>
              <p className="text-gray-600 dark:text-gray-300">
                {booking.reservationMode || '—'}
                <br />host: {fmt(booking.hostApprovalDeadline)}
                <br />payment: {fmt(booking.paymentDeadline)}
              </p>
            </div>
            <div>
              <h4 className="font-medium text-gray-900 dark:text-white mb-1">Payment</h4>
              <p className="text-gray-600 dark:text-gray-300">
                {booking.payment?.provider || '—'} · {booking.payment?.transactionId || '—'}
                {booking.payment?.refundOpsRequired ? ' · refundOpsRequired' : ''}
              </p>
            </div>
            <div>
              <h4 className="font-medium text-gray-900 dark:text-white mb-1">Inventaire</h4>
              <p className="text-gray-600 dark:text-gray-300">{booking.inventoryState || '—'}</p>
            </div>
            <div>
              <h4 className="font-medium text-gray-900 dark:text-white mb-1">Timestamps</h4>
              <p className="text-gray-600 dark:text-gray-300">créé {fmt(booking.createdAt)} · maj {fmt(booking.updatedAt)}</p>
            </div>
          </div>

          {Array.isArray(booking.statusHistory) && booking.statusHistory.length > 0 && (
            <div className="mt-4">
              <h4 className="font-medium text-gray-900 dark:text-white mb-2">statusHistory</h4>
              <ul className="text-xs text-gray-600 dark:text-gray-300 space-y-1">
                {booking.statusHistory.slice(-8).map((entry, idx) => (
                  <li key={idx}>{fmt(entry.changedAt)} · {entry.status} · {entry.reason || ''}</li>
                ))}
              </ul>
            </div>
          )}

          <div className="mt-8 flex justify-end space-x-3">
            {actions.canCancel && (
              <button onClick={() => runAction('cancel')} className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700">
                Annuler
              </button>
            )}
            {actions.canCheckin && (
              <button onClick={() => runAction('checkin')} className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">
                Valider check-in
              </button>
            )}
            {actions.canCheckout && (
              <button onClick={() => runAction('checkout')} className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                Valider check-out
              </button>
            )}
          </div>
        </div>
      </div>
    </motion.div>
  );
};

const BookingList = () => {
  const [bookings, setBookings] = useState([]);
  const [selectedBooking, setSelectedBooking] = useState(null);
  const [selectedBookings, setSelectedBookings] = useState([]);
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 10,
    total: 0,
    pages: 0
  });
  const [showFilters, setShowFilters] = useState(false);
  const [showColumnSelector, setShowColumnSelector] = useState(false);
  const [filters, setFilters] = useState({
    status: '',
    searchQuery: '',
    startDate: '',
    endDate: '',
    residence: '',
    partner: ''
  });
  const [sort, setSort] = useState({ field: 'visitDate', direction: 'desc' });
  const [visibleColumns, setVisibleColumns] = useState({
    visitDate: true,
    residence: true,
    client: true,
    partner: true,
    status: true
  });

  const loadBookings = useCallback(async () => {
    try {
      const data = await bookingService.getBookings({
        page: pagination.page,
        limit: pagination.limit,
        sort,
        filters
      });
      setBookings(data.bookings);
      setPagination(prev => ({
        ...prev,
        total: data.total,
        pages: data.pages
      }));
    } catch (error) {
      console.error('Erreur lors du chargement des réservations:', error);
      toast.error('Erreur lors du chargement des réservations');
    }
  }, [pagination.page, pagination.limit, sort, filters]);

  useEffect(() => {
    loadBookings();
  }, [loadBookings]);

  const handleSort = useCallback((field) => {
    setSort(prev => ({
      field,
      direction: prev.field === field && prev.direction === 'asc' ? 'desc' : 'asc'
    }));
  }, []);

  const handleViewBooking = async (id) => {
    try {
      const booking = await bookingService.getBookingById(id);
      setSelectedBooking(booking);
    } catch (error) {
      toast.error('Erreur lors du chargement de la réservation');
    }
  };

  const handleStatusChange = (updatedBooking) => {
    setBookings(prev => prev.map(b => b._id === updatedBooking._id ? updatedBooking : b));
    setSelectedBooking(null);
  };

  return (
    <div className="p-4">
      <div className="flex flex-col space-y-4">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Réservations</h1>
          <div className="flex space-x-2">
            <button
              onClick={() => setShowFilters(!showFilters)}
              className="px-4 py-2 bg-white dark:bg-gray-800 border border-gray-300 rounded-lg shadow-sm hover:bg-gray-50 dark:hover:bg-gray-700"
            >
              <FunnelIcon className="w-5 h-5 text-gray-500" />
            </button>
          </div>
        </div>

        {showFilters && (
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-4">
            <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-200 mb-1">
                  Statut
                </label>
                <select
                  value={filters.status}
                  onChange={(e) => setFilters(prev => ({ ...prev, status: e.target.value }))}
                  className="block w-full rounded-lg border-gray-300 shadow-sm focus:ring-primary focus:border-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
                >
                  <option value="">Tous</option>
                  {FILTERABLE_RESERVATION_STATUSES.map((status) => (
                    <option key={status} value={status}>
                      {reservationStatusLabel(status)}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-200 mb-1">
                  Recherche
                </label>
                <div className="relative">
                  <input
                    type="text"
                    value={filters.searchQuery}
                    onChange={(e) => setFilters(prev => ({ ...prev, searchQuery: e.target.value }))}
                    placeholder="Rechercher..."
                    className="block w-full rounded-lg border-gray-300 pl-10 shadow-sm focus:ring-primary focus:border-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
                  />
                  <MagnifyingGlassIcon className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                </div>
              </div>
            </div>
          </div>
        )}

        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead className="bg-gray-50 dark:bg-gray-900">
              <tr>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  <div className="flex items-center space-x-1 cursor-pointer" onClick={() => handleSort('visitDate')}>
                    <span>Arrivée</span>
                    <ChevronUpDownIcon className="w-4 h-4" />
                  </div>
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Résidence
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Client
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Partenaire
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Statut
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
              {bookings.map((booking) => (
                <tr key={booking._id} className="hover:bg-gray-50 dark:hover:bg-gray-700">
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                    {booking.checkIn ? format(new Date(booking.checkIn), 'dd/MM/yyyy') : '—'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                    {booking.residence?.title || <span className="text-gray-400 italic">Résidence inconnue</span>}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                    {booking.client?.name || <span className="text-gray-400 italic">Client inconnu</span>}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                    {booking.partner?.name || <span className="text-gray-400 italic">Aucun partenaire</span>}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <StatusBadge status={booking.status} />
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <button
                      onClick={() => handleViewBooking(booking._id)}
                      className="text-primary hover:text-primary-dark"
                    >
                      <EyeIcon className="w-5 h-5" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="flex justify-between items-center mt-4">
          <div className="text-sm text-gray-700 dark:text-gray-300">
            Affichage de {bookings.length} sur {pagination.total} réservations
          </div>
          <div className="flex space-x-2">
            <button
              onClick={() => setPagination(prev => ({ ...prev, page: prev.page - 1 }))}
              disabled={pagination.page === 1}
              className="px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-gray-800 dark:text-white dark:border-gray-600 dark:hover:bg-gray-700"
            >
              Précédent
            </button>
            <button
              onClick={() => setPagination(prev => ({ ...prev, page: prev.page + 1 }))}
              disabled={pagination.page === pagination.pages}
              className="px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-gray-800 dark:text-white dark:border-gray-600 dark:hover:bg-gray-700"
            >
              Suivant
            </button>
          </div>
        </div>
      </div>

      {/* Modal de détails */}
      <AnimatePresence>
        {selectedBooking && (
          <BookingDetails
            booking={selectedBooking}
            onClose={() => setSelectedBooking(null)}
            onStatusChange={handleStatusChange}
          />
        )}
      </AnimatePresence>
    </div>
  );
};

export default BookingList;
