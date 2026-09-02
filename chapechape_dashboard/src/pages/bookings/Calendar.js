import React, { useState, useEffect } from 'react';
import { Calendar as BigCalendar, dateFnsLocalizer } from 'react-big-calendar';
import format from 'date-fns/format';
import parse from 'date-fns/parse';
import startOfWeek from 'date-fns/startOfWeek';
import getDay from 'date-fns/getDay';
import fr from 'date-fns/locale/fr';
import 'react-big-calendar/lib/css/react-big-calendar.css';
import { motion, AnimatePresence } from 'framer-motion';
import { bookingService } from '../../services/bookingService';
import { opsService } from '../../services/opsService';
import { visibleOpsActions } from '../../ops/reservationActions';
import {
  FILTERABLE_RESERVATION_STATUSES,
  reservationStatusLabel,
} from '../../constants/reservationStatus';
import toast from 'react-hot-toast';
import {
  CalendarIcon, ListBulletIcon, FunnelIcon, PlusIcon,
  MagnifyingGlassIcon, BuildingOfficeIcon, UserIcon,
  CurrencyDollarIcon, ClockIcon, ArrowDownTrayIcon
} from '@heroicons/react/24/outline';

const locales = { 'fr': fr };

const localizer = dateFnsLocalizer({
  format,
  parse,
  startOfWeek,
  getDay,
  locales,
});

// Statuts de réservation avec leurs couleurs
const STATUS_COLORS = {
  pending: '#FFC107',
  awaiting_approval: '#9C27B0',
  payment_pending: '#FF9800',
  confirmed: '#4CAF50',
  in_stay: '#00BCD4',
  cancelled: '#F44336',
  expired: '#B71C1C',
  refunded: '#607D8B',
  completed: '#2196F3'
};

// Composant Modal de réservation avec les détails spécifiques à ChapeChape
const BookingModal = ({ isOpen, onClose, booking, onStatusChange }) => {
  if (!isOpen || !booking) return null;
  const actions = visibleOpsActions(booking.allowedActions);

  const runAction = async (kind) => {
    try {
      const reason = window.prompt(
        kind === 'cancel' ? 'Motif d\'annulation (obligatoire)' : 'Motif Ops (obligatoire)',
        'Action Ops Dashboard'
      );
      if (!reason) return;
      let response;
      if (kind === 'cancel') response = await opsService.cancelReservation(booking._id || booking.id, reason);
      if (kind === 'checkin') response = await opsService.checkinReservation(booking._id || booking.id, reason);
      if (kind === 'checkout') response = await opsService.checkoutReservation(booking._id || booking.id, reason);
      onStatusChange(response);
      toast.success('Action Ops enregistrée');
    } catch (error) {
      toast.error(error.message || 'Erreur lors de la mise à jour');
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center"
    >
      <motion.div
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.9, opacity: 0 }}
        className="bg-white dark:bg-gray-800 rounded-xl p-6 max-w-lg w-full mx-4"
      >
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
            Détails de la réservation
          </h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">×</button>
        </div>

        <div className="space-y-4">
          <div className="flex items-center">
            <BuildingOfficeIcon className="w-5 h-5 text-gray-500 mr-2" />
            <span className="text-gray-900 dark:text-white">{booking.residence?.title}</span>
          </div>
          
          <div className="flex items-center">
            <UserIcon className="w-5 h-5 text-gray-500 mr-2" />
            <span className="text-gray-900 dark:text-white">
              Client: {booking.client?.name}
            </span>
          </div>

          <div className="flex items-center">
            <UserIcon className="w-5 h-5 text-gray-500 mr-2" />
            <span className="text-gray-900 dark:text-white">
              Partenaire: {booking.partner?.name}
            </span>
          </div>

          <div className="flex items-center">
            <ClockIcon className="w-5 h-5 text-gray-500 mr-2" />
            <span className="text-gray-900 dark:text-white">
              Séjour: {booking.checkIn ? format(new Date(booking.checkIn), 'dd/MM/yyyy') : '—'}
              {' → '}
              {booking.checkOut ? format(new Date(booking.checkOut), 'dd/MM/yyyy') : '—'}
            </span>
          </div>

          <div className="flex items-center">
            <div className={`px-2 py-1 rounded-full text-white text-sm ${
              STATUS_COLORS[booking.status] ? `bg-[${STATUS_COLORS[booking.status]}]` : 'bg-gray-500'
            }`}>
              {booking.status}
            </div>
          </div>

          {booking.notes && (
            <div className="mt-4">
              <h3 className="font-medium text-gray-900 dark:text-white mb-2">Notes</h3>
              <p className="text-gray-600 dark:text-gray-300">{booking.notes}</p>
            </div>
          )}
        </div>

        <div className="mt-6 flex justify-end space-x-3">
          {actions.canCancel && (
            <button
              onClick={() => runAction('cancel')}
              className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
            >
              Annuler
            </button>
          )}
          {actions.canCheckin && (
            <button
              onClick={() => runAction('checkin')}
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
            >
              Valider check-in
            </button>
          )}
          {actions.canCheckout && (
            <button
              onClick={() => runAction('checkout')}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Valider check-out
            </button>
          )}
        </div>
      </motion.div>
    </motion.div>
  );
};

const BookingCalendar = () => {
  const [view, setView] = useState('month');
  const [showFilters, setShowFilters] = useState(false);
  const [selectedBooking, setSelectedBooking] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [bookings, setBookings] = useState([]);
  const [filters, setFilters] = useState({
    status: '',
    startDate: '',
    endDate: '',
    residenceType: '',
    searchQuery: ''
  });

  // Charger les réservations
  useEffect(() => {
    loadBookings();
  }, [filters]);

  const loadBookings = async () => {
    try {
      const data = await bookingService.getBookings({ filters });
      const reservations = data?.bookings || [];
      // Transformer les données pour le calendrier
      const formattedBookings = reservations.map(booking => ({
        id: booking._id,
        title: `${booking.residence?.title} - ${booking.client?.name}`,
        start: new Date(booking.checkIn || booking.visitDate),
        end: new Date(booking.checkOut || booking.checkIn || booking.visitDate),
        resource: booking,
        color: STATUS_COLORS[booking.status]
      }));
      setBookings(formattedBookings);
    } catch (error) {
      console.error('Erreur lors du chargement des réservations:', error);
      toast.error('Erreur lors du chargement des réservations');
    }
  };

  const handleEventClick = (event) => {
    setSelectedBooking(event.resource);
    setIsModalOpen(true);
  };

  const handleStatusChange = async (updatedBooking) => {
    await loadBookings();
    setIsModalOpen(false);
  };

  // Export des réservations
  const handleExport = async (format) => {
    try {
      let blob;
      if (format === 'pdf') {
        blob = await bookingService.exportBookingsPDF(filters);
      } else {
        blob = await bookingService.exportBookingsExcel(filters);
      }
      
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = format === 'excel' ? 'reservations.xlsx' : `reservations.${format}`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
    } catch (error) {
      toast.error(`Erreur lors de l'export en ${format.toUpperCase()}`);
    }
  };

  const eventStyleGetter = (event) => ({
    style: {
      backgroundColor: event.color,
      borderRadius: '8px',
      opacity: 0.8,
      color: '#fff',
      border: 'none'
    }
  });

  return (
    <div className="p-6">
      {/* En-tête */}
      <div className="flex justify-between items-start mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Calendrier des réservations
          </h1>
          <p className="mt-1 text-sm text-gray-500">
            Gérez vos réservations et leur planning
          </p>
        </div>
        <div className="flex space-x-2">
          <button
            onClick={() => handleExport('pdf')}
            className="flex items-center px-4 py-2 bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-200 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-600"
          >
            <ArrowDownTrayIcon className="w-5 h-5 mr-2" />
            PDF
          </button>
          <button
            onClick={() => handleExport('excel')}
            className="flex items-center px-4 py-2 bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-200 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-600"
          >
            <ArrowDownTrayIcon className="w-5 h-5 mr-2" />
            Excel
          </button>
        </div>
      </div>

      {/* Barre d'outils */}
      <div className="mb-6">
        <div className="flex flex-col md:flex-row space-y-4 md:space-y-0 md:space-x-4">
          <div className="flex-1 relative">
            <input
              type="text"
              placeholder="Rechercher une réservation..."
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg"
              value={filters.searchQuery}
              onChange={(e) => setFilters({ ...filters, searchQuery: e.target.value })}
            />
            <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
          </div>

          <button
            onClick={() => setShowFilters(!showFilters)}
            className="flex items-center px-4 py-2 bg-white text-gray-700 rounded-lg hover:bg-gray-50"
          >
            <FunnelIcon className="w-5 h-5 mr-2" />
            Filtres
          </button>

          <div className="flex space-x-2">
            <button
              onClick={() => setView('month')}
              className={`p-2 rounded-lg ${
                view === 'month'
                  ? 'bg-primary text-white'
                  : 'bg-white text-gray-700'
              }`}
            >
              <CalendarIcon className="w-5 h-5" />
            </button>
            <button
              onClick={() => setView('agenda')}
              className={`p-2 rounded-lg ${
                view === 'agenda'
                  ? 'bg-primary text-white'
                  : 'bg-white text-gray-700'
              }`}
            >
              <ListBulletIcon className="w-5 h-5" />
            </button>
          </div>
        </div>

        <AnimatePresence>
          {showFilters && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              className="mt-4 p-4 bg-white rounded-lg shadow-sm"
            >
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Statut
                  </label>
                  <select
                    value={filters.status}
                    onChange={(e) => setFilters({ ...filters, status: e.target.value })}
                    className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm"
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
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Date de début
                  </label>
                  <input
                    type="date"
                    value={filters.startDate}
                    onChange={(e) => setFilters({ ...filters, startDate: e.target.value })}
                    className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Date de fin
                  </label>
                  <input
                    type="date"
                    value={filters.endDate}
                    onChange={(e) => setFilters({ ...filters, endDate: e.target.value })}
                    className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm"
                  />
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Calendrier */}
      <div className="bg-white rounded-xl shadow-sm p-6">
        <BigCalendar
          localizer={localizer}
          events={bookings}
          startAccessor="start"
          endAccessor="end"
          style={{ height: 'calc(100vh - 300px)' }}
          views={['month', 'week', 'day', 'agenda']}
          defaultView={view}
          onView={setView}
          eventPropGetter={eventStyleGetter}
          onSelectEvent={handleEventClick}
          messages={{
            today: "Aujourd'hui",
            previous: 'Précédent',
            next: 'Suivant',
            month: 'Mois',
            week: 'Semaine',
            day: 'Jour',
            agenda: 'Agenda',
            date: 'Date',
            time: 'Heure',
            event: 'Événement',
          }}
        />
      </div>

      {/* Modal de réservation */}
      <BookingModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        booking={selectedBooking}
        onStatusChange={handleStatusChange}
      />
    </div>
  );
};

export default BookingCalendar;
