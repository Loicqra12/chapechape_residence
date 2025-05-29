import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { ThemeProvider } from './contexts/ThemeContext';
import { NotificationProvider } from './contexts/NotificationContext';
import { FavoritesProvider } from './contexts/FavoritesContext';
import { AuthProvider } from './contexts/AuthContext';
import { AnimatePresence } from 'framer-motion';
import Login from './pages/auth/Login';
import DashboardPage from './pages/dashboard/DashboardPage';
import Administrators from './pages/admin/Administrators';
import Roles from './pages/admin/Roles';
import Permissions from './pages/admin/Permissions';
import SystemLogs from './pages/admin/SystemLogs';
import Properties from './pages/properties/Properties';
import PropertyTypes from './pages/properties/PropertyTypes';
import Amenities from './pages/properties/Amenities';
import Media from './pages/properties/Media';
import BookingCalendar from './pages/bookings/Calendar';
import BookingList from './pages/bookings/List';
import CheckInPage from './pages/bookings/CheckInPage';
import TransactionsPage from './pages/finance/TransactionsPage';
import PaymentsPage from './pages/finance/PaymentsPage';
import ReportsPage from './pages/finance/ReportsPage';
import MessagesPage from './pages/communication/MessagesPage';
import NotificationsPage from './pages/communication/NotificationsPage';
import SupportPage from './pages/communication/SupportPage';
import PerformancePage from './pages/analytics/PerformancePage';
import RevenuePage from './pages/analytics/RevenuePage';
import AnalyticsReportsPage from './pages/analytics/ReportsPage';
import ReviewsPage from './pages/marketing/ReviewsPage';
import PromotionsPage from './pages/marketing/PromotionsPage';
import CampaignsPage from './pages/marketing/CampaignsPage';
import Layout from './components/layout/Layout';
import { isAuthenticated } from './services/auth';
import PartnersPage from './pages/users/PartnersPage';
import SettingsPage from './pages/settings/SettingsPage';
import SecurityPage from './pages/settings/SecurityPage';
import MaintenancePage from './pages/settings/MaintenancePage';
import ClientsPage from './pages/users/ClientsPage';
import HttpToggle from './components/HttpToggle';

const PrivateRoute = ({ children }) => {
  return isAuthenticated() ? children : <Navigate to="/login" />;
};

function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <NotificationProvider>
          <FavoritesProvider>
            {/* Composant pour basculer entre HTTP et HTTPS en développement */}
            <HttpToggle />
            <Router>
              <AnimatePresence mode="wait">
                <Routes>
                  <Route path="/login" element={<Login />} />
                  <Route
                    path="/*"
                    element={
                      <PrivateRoute>
                        <Layout>
                          <Routes>
                            <Route path="/dashboard" element={<DashboardPage />} />
                            
                            {/* Routes Marketing */}
                            <Route path="/marketing/reviews" element={<ReviewsPage />} />
                            <Route path="/marketing/promotions" element={<PromotionsPage />} />
                            <Route path="/marketing/campaigns" element={<CampaignsPage />} />
                            
                            {/* Routes Immobilier */}
                            <Route path="/properties" element={<Properties />} />
                            <Route path="/property-types" element={<PropertyTypes />} />
                            <Route path="/amenities" element={<Amenities />} />
                            <Route path="/media" element={<Media />} />
                            
                            {/* Routes Réservations */}
                            <Route path="/bookings/calendar" element={<BookingCalendar />} />
                            <Route path="/bookings/list" element={<BookingList />} />
                            <Route path="/bookings/checkin" element={<CheckInPage />} />
                            
                            {/* Routes Finance */}
                            <Route path="/finance/transactions" element={<TransactionsPage />} />
                            <Route path="/finance/payments" element={<PaymentsPage />} />
                            <Route path="/finance/reports" element={<ReportsPage />} />

                            {/* Routes Analytics */}
                            <Route path="/analytics/performance" element={<PerformancePage />} />
                            <Route path="/analytics/revenue" element={<RevenuePage />} />
                            <Route path="/analytics/reports" element={<AnalyticsReportsPage />} />

                            {/* Routes Communication */}
                            <Route path="/communication/messages" element={<MessagesPage />} />
                            <Route path="/communication/notifications" element={<NotificationsPage />} />
                            <Route path="/communication/support" element={<SupportPage />} />
                            
                            {/* Routes Administration */}
                            <Route path="/admin/administrators" element={<Administrators />} />
                            <Route path="/admin/roles" element={<Roles />} />
                            <Route path="/admin/permissions" element={<Permissions />} />
                            <Route path="/admin/logs" element={<SystemLogs />} />
                            
                            {/* Routes Utilisateurs */}
                            <Route path="/users/clients" element={<ClientsPage />} />
                            <Route path="/users/partners" element={<PartnersPage />} />

                            {/* Routes Système */}
                            <Route path="/settings" element={<SettingsPage />} />
                            <Route path="/settings/security" element={<SecurityPage />} />
                            <Route path="/settings/maintenance" element={<MaintenancePage />} />
                            
                            <Route path="*" element={<Navigate to="/dashboard" replace />} />
                          </Routes>
                        </Layout>
                      </PrivateRoute>
                    }
                  />
                </Routes>
              </AnimatePresence>
            </Router>
            <Toaster position="top-right" />
          </FavoritesProvider>
        </NotificationProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;
