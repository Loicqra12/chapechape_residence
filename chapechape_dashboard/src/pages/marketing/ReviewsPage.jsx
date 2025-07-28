import React, { useState, useEffect } from 'react';
import {
  Star,
  MessageSquare,
  Check,
  X,
  Flag,
  Reply,
  Filter,
  Search,
  MoreHorizontal,
  Calendar,
  TrendingUp,
  Users,
  ThumbsUp,
  AlertCircle,
  Eye,
  Download
} from 'lucide-react';
import { marketingService } from '../../services/marketingService';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import toast from 'react-hot-toast';

// ============ COMPOSANTS RÉUTILISABLES ============

// Composant Stats Card pour les avis
const ReviewStatsCard = ({ 
  icon: Icon, 
  title, 
  value, 
  subtitle, 
  trend, 
  color = 'primary' 
}) => {
  const colorClasses = {
    primary: 'bg-gradient-to-br from-blue-50 to-indigo-50 text-blue-600',
    success: 'bg-gradient-to-br from-green-50 to-emerald-50 text-green-600',
    warning: 'bg-gradient-to-br from-yellow-50 to-amber-50 text-yellow-600',
    danger: 'bg-gradient-to-br from-red-50 to-rose-50 text-red-600'
  };

  return (
    <div className="bg-white rounded-2xl p-6 border border-primary-200 hover:border-primary-300 transition-all duration-200 shadow-sm hover:shadow-md">
      <div className="flex items-center justify-between mb-4">
        <div className={`p-3 rounded-xl ${colorClasses[color]}`}>
          <Icon className="w-6 h-6" />
        </div>
        {trend && (
          <div className={`flex items-center space-x-1 text-sm font-medium ${
            trend.positive ? 'text-green-600' : 'text-red-600'
          }`}>
            <TrendingUp className={`w-4 h-4 ${trend.positive ? '' : 'rotate-180'}`} />
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
};

// Composant Review Card
const ReviewCard = ({ review, onApprove, onReject, onReply, onFlag }) => {
  const getStatusStyle = (status) => {
    const styles = {
      approved: 'bg-green-100 text-green-800 border-green-200',
      pending: 'bg-yellow-100 text-yellow-800 border-yellow-200',
      rejected: 'bg-red-100 text-red-800 border-red-200'
    };
    return styles[status] || 'bg-gray-100 text-gray-800 border-gray-200';
  };

  const getStatusLabel = (status) => {
    const labels = {
      approved: 'Approuvé',
      pending: 'En attente',
      rejected: 'Rejeté'
    };
    return labels[status] || status;
  };

  const renderStars = (rating) => {
    return Array.from({ length: 5 }, (_, index) => (
      <Star
        key={index}
        className={`w-4 h-4 ${
          index < rating
            ? 'text-yellow-400 fill-current'
            : 'text-gray-300'
        }`}
      />
    ));
  };

  return (
    <div className="bg-white rounded-2xl p-6 border border-primary-200 hover:border-primary-300 transition-all duration-300 shadow-sm hover:shadow-lg group">
      {/* Header avec utilisateur */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-3">
          <div className="relative">
            {review.user?.avatar ? (
              <img 
                src={review.user.avatar} 
                alt={review.user.name}
                className="w-12 h-12 rounded-full object-cover"
              />
            ) : (
              <div className="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center">
                <span className="text-primary-600 font-semibold text-lg">
                  {review.user?.name?.charAt(0)?.toUpperCase() || '?'}
                </span>
              </div>
            )}
            <div className="absolute -bottom-1 -right-1 w-4 h-4 bg-green-500 border-2 border-white rounded-full"></div>
          </div>
          <div>
            <h4 className="font-semibold text-gray-900">{review.user?.name || 'Utilisateur anonyme'}</h4>
            <p className="text-sm text-gray-500">
              {format(new Date(review.createdAt), 'dd MMMM yyyy', { locale: fr })}
            </p>
          </div>
        </div>
        
        <div className="flex items-center space-x-2">
          <span className={`px-3 py-1 text-xs font-medium rounded-full border ${getStatusStyle(review.status)}`}>
            {getStatusLabel(review.status)}
          </span>
          <button className="opacity-0 group-hover:opacity-100 transition-opacity p-1 hover:bg-gray-100 rounded">
            <MoreHorizontal className="w-4 h-4 text-gray-500" />
          </button>
        </div>
      </div>

      {/* Rating */}
      <div className="flex items-center space-x-2 mb-4">
        <div className="flex space-x-1">
          {renderStars(review.rating)}
        </div>
        <span className="text-sm font-medium text-gray-700">
          {review.rating}/5
        </span>
      </div>

      {/* Commentaire */}
      <div className="mb-4">
        <p className="text-gray-700 leading-relaxed">
          {review.comment}
        </p>
      </div>

      {/* Résidence */}
      {review.residence && (
        <div className="mb-4 p-3 bg-gray-50 rounded-lg">
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-primary-100 rounded-lg flex items-center justify-center">
              <MessageSquare className="w-4 h-4 text-primary-600" />
            </div>
            <div>
              <p className="text-sm font-medium text-gray-900">
                {review.residence.name}
              </p>
              <p className="text-xs text-gray-500">Résidence évaluée</p>
            </div>
          </div>
        </div>
      )}

      {/* Actions */}
      <div className="flex items-center justify-between pt-4 border-t border-gray-100">
        <div className="flex items-center space-x-2">
          {review.status === 'pending' && (
            <>
              <button
                onClick={() => onApprove(review.id)}
                className="flex items-center space-x-1 px-3 py-1.5 text-green-600 hover:bg-green-50 rounded-lg transition-colors duration-200"
                title="Approuver"
              >
                <Check className="w-4 h-4" />
                <span className="text-sm font-medium">Approuver</span>
              </button>
              <button
                onClick={() => onReject(review.id)}
                className="flex items-center space-x-1 px-3 py-1.5 text-red-600 hover:bg-red-50 rounded-lg transition-colors duration-200"
                title="Rejeter"
              >
                <X className="w-4 h-4" />
                <span className="text-sm font-medium">Rejeter</span>
              </button>
            </>
          )}
        </div>
        
        <div className="flex items-center space-x-2">
          <button
            onClick={() => onReply(review)}
            className="flex items-center space-x-1 px-3 py-1.5 text-primary-600 hover:bg-primary-50 rounded-lg transition-colors duration-200"
            title="Répondre"
          >
            <Reply className="w-4 h-4" />
            <span className="text-sm font-medium">Répondre</span>
          </button>
          <button
            onClick={() => onFlag(review.id)}
            className="flex items-center space-x-1 px-3 py-1.5 text-yellow-600 hover:bg-yellow-50 rounded-lg transition-colors duration-200"
            title="Signaler"
          >
            <Flag className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Réponse existante */}
      {review.response && (
        <div className="mt-4 p-4 bg-primary-50 border border-primary-200 rounded-lg">
          <div className="flex items-center space-x-2 mb-2">
            <div className="w-6 h-6 bg-primary-500 rounded-full flex items-center justify-center">
              <Reply className="w-3 h-3 text-white" />
            </div>
            <span className="text-sm font-semibold text-primary-800">
              Réponse de l'équipe ChapeChape
            </span>
          </div>
          <p className="text-sm text-primary-700 leading-relaxed">
            {review.response}
          </p>
        </div>
      )}
    </div>
  );
};

// Composant Filtre
const FilterSection = ({ filter, setFilter, searchTerm, setSearchTerm }) => (
  <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm mb-8">
    <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center">
      <Filter className="w-5 h-5 mr-2 text-primary-600" />
      Filtres et Recherche
    </h3>
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Rechercher
        </label>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder="Rechercher par nom ou commentaire..."
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>
      
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Statut
        </label>
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
        >
          <option value="all">Tous les avis</option>
          <option value="pending">En attente</option>
          <option value="approved">Approuvés</option>
          <option value="rejected">Rejetés</option>
        </select>
      </div>
      
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Note minimale
        </label>
        <select className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500">
          <option value="">Toutes les notes</option>
          <option value="5">5 étoiles</option>
          <option value="4">4+ étoiles</option>
          <option value="3">3+ étoiles</option>
          <option value="2">2+ étoiles</option>
          <option value="1">1+ étoile</option>
        </select>
      </div>
    </div>
  </div>
);

// Dialog de réponse
const ReplyDialog = ({ isOpen, onClose, review, onSubmit }) => {
  const [response, setResponse] = useState(review?.response || '');

  const handleSubmit = () => {
    if (response.trim()) {
      onSubmit(review.id, response);
      onClose();
    }
  };

  if (!isOpen || !review) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-900">Répondre à l'avis</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Avis original */}
        <div className="bg-gray-50 rounded-lg p-4 mb-6">
          <div className="flex items-center space-x-3 mb-3">
            <div className="w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center">
              <span className="text-primary-600 font-semibold">
                {review.user?.name?.charAt(0)?.toUpperCase() || '?'}
              </span>
            </div>
            <div>
              <h4 className="font-semibold text-gray-900">{review.user?.name}</h4>
              <div className="flex space-x-1">
                {Array.from({ length: 5 }, (_, index) => (
                  <Star
                    key={index}
                    className={`w-4 h-4 ${
                      index < review.rating
                        ? 'text-yellow-400 fill-current'
                        : 'text-gray-300'
                    }`}
                  />
                ))}
              </div>
            </div>
          </div>
          <p className="text-gray-700">{review.comment}</p>
        </div>

        {/* Zone de réponse */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Votre réponse
          </label>
          <textarea
            rows={6}
            className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 resize-none"
            placeholder="Rédigez votre réponse professionnelle et bienveillante..."
            value={response}
            onChange={(e) => setResponse(e.target.value)}
          />
          <div className="flex justify-between items-center mt-2">
            <p className="text-sm text-gray-500">
              {response.length}/500 caractères
            </p>
            <div className="flex space-x-2">
              <button className="text-sm text-primary-600 hover:text-primary-700">
                Modèle de réponse
              </button>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="flex items-center justify-end space-x-4">
          <button
            onClick={onClose}
            className="px-6 py-2 text-gray-600 hover:text-gray-800 font-medium"
          >
            Annuler
          </button>
          <button
            onClick={handleSubmit}
            disabled={!response.trim()}
            className="px-6 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium transition-colors duration-200"
          >
            Répondre
          </button>
        </div>
      </div>
    </div>
  );
};

// ============ COMPOSANT PRINCIPAL ============

const ReviewsPage = () => {
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedReview, setSelectedReview] = useState(null);
  const [filter, setFilter] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    loadReviews();
  }, []);

  const loadReviews = async () => {
    setLoading(true);
    try {
      const response = await marketingService.getReviews();
      if (response.success) {
        setReviews(response.data);
        toast.success('Avis chargés avec succès');
      }
    } catch (error) {
      console.error('Erreur lors du chargement des avis:', error);
      toast.error('Erreur lors du chargement des avis');
    }
    setLoading(false);
  };

  const handleApprove = async (reviewId) => {
    try {
      // Simuler l'approbation
      setReviews(prev => prev.map(review => 
        review.id === reviewId ? { ...review, status: 'approved' } : review
      ));
      toast.success('Avis approuvé avec succès');
    } catch (error) {
      toast.error('Erreur lors de l\'approbation');
    }
  };

  const handleReject = async (reviewId) => {
    try {
      // Simuler le rejet
      setReviews(prev => prev.map(review => 
        review.id === reviewId ? { ...review, status: 'rejected' } : review
      ));
      toast.success('Avis rejeté');
    } catch (error) {
      toast.error('Erreur lors du rejet');
    }
  };

  const handleReply = (review) => {
    setSelectedReview(review);
    setOpenDialog(true);
  };

  const handleSubmitReply = async (reviewId, response) => {
    try {
      // Simuler l'ajout de réponse
      setReviews(prev => prev.map(review => 
        review.id === reviewId ? { ...review, response } : review
      ));
      toast.success('Réponse ajoutée avec succès');
    } catch (error) {
      toast.error('Erreur lors de l\'ajout de la réponse');
    }
  };

  const handleFlag = async (reviewId) => {
    try {
      toast.success('Avis signalé pour révision');
    } catch (error) {
      toast.error('Erreur lors du signalement');
    }
  };

  const getReviewStats = () => {
    const total = reviews.length;
    const approved = reviews.filter(r => r.status === 'approved').length;
    const pending = reviews.filter(r => r.status === 'pending').length;
    const avgRating = reviews.length > 0 
      ? (reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length).toFixed(1)
      : 0;

    return [
      {
        icon: MessageSquare,
        title: 'Total Avis',
        value: total.toString(),
        subtitle: 'Tous les avis reçus',
        trend: { positive: true, value: '+12%' },
        color: 'primary'
      },
      {
        icon: Check,
        title: 'Avis Approuvés',
        value: approved.toString(),
        subtitle: 'Avis publiés',
        trend: { positive: true, value: '+8%' },
        color: 'success'
      },
      {
        icon: AlertCircle,
        title: 'En Attente',
        value: pending.toString(),
        subtitle: 'À modérer',
        trend: { positive: false, value: '-3%' },
        color: 'warning'
      },
      {
        icon: Star,
        title: 'Note Moyenne',
        value: `${avgRating}/5`,
        subtitle: 'Satisfaction globale',
        trend: { positive: true, value: '+0.2' },
        color: 'primary'
      }
    ];
  };

  const filteredReviews = reviews.filter(review => {
    const matchesFilter = filter === 'all' || review.status === filter;
    const matchesSearch = searchTerm === '' || 
      review.user?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      review.comment?.toLowerCase().includes(searchTerm.toLowerCase());
    
    return matchesFilter && matchesSearch;
  });

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="flex flex-col items-center space-y-4">
          <div className="relative">
            <div className="w-16 h-16 border-4 border-primary-200 rounded-full animate-spin"></div>
            <div className="absolute top-0 left-0 w-16 h-16 border-4 border-primary-600 border-t-transparent rounded-full animate-spin"></div>
          </div>
          <p className="text-gray-600 font-medium text-lg">Chargement des avis clients...</p>
        </div>
      </div>
    );
  }

  const reviewStats = getReviewStats();

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="container mx-auto px-6 py-8 max-w-[1600px]">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center space-x-4">
            <div className="w-16 h-16 bg-primary-500 rounded-2xl flex items-center justify-center shadow-lg">
              <Star className="w-8 h-8 text-white" />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Avis Clients</h1>
              <p className="text-lg text-gray-600">Gestion et modération des avis</p>
            </div>
          </div>
          <div className="flex items-center space-x-3">
            <button className="flex items-center gap-2 px-4 py-2 bg-white border border-primary-200 text-primary-700 rounded-lg hover:bg-primary-50 transition-colors duration-200">
              <Download className="w-4 h-4" />
              Exporter
            </button>
            <button className="flex items-center gap-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors duration-200">
              <Eye className="w-4 h-4" />
              Vue publique
            </button>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {reviewStats.map((stat, index) => (
            <ReviewStatsCard key={index} {...stat} />
          ))}
        </div>

        {/* Filtres */}
        <FilterSection 
          filter={filter}
          setFilter={setFilter}
          searchTerm={searchTerm}
          setSearchTerm={setSearchTerm}
        />

        {/* Grille des avis */}
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
          {filteredReviews.map((review) => (
            <ReviewCard
              key={review.id}
              review={review}
              onApprove={handleApprove}
              onReject={handleReject}
              onReply={handleReply}
              onFlag={handleFlag}
            />
          ))}
        </div>

        {/* Message si aucun avis */}
        {filteredReviews.length === 0 && (
          <div className="text-center py-12">
            <div className="w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <MessageSquare className="w-12 h-12 text-gray-400" />
            </div>
            <h3 className="text-xl font-semibold text-gray-900 mb-2">
              Aucun avis trouvé
            </h3>
            <p className="text-gray-600">
              {searchTerm || filter !== 'all' 
                ? 'Aucun avis ne correspond à vos critères de recherche.'
                : 'Aucun avis client n\'a encore été soumis.'
              }
            </p>
          </div>
        )}

        {/* Dialog de réponse */}
        <ReplyDialog
          isOpen={openDialog}
          onClose={() => {
            setOpenDialog(false);
            setSelectedReview(null);
          }}
          review={selectedReview}
          onSubmit={handleSubmitReply}
        />
      </div>
    </div>
  );
};

export default ReviewsPage;