import React, { useState, useEffect } from 'react';
import {
  TrendingUp,
  TrendingDown,
  DollarSign,
  CreditCard,
  Calendar,
  Filter,
  Download,
  RefreshCw,
  FileText,
  BarChart3,
  PieChart,
  Activity,
  Eye,
  Users,
  Target
} from 'lucide-react';
import { financeService } from '../../services/financeService';
import { format, subMonths, startOfMonth, endOfMonth } from 'date-fns';
import { fr } from 'date-fns/locale';
import StatsCards from '../../components/finance/StatsCards';
import toast from 'react-hot-toast';

// ============ COMPOSANTS RÉUTILISABLES ============

// Composant Metric Card réutilisable
const MetricCard = ({ 
  icon: Icon, 
  title, 
  value, 
  subtitle, 
  trend, 
  bgColor = 'bg-white', 
  iconColor = 'text-primary-600' 
}) => (
  <div className={`${bgColor} rounded-2xl p-6 border border-primary-200 hover:border-primary-300 transition-all duration-200 shadow-sm hover:shadow-md`}>
    <div className="flex items-center justify-between mb-4">
      <div className={`p-3 bg-primary-50 rounded-xl`}>
        <Icon className={`w-6 h-6 ${iconColor}`} />
      </div>
      {trend && (
        <div className={`flex items-center space-x-1 text-sm font-medium ${
          trend.positive ? 'text-green-600' : 'text-red-600'
        }`}>
          {trend.positive ? (
            <TrendingUp className="w-4 h-4" />
          ) : (
            <TrendingDown className="w-4 h-4" />
          )}
          <span>{trend.value}</span>
        </div>
      )}
    </div>
    
    <div className="mb-2">
      <h3 className="text-sm font-medium text-gray-600 mb-1 uppercase tracking-wide">
        {title}
      </h3>
      <p className="text-3xl font-bold text-gray-900">{value}</p>
    </div>
    
    <div className="text-gray-500 text-sm">{subtitle}</div>
  </div>
);

// Composant Chart Container réutilisable
const ChartContainer = ({ title, subtitle, rightContent, children, height = 'h-96' }) => (
  <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm hover:shadow-lg transition-shadow duration-300">
    <div className="flex items-center justify-between mb-6">
      <div>
        <h3 className="text-xl font-bold text-gray-900 mb-1">{title}</h3>
        {subtitle && <p className="text-sm text-gray-600">{subtitle}</p>}
      </div>
      {rightContent && <div>{rightContent}</div>}
    </div>
    <div className={height}>{children}</div>
  </div>
);

// Composant Custom Bar Chart
const CustomBarChart = ({ data, formatValue }) => (
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
      
      {/* Bars */}
      {data.map((item, index) => {
        const x = 80 + (index * (680 / data.length));
        const barWidth = Math.max(40, (680 / data.length) - 10);
        const maxValue = Math.max(...data.map(d => d.total));
        
        // Heights proportional to values
        const completedHeight = (item.completed / maxValue) * 200;
        const pendingHeight = (item.pending / maxValue) * 200;
        const failedHeight = (item.failed / maxValue) * 200;
        
        return (
          <g key={index}>
            {/* Completed bar */}
            <rect
              x={x}
              y={250 - completedHeight}
              width={barWidth * 0.8}
              height={completedHeight}
              fill="#10B981"
              rx="4"
            />
            {/* Pending bar */}
            <rect
              x={x + barWidth * 0.8 + 2}
              y={250 - pendingHeight}
              width={barWidth * 0.8}
              height={pendingHeight}
              fill="#F59E0B"
              rx="4"
            />
            {/* Failed bar */}
            <rect
              x={x + barWidth * 1.6 + 4}
              y={250 - failedHeight}
              width={barWidth * 0.8}
              height={failedHeight}
              fill="#EF4444"
              rx="4"
            />
          </g>
        );
      })}
    </svg>
    
    {/* X-axis labels */}
    <div className="absolute bottom-0 left-0 right-0 flex justify-between px-12 text-xs text-gray-600">
      {data.map((item, index) => (
        <span key={index} className="transform -rotate-45 origin-left">
          {item.name.split(' ')[0]}
        </span>
      ))}
    </div>
    
    {/* Legend */}
    <div className="absolute top-4 right-4 flex space-x-4 text-xs">
      <div className="flex items-center space-x-1">
        <div className="w-3 h-3 bg-green-500 rounded"></div>
        <span>Complétés</span>
      </div>
      <div className="flex items-center space-x-1">
        <div className="w-3 h-3 bg-yellow-500 rounded"></div>
        <span>En attente</span>
      </div>
      <div className="flex items-center space-x-1">
        <div className="w-3 h-3 bg-red-500 rounded"></div>
        <span>Échoués</span>
      </div>
    </div>
  </div>
);

// Composant Custom Pie Chart
const CustomPieChart = ({ data, formatValue }) => {
  const total = data.reduce((sum, item) => sum + item.value, 0);
  let currentAngle = 0;
  const colors = ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#EC4899'];

  const createArcPath = (centerX, centerY, radius, startAngle, endAngle) => {
    const start = polarToCartesian(centerX, centerY, radius, endAngle);
    const end = polarToCartesian(centerX, centerY, radius, startAngle);
    const largeArcFlag = endAngle - startAngle <= 180 ? "0" : "1";
    return `M ${centerX} ${centerY} L ${start.x} ${start.y} A ${radius} ${radius} 0 ${largeArcFlag} 0 ${end.x} ${end.y} Z`;
  };

  const polarToCartesian = (centerX, centerY, radius, angleInDegrees) => {
    const angleInRadians = (angleInDegrees - 90) * Math.PI / 180.0;
    return {
      x: centerX + (radius * Math.cos(angleInRadians)),
      y: centerY + (radius * Math.sin(angleInRadians))
    };
  };

  return (
    <div className="h-full flex items-center justify-center">
      <div className="relative">
        <svg width="300" height="300" viewBox="0 0 300 300">
          {data.map((item, index) => {
            const percentage = (item.value / total) * 100;
            const angle = (percentage / 100) * 360;
            const path = createArcPath(150, 150, 120, currentAngle, currentAngle + angle);
            currentAngle += angle;
            
            return (
              <path
                key={index}
                d={path}
                fill={colors[index % colors.length]}
                stroke="white"
                strokeWidth="2"
                className="hover:opacity-80 transition-opacity cursor-pointer"
              />
            );
          })}
          
          {/* Center circle */}
          <circle cx="150" cy="150" r="60" fill="white" />
          <text x="150" y="145" textAnchor="middle" className="text-sm font-medium fill-gray-600">
            Total
          </text>
          <text x="150" y="165" textAnchor="middle" className="text-lg font-bold fill-gray-900">
            {formatValue(total)}
          </text>
        </svg>
        
        {/* Legend */}
        <div className="absolute -right-48 top-1/2 transform -translate-y-1/2 space-y-2">
          {data.map((item, index) => (
            <div key={index} className="flex items-center space-x-2 text-sm">
              <div 
                className="w-4 h-4 rounded"
                style={{ backgroundColor: colors[index % colors.length] }}
              ></div>
              <span className="text-gray-700">{item.name}</span>
              <span className="text-gray-500">({((item.value / total) * 100).toFixed(1)}%)</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

// Composant Filter Section
const FilterSection = ({ dateRange, setDateRange, onUpdate, loading }) => (
  <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm mb-8">
    <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center">
      <Filter className="w-5 h-5 mr-2 text-primary-600" />
      Filtres et Période
    </h3>
    <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Date de début
        </label>
        <input
          type="date"
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
          value={dateRange.startDate}
          onChange={(e) => setDateRange({ ...dateRange, startDate: e.target.value })}
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Date de fin
        </label>
        <input
          type="date"
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
          value={dateRange.endDate}
          onChange={(e) => setDateRange({ ...dateRange, endDate: e.target.value })}
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Type de rapport
        </label>
        <select className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500">
          <option>Tous les paiements</option>
          <option>Paiements complétés</option>
          <option>Paiements en attente</option>
          <option>Paiements échoués</option>
        </select>
      </div>
      <div className="flex items-end">
        <button
          onClick={onUpdate}
          disabled={loading}
          className="w-full flex items-center justify-center px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-primary-500 disabled:opacity-50 transition-colors duration-200"
        >
          <RefreshCw className={`w-4 h-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
          Mettre à jour
        </button>
      </div>
    </div>
  </div>
);

// ============ COMPOSANT PRINCIPAL ============

const ReportsPage = () => {
  const [loading, setLoading] = useState(false);
  const [stats, setStats] = useState(null);
  const [payments, setPayments] = useState([]);
  const [dateRange, setDateRange] = useState({
    startDate: format(startOfMonth(subMonths(new Date(), 5)), 'yyyy-MM-dd'),
    endDate: format(endOfMonth(new Date()), 'yyyy-MM-dd'),
  });

  useEffect(() => {
    loadData();
  }, [dateRange]);

  const loadData = async () => {
    try {
      setLoading(true);
      const response = await financeService.getPayments({
        limit: 1000,
        filters: {
          startDate: dateRange.startDate,
          endDate: dateRange.endDate,
        },
      });

      if (response.success) {
        setPayments(response.data);
        await loadStats();
        toast.success('Données mises à jour avec succès');
      }
    } catch (error) {
      console.error('Erreur lors du chargement des données:', error);
      toast.error('Erreur lors du chargement des données');
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      const response = await financeService.getFinancialStats();
      if (response.success) {
        setStats(response.data);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des statistiques:', error);
    }
  };

  const getMonthlyData = () => {
    const monthlyData = {};
    payments.forEach(payment => {
      const date = new Date(payment.createdAt);
      const monthKey = format(date, 'yyyy-MM');
      const monthLabel = format(date, 'MMMM yyyy', { locale: fr });
      
      if (!monthlyData[monthKey]) {
        monthlyData[monthKey] = {
          name: monthLabel,
          total: 0,
          completed: 0,
          pending: 0,
          failed: 0,
        };
      }

      const amount = payment.amount || 0;
      monthlyData[monthKey].total += amount;

      switch (payment.status) {
        case 'completed':
          monthlyData[monthKey].completed += amount;
          break;
        case 'pending':
          monthlyData[monthKey].pending += amount;
          break;
        case 'failed':
          monthlyData[monthKey].failed += amount;
          break;
      }
    });

    return Object.values(monthlyData).sort((a, b) => 
      new Date(a.name) - new Date(b.name)
    );
  };

  const getPaymentMethodsData = () => {
    const methodsData = {};
    payments.forEach(payment => {
      if (payment.status === 'completed') {
        const method = financeService.getPaymentMethods()
          .find(m => m.id === payment.paymentMethod)?.name || 'Autre';
        
        if (!methodsData[method]) {
          methodsData[method] = {
            name: method,
            value: 0,
            count: 0,
          };
        }
        methodsData[method].value += payment.amount || 0;
        methodsData[method].count += 1;
      }
    });

    return Object.values(methodsData);
  };

  const formatCurrency = (value) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'XOF',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
  };

  const getFinancialMetrics = () => {
    const totalRevenue = payments.reduce((sum, p) => p.status === 'completed' ? sum + (p.amount || 0) : sum, 0);
    const totalTransactions = payments.length;
    const completedTransactions = payments.filter(p => p.status === 'completed').length;
    const avgTransactionValue = completedTransactions > 0 ? totalRevenue / completedTransactions : 0;
    const successRate = totalTransactions > 0 ? (completedTransactions / totalTransactions) * 100 : 0;

    return [
      {
        icon: DollarSign,
        title: 'Chiffre d\'Affaires Total',
        value: formatCurrency(totalRevenue),
        subtitle: `${completedTransactions} transactions complétées`,
        trend: { positive: true, value: '+12.5%' },
        bgColor: 'bg-gradient-to-br from-green-50 to-emerald-50',
        iconColor: 'text-green-600'
      },
      {
        icon: Activity,
        title: 'Total Transactions',
        value: totalTransactions.toString(),
        subtitle: 'Toutes périodes confondues',
        trend: { positive: true, value: '+8.3%' },
        bgColor: 'bg-gradient-to-br from-blue-50 to-indigo-50',
        iconColor: 'text-blue-600'
      },
      {
        icon: Target,
        title: 'Taux de Succès',
        value: `${successRate.toFixed(1)}%`,
        subtitle: 'Transactions réussies',
        trend: { positive: successRate > 85, value: `${successRate > 85 ? '+' : '-'}2.1%` },
        bgColor: 'bg-gradient-to-br from-purple-50 to-violet-50',
        iconColor: 'text-purple-600'
      },
      {
        icon: TrendingUp,
        title: 'Valeur Moyenne',
        value: formatCurrency(avgTransactionValue),
        subtitle: 'Par transaction',
        trend: { positive: true, value: '+5.7%' },
        bgColor: 'bg-gradient-to-br from-orange-50 to-amber-50',
        iconColor: 'text-orange-600'
      }
    ];
  };

  const monthlyData = getMonthlyData();
  const paymentMethodsData = getPaymentMethodsData();
  const financialMetrics = getFinancialMetrics();

  if (loading && payments.length === 0) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="flex flex-col items-center space-y-4">
          <div className="relative">
            <div className="w-16 h-16 border-4 border-primary-200 rounded-full animate-spin"></div>
            <div className="absolute top-0 left-0 w-16 h-16 border-4 border-primary-600 border-t-transparent rounded-full animate-spin"></div>
          </div>
          <p className="text-gray-600 font-medium text-lg">Chargement des rapports financiers...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="container mx-auto px-6 py-8 max-w-[1600px]">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center space-x-4">
            <div className="w-16 h-16 bg-primary-500 rounded-2xl flex items-center justify-center shadow-lg">
              <FileText className="w-8 h-8 text-white" />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Rapports Financiers</h1>
              <p className="text-lg text-gray-600">Analyse des paiements et des transactions</p>
            </div>
          </div>
          <div className="flex items-center space-x-3">
            <button className="flex items-center gap-2 px-4 py-2 bg-white border border-primary-200 text-primary-700 rounded-lg hover:bg-primary-50 transition-colors duration-200">
              <Download className="w-4 h-4" />
              Exporter
            </button>
            <button className="flex items-center gap-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors duration-200">
              <Eye className="w-4 h-4" />
              Vue détaillée
            </button>
          </div>
        </div>

        {/* Métriques Financières */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {financialMetrics.map((metric, index) => (
            <MetricCard key={index} {...metric} />
          ))}
        </div>

        {/* Filtres */}
        <FilterSection 
          dateRange={dateRange}
          setDateRange={setDateRange}
          onUpdate={loadData}
          loading={loading}
        />

        {/* Graphiques Principaux */}
        <div className="grid grid-cols-12 gap-6 mb-8">
          {/* Évolution mensuelle */}
          <div className="col-span-12">
            <ChartContainer
              title="Évolution Mensuelle des Paiements"
              subtitle="Comparaison des statuts de paiement par mois"
              rightContent={
                <div className="text-right">
                  <div className="text-2xl font-bold text-primary-600">
                    {formatCurrency(monthlyData.reduce((sum, m) => sum + m.total, 0))}
                  </div>
                  <div className="text-sm text-gray-600">Total période</div>
                </div>
              }
            >
              <CustomBarChart data={monthlyData} formatValue={formatCurrency} />
            </ChartContainer>
          </div>
        </div>

        {/* Analyse par Méthodes de Paiement */}
        <div className="grid grid-cols-12 gap-6 mb-8">
          {/* Pie Chart */}
          <div className="col-span-12 lg:col-span-8">
            <ChartContainer
              title="Distribution des Méthodes de Paiement"
              subtitle="Répartition du volume par méthode de paiement"
              height="h-[500px]"
            >
              <CustomPieChart data={paymentMethodsData} formatValue={formatCurrency} />
            </ChartContainer>
          </div>

          {/* Détails des méthodes */}
          <div className="col-span-12 lg:col-span-4 space-y-6">
            <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm">
              <h4 className="text-lg font-bold text-gray-900 mb-4 flex items-center">
                <CreditCard className="w-5 h-5 mr-2 text-primary-600" />
                Détails par Méthode
              </h4>
              <div className="space-y-4">
                {paymentMethodsData.map((method, index) => (
                  <div key={method.name} className="p-4 bg-gray-50 rounded-lg">
                    <div className="flex items-center justify-between mb-2">
                      <h5 className="font-medium text-gray-900">{method.name}</h5>
                      <span className="text-sm text-primary-600 font-medium">
                        {method.count} transactions
                      </span>
                    </div>
                    <div className="space-y-1 text-sm text-gray-600">
                      <div className="flex justify-between">
                        <span>Volume total:</span>
                        <span className="font-medium">{formatCurrency(method.value)}</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Moyenne/transaction:</span>
                        <span className="font-medium">
                          {formatCurrency(method.value / method.count)}
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Composant Stats Cards existant */}
        {stats && (
          <div className="mb-8">
            <h3 className="text-xl font-bold text-gray-900 mb-4">Statistiques Globales</h3>
            <StatsCards stats={stats} />
          </div>
        )}
      </div>
    </div>
  );
};

export default ReportsPage;