import React, { useState, useEffect } from 'react';
import {
  RefreshCw,
  TrendingUp,
  Home,
  Calendar,
  MessageSquare,
  Activity,
  DollarSign,
  Users,
  BarChart3,
  ArrowUpRight,
  ArrowDownRight,
  Filter,
  Download,
  Eye,
  MoreHorizontal,
  Zap,
  Target,
  Star,
  Building,
  Clock,
  Percent
} from 'lucide-react';
import { dashboardApiService } from '../../services/dashboardApiService';
import BookingStats from '../../components/analytics/BookingStats';
import ResidenceStats from '../../components/analytics/ResidenceStats';
import CommunicationStats from '../../components/analytics/CommunicationStats';
import AnalyticsChart from '../../components/analytics/AnalyticsChart';
import toast from 'react-hot-toast';

// ============ COMPOSANTS RÉUTILISABLES ============

// Composant KPI Card réutilisable
const KPICard = ({ 
  icon: Icon, 
  title, 
  value, 
  subtitle, 
  trend, 
  bgColor = 'bg-primary-50', 
  textColor = 'text-primary-700',
  gauge,
  stars 
}) => (
  <div className={`${bgColor} rounded-2xl p-6 border border-primary-200 hover:border-primary-300 transition-all duration-200 shadow-sm hover:shadow-md`}>
    {/* Header */}
    <div className="flex items-center justify-between mb-4">
      <Icon className="w-8 h-8 text-primary-600" />
      <div className="text-right">
        <div className={`text-2xl font-bold ${textColor}`}>{value}</div>
        <div className="text-sm text-gray-600">{title}</div>
      </div>
    </div>
    
    {/* Trend */}
    {trend && (
      <div className="flex items-center space-x-2 text-sm">
        <ArrowUpRight className={`w-4 h-4 ${trend.positive ? 'text-green-500' : 'text-red-500'}`} />
        <span className={`font-medium ${trend.positive ? 'text-green-600' : 'text-red-600'}`}>
          {trend.value}
        </span>
        <span className="text-gray-600">{trend.label}</span>
      </div>
    )}
    
    {/* Subtitle */}
    <div className="text-gray-600 text-sm mt-2">{subtitle}</div>
    
    {/* Gauge pour occupation */}
    {gauge && (
      <div className="mt-4 flex justify-center">
        <div className="relative w-20 h-10 overflow-hidden">
          <div className="w-20 h-20 border-8 border-primary-200 rounded-full"></div>
          <div 
            className="absolute top-0 left-0 w-20 h-20 border-8 rounded-full transition-all duration-1000"
            style={{
              borderColor: `#3F51B5 transparent transparent transparent`,
              transform: `rotate(${(gauge / 100) * 180}deg)`
            }}
          ></div>
          <div className="absolute inset-0 flex items-end justify-center pb-1">
            <span className={`text-xs font-bold ${textColor}`}>{gauge}%</span>
          </div>
        </div>
      </div>
    )}
    
    {/* Stars pour satisfaction */}
    {stars && (
      <div className="mt-3 flex justify-center space-x-1">
        {[1, 2, 3, 4, 5].map((star) => (
          <Star
            key={star}
            className={`w-4 h-4 ${
              star <= Math.floor(stars)
                ? 'text-primary-500 fill-current'
                : star === Math.ceil(stars) && stars % 1 !== 0
                ? 'text-primary-400 fill-current opacity-50'
                : 'text-gray-300'
            }`}
          />
        ))}
        <span className={`ml-2 text-sm ${textColor}`}>{stars}</span>
      </div>
    )}
  </div>
);

// Composant Chart Container réutilisable
const ChartContainer = ({ 
  title, 
  subtitle, 
  rightValue, 
  rightLabel, 
  legends, 
  children, 
  height = 'h-80' 
}) => (
  <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm">
    <div className="flex items-center justify-between mb-6">
      <div>
        <h3 className="text-xl font-bold text-gray-900 mb-1">{title}</h3>
        {subtitle && <p className="text-sm text-gray-600">{subtitle}</p>}
        {legends && (
          <div className="flex items-center space-x-6 text-sm mt-2">
            {legends.map((legend, index) => (
              <div key={index} className="flex items-center space-x-2">
                <div className={`w-3 h-3 ${legend.color} rounded-full`}></div>
                <span className="text-gray-600">{legend.label}</span>
              </div>
            ))}
          </div>
        )}
      </div>
      {rightValue && (
        <div className="text-right">
          <div className="text-2xl font-bold text-primary-600">{rightValue}</div>
          <div className="text-sm text-gray-600">{rightLabel}</div>
        </div>
      )}
    </div>
    <div className={height}>{children}</div>
  </div>
);

// Composant SVG Chart réutilisable
const SVGChart = ({ type = 'line', data, colors = ['#3F51B5', '#9FA8DA', '#303F9F'] }) => (
  <div className="h-full relative">
    <svg className="w-full h-full" viewBox="0 0 800 300">
      {/* Grid lines */}
      {[0, 1, 2, 3, 4, 5].map((i) => (
        <line
          key={i}
          x1="60"
          y1={50 + i * 40}
          x2="780"
          y2={50 + i * 40}
          stroke="#E5E7EB"
          strokeWidth="1"
        />
      ))}
      
      {type === 'line' && (
        <>
          {/* Line paths */}
          <path
            d="M 80 180 L 150 160 L 220 140 L 290 170 L 360 120 L 430 150 L 500 100 L 570 130 L 640 160 L 710 140"
            fill="none"
            stroke={colors[0]}
            strokeWidth="3"
          />
          <path
            d="M 80 200 L 150 190 L 220 180 L 290 200 L 360 160 L 430 180 L 500 140 L 570 170 L 640 190 L 710 180"
            fill="none"
            stroke={colors[1]}
            strokeWidth="3"
          />
          <path
            d="M 80 160 L 150 150 L 220 120 L 290 140 L 360 100 L 430 130 L 500 90 L 570 110 L 640 140 L 710 120"
            fill="none"
            stroke={colors[2]}
            strokeWidth="3"
          />
          {/* Data points */}
          {[80, 150, 220, 290, 360, 430, 500, 570, 640, 710].map((x, i) => (
            <circle key={i} cx={x} cy={100 + Math.random() * 100} r="4" fill={colors[0]} />
          ))}
        </>
      )}
      
      {type === 'bar' && (
        <>
          {/* Bar chart */}
          {[
            { x: 100, height: 120, color: colors[0] },
            { x: 160, height: 140, color: colors[0] },
            { x: 220, height: 100, color: colors[0] },
            { x: 280, height: 160, color: colors[0] },
            { x: 340, height: 130, color: colors[1] },
            { x: 400, height: 150, color: colors[1] },
            { x: 460, height: 110, color: colors[1] },
            { x: 520, height: 140, color: colors[1] },
            { x: 580, height: 80, color: colors[2] },
            { x: 640, height: 90, color: colors[2] },
            { x: 700, height: 70, color: colors[2] }
          ].map((bar, i) => (
            <rect
              key={i}
              x={bar.x}
              y={250 - bar.height}
              width="40"
              height={bar.height}
              fill={bar.color}
              rx="4"
            />
          ))}
        </>
      )}
      
      {type === 'area' && (
        <>
          <defs>
            <linearGradient id="areaGradient1" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stopColor={colors[0]} stopOpacity="0.3" />
              <stop offset="100%" stopColor={colors[0]} stopOpacity="0.05" />
            </linearGradient>
            <linearGradient id="areaGradient2" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stopColor={colors[1]} stopOpacity="0.3" />
              <stop offset="100%" stopColor={colors[1]} stopOpacity="0.05" />
            </linearGradient>
          </defs>
          
          {/* Area paths */}
          <path
            d="M 80 140 L 150 120 L 220 100 L 290 130 L 360 90 L 430 110 L 500 80 L 570 100 L 640 120 L 710 110 L 710 250 L 80 250 Z"
            fill="url(#areaGradient1)"
          />
          <path
            d="M 80 140 L 150 120 L 220 100 L 290 130 L 360 90 L 430 110 L 500 80 L 570 100 L 640 120 L 710 110"
            fill="none"
            stroke={colors[0]}
            strokeWidth="3"
          />
          
          <path
            d="M 80 180 L 150 170 L 220 160 L 290 180 L 360 150 L 430 170 L 500 140 L 570 160 L 640 180 L 710 170 L 710 250 L 80 250 Z"
            fill="url(#areaGradient2)"
          />
          <path
            d="M 80 180 L 150 170 L 220 160 L 290 180 L 360 150 L 430 170 L 500 140 L 570 160 L 640 180 L 710 170"
            fill="none"
            stroke={colors[1]}
            strokeWidth="3"
          />
        </>
      )}
    </svg>
    
    {/* X-axis labels */}
    <div className="absolute bottom-0 left-0 right-0 flex justify-between px-12 text-xs text-gray-600">
      {['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'].map(month => (
        <span key={month}>{month}</span>
      ))}
    </div>
  </div>
);

// Composant Metrics List réutilisable
const MetricsList = ({ title, items, showPercentage = false }) => (
  <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm">
    <h4 className="text-lg font-bold text-gray-900 mb-4">{title}</h4>
    <div className="space-y-3">
      {items.map((item, index) => (
        <div key={index} className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <div className={`w-3 h-3 ${item.color} rounded-full`}></div>
            <span className="text-gray-600 text-sm">{item.label}</span>
          </div>
          <div className="flex items-center space-x-2">
            {showPercentage && (
              <div className="w-20 h-2 bg-primary-100 rounded-full overflow-hidden">
                <div
                  className="h-full bg-primary-500 rounded-full transition-all duration-1000"
                  style={{ width: `${item.percentage || 0}%` }}
                ></div>
              </div>
            )}
            <span className="text-gray-900 font-medium text-sm">
              {item.value}{showPercentage && '%'}
            </span>
          </div>
        </div>
      ))}
    </div>
  </div>
);

// Composant Performance Metrics réutilisable
const PerformanceMetrics = ({ title, metrics }) => (
  <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm">
    <h4 className="text-lg font-bold text-gray-900 mb-4">{title}</h4>
    <div className="space-y-4">
      {metrics.map((metric, index) => (
        <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
          <span className="text-gray-700 font-medium">{metric.label}</span>
          <div className="text-right">
            <div className="text-primary-700 font-bold">{metric.value}</div>
            <div className={`text-xs ${metric.positive ? 'text-green-600' : 'text-red-600'}`}>
              {metric.change}
            </div>
          </div>
        </div>
      ))}
    </div>
  </div>
);

// Composant Donut Chart réutilisable
const DonutChart = ({ data, centerValue, centerLabel }) => (
  <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm">
    <h4 className="text-lg font-bold text-gray-900 mb-4">Répartition des Données</h4>
    <div className="flex justify-center mb-4">
      <div className="relative w-32 h-32">
        <svg className="w-32 h-32 transform -rotate-90" viewBox="0 0 120 120">
          <circle cx="60" cy="60" r="40" fill="none" stroke="#E8EAF6" strokeWidth="8" />
          {data.map((item, index) => (
            <circle
              key={index}
              cx="60"
              cy="60"
              r="40"
              fill="none"
              stroke={item.color}
              strokeWidth="8"
              strokeDasharray={`${40 * 2 * Math.PI * (item.percentage / 100)} ${40 * 2 * Math.PI * (1 - item.percentage / 100)}`}
              strokeDashoffset={`-${40 * 2 * Math.PI * (data.slice(0, index).reduce((acc, curr) => acc + curr.percentage, 0) / 100)}`}
              strokeLinecap="round"
            />
          ))}
        </svg>
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="text-center">
            <div className="text-xl font-bold text-primary-600">{centerValue}</div>
            {centerLabel && <div className="text-xs text-gray-600">{centerLabel}</div>}
          </div>
        </div>
      </div>
    </div>
    
    <div className="space-y-2 text-sm">
      {data.map((item, index) => (
        <div key={index} className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <div className={`w-3 h-3 rounded-full`} style={{ backgroundColor: item.color }}></div>
            <span className="text-gray-600">{item.label}</span>
          </div>
          <span className="text-gray-900 font-medium">{item.value}</span>
        </div>
      ))}
    </div>
  </div>
);

// ============ COMPOSANT PRINCIPAL ============

const DashboardPage = () => {
  const [dashboardData, setDashboardData] = useState({
    bookingStats: {},
    revenueData: {},
    residenceStats: {},
    communicationStats: {}
  });
  const [loading, setLoading] = useState(true);
  const [selectedTimeRange, setSelectedTimeRange] = useState('30d');
  const [activeTab, setActiveTab] = useState('overview');

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    setLoading(true);
    try {
      // Utiliser le service API réel pour récupérer les données
      const dashboardResponse = await dashboardApiService.getDashboardOverview();
      
      if (dashboardResponse.success) {
        setDashboardData(dashboardResponse.data);
        toast.success('Données du dashboard mises à jour');
      } else {
        throw new Error(dashboardResponse.error || 'Erreur lors du chargement des données');
      }
    } catch (error) {
      console.error('Erreur:', error);
      toast.error(error.message || 'Erreur lors du chargement des données du dashboard');
      
      // En cas d'erreur, utiliser des données de fallback
      setDashboardData({
        bookingStats: {
          totalBookings: 0,
          confirmedBookings: 0,
          pendingBookings: 0,
          completedBookings: 0,
          cancelledBookings: 0,
          conversionRate: 0,
          averageDuration: '0j',
          monthlyBookings: Array(12).fill(0)
        },
        revenueData: {
          totalRevenue: 0,
          monthlyData: Array(12).fill(0)
        },
        residenceStats: {
          totalResidences: 0,
          available: 0,
          occupied: 0,
          occupancyRate: 0,
          averageRating: 0,
          averagePrice: 0
        },
        communicationStats: {
          totalMessages: 0,
          averageResponseTime: '0h',
          satisfactionRate: 0,
          activeSupport: 0,
          messages: { unread: 0, total: 0 }
        }
      });
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = () => {
    loadDashboardData();
  };

  const formatCurrency = (value) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'XOF',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
  };

  // ============ DATA CONFIGURATION ============

  const getKPIConfig = (tab) => {
    const { bookingStats, revenueData, residenceStats, communicationStats } = dashboardData;

    const configs = {
      overview: [
        {
          icon: Calendar,
          title: 'Total Réservations',
          value: (bookingStats?.confirmedBookings + bookingStats?.completedBookings + bookingStats?.pendingBookings) || '5',
          subtitle: 'Réservations confirmées',
          bgColor: 'bg-primary-50',
          textColor: 'text-primary-700',
          trend: { positive: true, value: '+12%', label: 'vs mois dernier' }
        },
        {
          icon: DollarSign,
          title: 'Revenus Totaux',
          value: formatCurrency(revenueData?.totalRevenue || 780000),
          subtitle: 'Revenus cette période',
          bgColor: 'bg-primary-100',
          textColor: 'text-primary-800',
          trend: { positive: true, value: '+8%', label: 'vs mois dernier' }
        },
        {
          icon: Percent,
          title: 'Taux d\'Occupation',
          value: '74%',
          subtitle: 'Capacité utilisée',
          gauge: 74,
          bgColor: 'bg-primary-200',
          textColor: 'text-primary-900',
          trend: { positive: true, value: '+3%', label: 'vs mois dernier' }
        },
        {
          icon: Star,
          title: 'Note Satisfaction',
          value: '4.2',
          subtitle: 'Sur 5 étoiles',
          stars: 4.2,
          bgColor: 'bg-primary-300',
          textColor: 'text-primary-900',
          trend: { positive: true, value: '+0.2', label: 'vs mois dernier' }
        }
      ],
      bookings: [
        {
          icon: Calendar,
          title: 'Total Réservations',
          value: dashboardData.bookingStats?.totalBookings || '247',
          subtitle: 'Total Réservations',
          bgColor: 'bg-primary-50',
          textColor: 'text-primary-700',
          trend: { positive: true, value: '+12%', label: 'vs mois dernier' }
        },
        {
          icon: Target,
          title: 'Taux de Conversion',
          value: `${dashboardData.bookingStats?.conversionRate || 73}%`,
          subtitle: 'Taux de Conversion',
          bgColor: 'bg-primary-100',
          textColor: 'text-primary-700',
          trend: { positive: true, value: '+8%', label: 'vs mois dernier' }
        },
        {
          icon: Clock,
          title: 'Durée Moyenne',
          value: dashboardData.bookingStats?.averageDuration || '4.2j',
          subtitle: 'Durée Moyenne',
          bgColor: 'bg-primary-200',
          textColor: 'text-primary-800',
          trend: { positive: false, value: '-3%', label: 'vs mois dernier' }
        },
        {
          icon: DollarSign,
          title: 'Revenus Réservations',
          value: formatCurrency(dashboardData.revenueData?.totalRevenue || 1247000),
          subtitle: 'Revenus Réservations',
          bgColor: 'bg-primary-300',
          textColor: 'text-primary-900',
          trend: { positive: true, value: '+18%', label: 'vs mois dernier' }
        }
      ],
      residences: [
        {
          icon: Building,
          title: 'Total Résidences',
          value: dashboardData.residenceStats?.totalResidences || '142',
          subtitle: 'Total Résidences',
          bgColor: 'bg-primary-50',
          textColor: 'text-primary-700',
          trend: { positive: true, value: '+5%', label: 'nouvelles ce mois' }
        },
        {
          icon: Percent,
          title: 'Taux d\'Occupation',
          value: `${dashboardData.residenceStats?.occupancyRate || 87}%`,
          subtitle: 'Taux d\'Occupation',
          bgColor: 'bg-primary-100',
          textColor: 'text-primary-700',
          trend: { positive: true, value: '+3%', label: 'vs mois dernier' }
        },
        {
          icon: Star,
          title: 'Note Moyenne',
          value: dashboardData.residenceStats?.averageRating || '4.6',
          subtitle: 'Note Moyenne',
          bgColor: 'bg-primary-200',
          textColor: 'text-primary-800',
          trend: { positive: true, value: '+0.2', label: 'vs mois dernier' }
        },
        {
          icon: DollarSign,
          title: 'Prix Moyen/Nuit',
          value: formatCurrency(dashboardData.residenceStats?.averagePrice || 87500),
          subtitle: 'Prix Moyen/Nuit',
          bgColor: 'bg-primary-300',
          textColor: 'text-primary-900',
          trend: { positive: true, value: '+7%', label: 'vs mois dernier' }
        }
      ],
      communication: [
        {
          icon: MessageSquare,
          title: 'Messages Total',
          value: dashboardData.communicationStats?.totalMessages || '1847',
          subtitle: 'Messages Total',
          bgColor: 'bg-primary-50',
          textColor: 'text-primary-700',
          trend: { positive: true, value: '+23%', label: 'vs mois dernier' }
        },
        {
          icon: Clock,
          title: 'Temps Réponse Moyen',
          value: dashboardData.communicationStats?.averageResponseTime || '2.4h',
          subtitle: 'Temps Réponse Moyen',
          bgColor: 'bg-primary-100',
          textColor: 'text-primary-700',
          trend: { positive: true, value: '-15min', label: 'vs mois dernier' }
        },
        {
          icon: Star,
          title: 'Taux Satisfaction',
          value: `${dashboardData.communicationStats?.satisfactionRate || 92}%`,
          subtitle: 'Taux Satisfaction',
          bgColor: 'bg-primary-200',
          textColor: 'text-primary-800',
          trend: { positive: true, value: '+4%', label: 'vs mois dernier' }
        },
        {
          icon: Users,
          title: 'Agents Actifs',
          value: dashboardData.communicationStats?.activeSupport || '12',
          subtitle: 'Agents Actifs',
          bgColor: 'bg-primary-300',
          textColor: 'text-primary-900',
          trend: { positive: true, value: '+2', label: 'nouveaux ce mois' }
        }
      ]
    };

    return configs[tab] || configs.overview;
  };

  const getMetricsData = (type) => {
    const data = {
      bookingDistribution: [
        { label: 'Confirmées', value: '156', color: 'bg-primary-500' },
        { label: 'En attente', value: '43', color: 'bg-primary-300' },
        { label: 'Terminées', value: '189', color: 'bg-primary-700' },
        { label: 'Annulées', value: '27', color: 'bg-primary-800' }
      ],
      residenceTypes: [
        { label: 'Appartements', value: '68', color: 'bg-primary-500' },
        { label: 'Villas', value: '34', color: 'bg-primary-300' },
        { label: 'Studios', value: '28', color: 'bg-primary-700' },
        { label: 'Duplex', value: '12', color: 'bg-primary-800' }
      ],
      communicationChannels: [
        { label: 'Chat en direct', value: '847', color: 'bg-primary-500' },
        { label: 'Email', value: '634', color: 'bg-primary-300' },
        { label: 'Téléphone', value: '234', color: 'bg-primary-700' },
        { label: 'WhatsApp', value: '132', color: 'bg-primary-800' }
      ],
      amenities: [
        { label: 'WiFi', value: '98', percentage: 98, color: 'bg-primary-500' },
        { label: 'Climatisation', value: '89', percentage: 89, color: 'bg-primary-400' },
        { label: 'Cuisine équipée', value: '76', percentage: 76, color: 'bg-primary-300' },
        { label: 'Parking', value: '72', percentage: 72, color: 'bg-primary-200' },
        { label: 'Piscine', value: '43', percentage: 43, color: 'bg-primary-100' },
        { label: 'Sécurité 24h/24', value: '67', percentage: 67, color: 'bg-primary-50' }
      ]
    };
    return data[type] || [];
  };

  const getPerformanceData = (type) => {
    const data = {
      booking: [
        { label: 'Revenus moyens/résidence', value: formatCurrency(125000), change: '+15%', positive: true },
        { label: 'Durée moyenne de séjour', value: '3.2 jours', change: '+0.3j', positive: true },
        { label: 'Taux de réservation répétée', value: '34%', change: '+7%', positive: true },
        { label: 'Temps de réponse moyen', value: '1.2h', change: '-18min', positive: true }
      ],
      communication: [
        { label: 'Temps de première réponse', value: '1.4h', change: '-23min', positive: true },
        { label: 'Taux de résolution premier contact', value: '87%', change: '+5%', positive: true },
        { label: 'Messages par agent/jour', value: '42', change: '+8', positive: true },
        { label: 'Score satisfaction client (CSAT)', value: '4.7/5', change: '+0.3', positive: true }
      ]
    };
    return data[type] || [];
  };

  const getDonutData = () => [
    { label: 'Confirmées', value: '3.74K', percentage: 30, color: '#3F51B5' },
    { label: 'En attente', value: '2.68K', percentage: 25, color: '#7986CB' },
    { label: 'Terminées', value: '3.02K', percentage: 25, color: '#303F9F' },
    { label: 'Annulées', value: '2.72K', percentage: 20, color: '#C5CAE9' }
  ];

  const getChartLegends = (type) => {
    const legends = {
      booking: [
        { label: 'Confirmées', color: 'bg-primary-500' },
        { label: 'En attente', color: 'bg-primary-300' },
        { label: 'Annulées', color: 'bg-primary-700' }
      ],
      residence: [
        { label: 'Appartements', color: 'bg-primary-500' },
        { label: 'Villas', color: 'bg-primary-300' },
        { label: 'Studios', color: 'bg-primary-700' }
      ],
      communication: [
        { label: 'Chat en direct', color: 'bg-primary-500' },
        { label: 'Email', color: 'bg-primary-300' },
        { label: 'Téléphone', color: 'bg-primary-700' }
      ],
      overview: [
        { label: 'Réservations', color: 'bg-primary-500' },
        { label: 'Revenus', color: 'bg-primary-300' },
        { label: 'Occupation', color: 'bg-primary-700' }
      ]
    };
    return legends[type] || [];
  };

  // Mock data pour les graphiques
  const getWeeklyData = () => [
    { day: 'Lundi', morning: 2.1, evening: 1.8, total: 3.9 },
    { day: 'Mardi', morning: 1.9, evening: 2.1, total: 4.0 },
    { day: 'Mercredi', morning: 2.2, evening: 1.9, total: 4.1 },
    { day: 'Jeudi', morning: 2.0, evening: 2.3, total: 4.3 },
    { day: 'Vendredi', morning: 2.4, evening: 2.6, total: 5.0 },
    { day: 'Samedi', morning: 1.8, evening: 2.4, total: 4.2 },
    { day: 'Dimanche', morning: 1.6, evening: 2.0, total: 3.6 }
  ];

  const getMonthlyData = () => [
    { month: 'Janvier', revenus: 2.1, reservations: 2, taux: 65 },
    { month: 'Février', revenus: 1.8, reservations: 1, taux: 45 },
    { month: 'Mars', revenus: 2.8, reservations: 3, taux: 85 },
    { month: 'Avril', revenus: 2.2, reservations: 2, taux: 70 },
    { month: 'Mai', revenus: 3.1, reservations: 4, taux: 90 },
    { month: 'Juin', revenus: 2.6, reservations: 3, taux: 78 },
    { month: 'Juillet', revenus: 3.8, reservations: 5, taux: 95 },
    { month: 'Août', revenus: 3.2, reservations: 4, taux: 88 }
  ];

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="flex flex-col items-center space-y-4">
          <div className="relative">
            <div className="w-16 h-16 border-4 border-primary-200 rounded-full animate-spin"></div>
            <div className="absolute top-0 left-0 w-16 h-16 border-4 border-primary-600 border-t-transparent rounded-full animate-spin"></div>
          </div>
          <p className="text-gray-600 font-medium text-lg">Chargement du tableau de bord...</p>
        </div>
      </div>
    );
  }

  const weeklyData = getWeeklyData();
  const monthlyData = getMonthlyData();

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="container mx-auto px-6 py-8 max-w-[1600px]">
        {/* Header - Power BI Style */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center space-x-4">
            <div className="w-16 h-16 bg-primary-500 rounded-2xl flex items-center justify-center shadow-lg">
              <div className="text-2xl font-bold text-white">CR</div>
            </div>
            <div>
              <h1 className="text-3xl font-bold text-gray-900">CHAPECHAPE</h1>
              <h2 className="text-lg text-primary-600 font-medium">RESIDENCE</h2>
            </div>
          </div>
          <div className="flex items-center space-x-3">
            <select 
              value={selectedTimeRange}
              onChange={(e) => setSelectedTimeRange(e.target.value)}
              className="px-4 py-2 bg-white border border-primary-200 rounded-lg text-sm font-medium text-gray-700 hover:border-primary-300 focus:outline-none focus:ring-2 focus:ring-primary-500 transition-all duration-200"
            >
              <option value="7d">7 derniers jours</option>
              <option value="30d">30 derniers jours</option>
              <option value="90d">90 derniers jours</option>
              <option value="1y">Cette année</option>
            </select>
            <button
              onClick={handleRefresh}
              className="flex items-center gap-2 px-6 py-3 bg-primary-500 hover:bg-primary-600 text-white rounded-xl transition-all duration-200 shadow-sm hover:shadow-md"
            >
              <RefreshCw className="w-5 h-5" />
              Actualiser
            </button>
          </div>
        </div>

        {/* Navigation par Onglets */}
        <div className="flex items-center space-x-1 mb-8 bg-white rounded-xl p-2 border border-primary-200 shadow-sm">
          {[
            { id: 'overview', label: 'Vue d\'ensemble', icon: Home },
            { id: 'bookings', label: 'Réservations', icon: Calendar },
            { id: 'residences', label: 'Résidences', icon: Building },
            { id: 'communication', label: 'Communication', icon: MessageSquare }
          ].map((tab) => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center space-x-2 px-4 py-3 rounded-lg transition-all duration-200 font-medium text-sm ${
                  activeTab === tab.id
                    ? 'bg-primary-500 text-white shadow-md'
                    : 'text-gray-600 hover:bg-primary-50 hover:text-primary-700'
                }`}
              >
                <Icon className="w-4 h-4" />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* KPI Cards - Réutilisable pour tous les onglets */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {getKPIConfig(activeTab).map((kpi, index) => (
            <KPICard key={`${activeTab}-${index}`} {...kpi} />
          ))}
        </div>

        {/* Contenu spécifique par onglet */}
        <div className="grid grid-cols-12 gap-6 mb-8">
          {/* Graphique principal */}
          <div className="col-span-12 lg:col-span-8">
            <ChartContainer
              title={
                activeTab === 'bookings' ? 'Tendances des Réservations par Statut' :
                activeTab === 'residences' ? 'Performance des Résidences par Type' :
                activeTab === 'communication' ? 'Volume des Communications par Canal' :
                'Évolution Générale'
              }
              subtitle={
                activeTab === 'bookings' ? 'Réservations par statut sur 12 mois' :
                activeTab === 'residences' ? 'Performance par type de résidence' :
                activeTab === 'communication' ? 'Communications par canal sur 12 mois' :
                'Vue globale des performances'
              }
              legends={getChartLegends(activeTab)}
              rightValue={
                activeTab === 'bookings' ? '82.4%' :
                activeTab === 'residences' ? '94.2%' :
                activeTab === 'communication' ? '98.2%' :
                'Vue Globale'
              }
              rightLabel={
                activeTab === 'bookings' ? 'Taux de succès' :
                activeTab === 'residences' ? 'Satisfaction globale' :
                activeTab === 'communication' ? 'Taux de résolution' :
                'Performances générales'
              }
            >
              {activeTab === 'communication' ? (
                <SVGChart type="area" />
              ) : activeTab === 'residences' ? (
                <SVGChart type="bar" />
              ) : (
                <SVGChart type="line" />
              )}
            </ChartContainer>
          </div>

          {/* Sidebar avec métriques */}
          <div className="col-span-12 lg:col-span-4 space-y-6">
            {/* Donut Chart */}
            <DonutChart 
              data={getDonutData()}
              centerValue="2.74K"
              centerLabel="Total"
            />

            {/* Métriques spécifiques */}
            <MetricsList 
              title={
                activeTab === 'bookings' ? 'Distribution par Statut' :
                activeTab === 'residences' ? 'Répartition par Type' :
                activeTab === 'communication' ? 'Répartition par Canal' :
                'Résumé Activité'
              }
              items={
                activeTab === 'bookings' ? getMetricsData('bookingDistribution') :
                activeTab === 'residences' ? getMetricsData('residenceTypes') :
                activeTab === 'communication' ? getMetricsData('communicationChannels') :
                [
                  { label: 'Réservations actives', value: String((dashboardData.bookingStats?.confirmedBookings || 0) + (dashboardData.bookingStats?.pendingBookings || 0)), color: 'bg-primary-500' },
                  { label: 'Résidences disponibles', value: String(dashboardData.residenceStats?.available || 0), color: 'bg-primary-300' },
                  { label: 'Messages non lus', value: String(dashboardData.communicationStats?.messages?.unread || 0), color: 'bg-primary-700' }
                ]
              }
            />

            {/* Performance hebdomadaire */}
            <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm">
              <h4 className="text-lg font-bold text-gray-900 mb-4">Performance Hebdomadaire</h4>
              <div className="space-y-3">
                {weeklyData.map((day, index) => (
                  <div key={day.day} className="flex items-center justify-between">
                    <span className="text-sm text-gray-600 w-20 font-medium">{day.day}</span>
                    <div className="flex-1 mx-3 h-3 bg-primary-100 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-gradient-to-r from-primary-500 to-primary-300 rounded-full transition-all duration-1000"
                        style={{ width: `${(day.total / 5) * 100}%` }}
                      ></div>
                    </div>
                    <span className="text-sm text-primary-700 font-medium w-12 text-right">
                      {day.total.toFixed(1)}K
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Section détaillée selon l'onglet */}
        {activeTab !== 'overview' && (
          <div className="grid grid-cols-12 gap-6 mb-8">
            {/* Performance Metrics */}
            <div className="col-span-12 lg:col-span-6">
              <PerformanceMetrics 
                title="Indicateurs de Performance"
                metrics={
                  activeTab === 'bookings' ? getPerformanceData('booking') :
                  activeTab === 'communication' ? getPerformanceData('communication') :
                  getPerformanceData('booking')
                }
              />
            </div>

            {/* Métriques secondaires */}
            <div className="col-span-12 lg:col-span-6">
              {activeTab === 'residences' ? (
                <MetricsList 
                  title="Équipements les Plus Demandés"
                  items={getMetricsData('amenities')}
                  showPercentage={true}
                />
              ) : activeTab === 'communication' ? (
                <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm">
                  <h4 className="text-lg font-bold text-gray-900 mb-4">Équipe Support - Performance</h4>
                  <div className="space-y-3">
                    {[
                      { name: 'Sarah K.', messages: 67, rating: 4.9, status: 'online' },
                      { name: 'Mohamed A.', messages: 54, rating: 4.8, status: 'online' },
                      { name: 'Fatou D.', messages: 48, rating: 4.7, status: 'busy' },
                      { name: 'Koffi J.', messages: 41, rating: 4.6, status: 'offline' }
                    ].map((agent, index) => (
                      <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                        <div className="flex items-center space-x-3">
                          <div className={`w-3 h-3 rounded-full ${
                            agent.status === 'online' ? 'bg-green-400' : 
                            agent.status === 'busy' ? 'bg-yellow-400' : 'bg-gray-400'
                          }`}></div>
                          <div>
                            <span className="text-gray-700 font-medium text-sm">{agent.name}</span>
                            <div className="flex items-center space-x-1 text-xs text-gray-500">
                              <Star className="w-3 h-3 text-yellow-400 fill-current" />
                              <span>{agent.rating}</span>
                            </div>
                          </div>
                        </div>
                        <div className="text-primary-600 font-bold text-sm">
                          {agent.messages} msg
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm">
                  <h4 className="text-lg font-bold text-gray-900 mb-4">Top Résidences</h4>
                  <div className="space-y-3">
                    {[
                      { name: 'Villa Cocody Premium', rating: 4.9, bookings: 34 },
                      { name: 'Appart Plateau Centre', rating: 4.8, bookings: 28 },
                      { name: 'Studio Marcory Moderne', rating: 4.7, bookings: 22 },
                      { name: 'Duplex Riviera Golf', rating: 4.8, bookings: 19 }
                    ].map((residence, index) => (
                      <div key={index} className="flex items-center justify-between p-3 bg-primary-50 rounded-lg">
                        <div>
                          <span className="text-gray-700 font-medium text-sm">{residence.name}</span>
                          <div className="flex items-center space-x-1 text-xs text-gray-500">
                            <Star className="w-3 h-3 text-yellow-400 fill-current" />
                            <span>{residence.rating}</span>
                          </div>
                        </div>
                        <div className="text-primary-600 font-bold text-sm">
                          {residence.bookings} résa
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Section Composants Spécialisés */}
        {activeTab !== 'overview' && (
          <div className="grid grid-cols-12 gap-6 mb-8">
            <div className="col-span-12">
              <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm">
                <h3 className="text-xl font-bold text-gray-900 mb-6">
                  {activeTab === 'bookings' ? 'Analyse Détaillée des Réservations' :
                   activeTab === 'residences' ? 'Analyse Détaillée des Résidences' :
                   'Analyse Détaillée des Communications'}
                </h3>
                {activeTab === 'bookings' && <BookingStats data={dashboardData.bookingStats} />}
                {activeTab === 'residences' && <ResidenceStats data={dashboardData.residenceStats} />}
                {activeTab === 'communication' && <CommunicationStats data={dashboardData.communicationStats} />}
              </div>
            </div>
          </div>
        )}

        {/* Vue d'ensemble avec graphique principal */}
        {activeTab === 'overview' && (
          <div className="grid grid-cols-12 gap-6 mb-8">
            <div className="col-span-12 lg:col-span-8">
              <ChartContainer
                title="Évolution des Réservations par Période"
                subtitle="Données comparatives sur 12 mois"
                legends={getChartLegends('overview')}
                rightValue="2.74K"
                rightLabel="Total mensuel"
              >
                {dashboardData.revenueData ? (
                  <div className="h-full">
                    <AnalyticsChart
                      data={[
                        { name: 'Jan', revenus: dashboardData.revenueData.monthlyData?.[0] || 0, reservations: dashboardData.bookingStats?.monthlyBookings?.[0] || 0 },
                        { name: 'Fév', revenus: dashboardData.revenueData.monthlyData?.[1] || 0, reservations: dashboardData.bookingStats?.monthlyBookings?.[1] || 0 },
                        { name: 'Mar', revenus: dashboardData.revenueData.monthlyData?.[2] || 0, reservations: dashboardData.bookingStats?.monthlyBookings?.[2] || 0 },
                        { name: 'Avr', revenus: dashboardData.revenueData.monthlyData?.[3] || 0, reservations: dashboardData.bookingStats?.monthlyBookings?.[3] || 0 },
                        { name: 'Mai', revenus: dashboardData.revenueData.monthlyData?.[4] || 0, reservations: dashboardData.bookingStats?.monthlyBookings?.[4] || 0 },
                        { name: 'Juin', revenus: dashboardData.revenueData.monthlyData?.[5] || 0, reservations: dashboardData.bookingStats?.monthlyBookings?.[5] || 0 },
                      ]}
                      xKey="name"
                      yKeys={[
                        { key: 'revenus', name: 'Revenus (XOF)', color: '#3F51B5' },
                        { key: 'reservations', name: 'Réservations', color: '#9FA8DA' },
                      ]}
                    />
                  </div>
                ) : (
                  <SVGChart type="line" />
                )}
              </ChartContainer>
            </div>
            
            <div className="col-span-12 lg:col-span-4">
              <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm">
                <h4 className="text-lg font-bold text-gray-900 mb-4">
                  Résumé Activité
                </h4>
                <div className="space-y-3">
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600">Réservations actives</span>
                    <span className="text-primary-700 font-medium">
                      {(dashboardData.bookingStats?.confirmedBookings || 0) + (dashboardData.bookingStats?.pendingBookings || 0)}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600">Résidences disponibles</span>
                    <span className="text-primary-700 font-medium">
                      {dashboardData.residenceStats?.available || 0}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600">Messages non lus</span>
                    <span className="text-primary-700 font-medium">
                      {dashboardData.communicationStats?.messages?.unread || 0}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Bottom Section - Data Tables */}
        <div className="grid grid-cols-12 gap-6">
          {/* Data Table */}
          <div className="col-span-12 lg:col-span-4">
            <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm">
              <h4 className="text-lg font-bold text-gray-900 mb-4">Tableau de Données</h4>
              <div className="overflow-hidden">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-primary-200">
                      <th className="text-left py-2 text-gray-600 font-medium">Mois</th>
                      <th className="text-center py-2 text-gray-600 font-medium">2023</th>
                      <th className="text-center py-2 text-gray-600 font-medium">2024</th>
                      <th className="text-center py-2 text-gray-600 font-medium">2025</th>
                      <th className="text-right py-2 text-gray-600 font-medium">Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    {monthlyData.slice(0, 6).map((row, index) => (
                      <tr key={row.month} className="border-b border-primary-100">
                        <td className="py-2 text-gray-700 font-medium">{row.month}</td>
                        <td className="text-center py-2 text-gray-900">{Math.floor(row.revenus)}</td>
                        <td className="text-center py-2 text-gray-900">{Math.floor(row.revenus * 1.1)}</td>
                        <td className="text-center py-2 text-gray-900">{Math.floor(row.revenus * 0.9)}</td>
                        <td className="text-right py-2 text-primary-600 font-medium">
                          {Math.floor(row.revenus * 3)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          {/* Yearly Comparison */}
          <div className="col-span-12 lg:col-span-4">
            <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm">
              <h4 className="text-lg font-bold text-gray-900 mb-4">Évolution Annuelle</h4>
              <div className="space-y-4">
                {[
                  { year: '2023', total: 8.1 },
                  { year: '2024', total: 9.0 },
                  { year: '2025', total: 9.9 }
                ].map((year, index) => (
                  <div key={year.year} className="space-y-2">
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-600 font-medium">{year.year}</span>
                      <span className="text-sm text-primary-700 font-medium">{year.total}K</span>
                    </div>
                    <div className="w-full h-3 bg-primary-100 rounded-full overflow-hidden">
                      <div 
                        className="h-full bg-gradient-to-r from-primary-500 to-primary-300 rounded-full transition-all duration-1000"
                        style={{ width: `${(year.total / 10) * 100}%` }}
                      ></div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Quick Stats */}
          <div className="col-span-12 lg:col-span-4">
            <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm">
              <h4 className="text-lg font-bold text-gray-900 mb-4">Statistiques Rapides</h4>
              <div className="grid grid-cols-2 gap-4">
                <div className="text-center p-3 bg-primary-50 rounded-lg">
                  <div className="text-2xl font-bold text-primary-600">247</div>
                  <div className="text-xs text-gray-600">Réservations</div>
                </div>
                <div className="text-center p-3 bg-primary-50 rounded-lg">
                  <div className="text-2xl font-bold text-primary-600">142</div>
                  <div className="text-xs text-gray-600">Résidences</div>
                </div>
                <div className="text-center p-3 bg-primary-50 rounded-lg">
                  <div className="text-2xl font-bold text-primary-600">1.8K</div>
                  <div className="text-xs text-gray-600">Messages</div>
                </div>
                <div className="text-center p-3 bg-primary-50 rounded-lg">
                  <div className="text-2xl font-bold text-primary-600">4.6</div>
                  <div className="text-xs text-gray-600">Note moyenne</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardPage;