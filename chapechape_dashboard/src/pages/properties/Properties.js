import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  MagnifyingGlassIcon,
  FunnelIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  MapPinIcon,
  BanknotesIcon,
  HomeIcon,
  BuildingOfficeIcon,
  HomeModernIcon,
  EyeIcon,
  PencilIcon,
  TrashIcon,
  BeakerIcon,
  CheckIcon,
  CheckCircleIcon,
  XCircleIcon,
  XMarkIcon
} from '@heroicons/react/24/outline';
import toast from 'react-hot-toast';
import { adminService } from '../../services/adminService';

/** Icônes par code backend (catalogue meta) — défaut : BuildingOfficeIcon */
const TYPE_ICON_COMPONENTS = {
  apartment: BuildingOfficeIcon,
  house: HomeIcon,
  villa: HomeModernIcon,
  studio: BuildingOfficeIcon,
  appartement_meuble: BuildingOfficeIcon,
  studio_meuble: BuildingOfficeIcon,
  villa_meublee: HomeModernIcon,
  penthouse: HomeModernIcon,
  loft: HomeModernIcon,
  grenier: HomeIcon,
  hotel: BuildingOfficeIcon,
  hotel_passage: BuildingOfficeIcon,
  motel: BuildingOfficeIcon,
  boutique_hotel: BuildingOfficeIcon,
  hotel_luxe: HomeModernIcon,
  guest_house: HomeIcon,
  residence_hoteliere: BuildingOfficeIcon,
  bungalow: HomeIcon,
  lodge: HomeIcon,
  case_traditionnelle: HomeIcon,
  maison_flottante: HomeModernIcon,
  campement_touristique: HomeIcon,
  chambre_colocation: BuildingOfficeIcon,
  coliving: BuildingOfficeIcon,
  maison_hotes: HomeIcon,
  residence_universitaire: BuildingOfficeIcon,
  cite_dortoir: BuildingOfficeIcon,
  appartement_vide: BuildingOfficeIcon,
  villa_vide: HomeModernIcon,
  immeuble: BuildingOfficeIcon,
  cour_commune: HomeIcon,
  maison_hotes_economique: HomeIcon,
  residence_familiale: HomeIcon,
  chambres_passage: HomeIcon,
  room: HomeIcon,
  other: HomeIcon
};

const PropertyCard = ({ property, typeLabel, onValidate, onReject, onDelete, onVerify }) => {
  const statusColors = {
    available: 'bg-green-100 text-green-800',
    unavailable: 'bg-red-100 text-red-800',
    maintenance: 'bg-yellow-100 text-yellow-800'
  };

  const TypeIcon = TYPE_ICON_COMPONENTS[property.type] || BuildingOfficeIcon;

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden hover:shadow-lg transition-shadow duration-300"
    >
      <div className="relative aspect-[16/9] overflow-hidden">
        <img
          src={property.images?.[0] || '/placeholder-property.jpg'}
          alt={property.title}
          className="w-full h-full object-cover transform hover:scale-110 transition-transform duration-300"
        />
        <div className="absolute top-4 right-4">
          <span className={`px-3 py-1 rounded-full text-xs font-medium ${statusColors[property.status]}`}>
            {property.status === 'available' ? 'Disponible' : 
             property.status === 'unavailable' ? 'Non disponible' : 'En maintenance'}
          </span>
        </div>
      </div>

      <div className="p-6">
        <div className="flex items-start justify-between mb-4">
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1">
              {property.title}
            </h3>
            <div className="flex items-center text-gray-600 dark:text-gray-400">
              <MapPinIcon className="w-4 h-4 mr-1" />
              <span className="text-sm">{property.city}</span>
            </div>
          </div>
          <div className="flex items-center">
            <TypeIcon className="w-5 h-5" />
            <span className="ml-2 text-sm text-gray-600 dark:text-gray-400">
              {typeLabel ||
                (property.type
                  ? String(property.type).replace(/_/g, ' ')
                  : '—')}
            </span>
          </div>
        </div>

        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center space-x-4">
            <div className="flex items-center">
              <HomeIcon className="w-5 h-5 text-gray-400 mr-1" />
              <span className="text-sm text-gray-600 dark:text-gray-400">{property.bedrooms} ch.</span>
            </div>
            <div className="flex items-center">
              <BeakerIcon className="w-5 h-5 text-gray-400 mr-1" />
              <span className="text-sm text-gray-600 dark:text-gray-400">{property.bathrooms} sdb.</span>
            </div>
            <div className="flex items-center">
              <span className="text-sm text-gray-600 dark:text-gray-400">{property.area} m²</span>
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center">
            <BanknotesIcon className="w-5 h-5 text-primary mr-1" />
            <span className="text-xl font-bold text-primary">
              {new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF' }).format(property.price)}
            </span>
          </div>
          <div className="flex items-center space-x-2">
            {property.featured && (
              <span className="px-2 py-1 bg-yellow-100 text-yellow-800 text-xs rounded-full">
                ⭐ Mise en avant
              </span>
            )}
            {property.verified && (
              <span className="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full">
                ✓ Vérifiée
              </span>
            )}
          </div>
        </div>

        {/* Actions */}
        <div className="flex items-center justify-between space-x-2">
          <button className="flex-1 px-3 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-lg transition-colors duration-200 text-sm">
            Voir détails
          </button>
          
          <div className="flex space-x-1">
            {!property.verified && (
              <button 
                onClick={() => onVerify(property.id)}
                className="p-2 bg-blue-100 hover:bg-blue-200 text-blue-600 rounded-lg transition-colors duration-200"
                title="Vérifier la propriété"
              >
                <CheckIcon className="w-4 h-4" />
              </button>
            )}
            
            {property.status === 'pending' && (
              <>
                <button 
                  onClick={() => onValidate(property.id)}
                  className="p-2 bg-green-100 hover:bg-green-200 text-green-600 rounded-lg transition-colors duration-200"
                  title="Valider la propriété"
                >
                  <CheckCircleIcon className="w-4 h-4" />
                </button>
                <button 
                  onClick={() => onReject(property.id)}
                  className="p-2 bg-red-100 hover:bg-red-200 text-red-600 rounded-lg transition-colors duration-200"
                  title="Rejeter la propriété"
                >
                  <XCircleIcon className="w-4 h-4" />
                </button>
              </>
            )}
            
            <button 
              onClick={() => onDelete(property.id)}
              className="p-2 bg-red-100 hover:bg-red-200 text-red-600 rounded-lg transition-colors duration-200"
              title="Supprimer la propriété"
            >
              <TrashIcon className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </motion.div>
  );
};

const PropertySkeleton = () => (
  <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden">
    <div className="aspect-[16/9] bg-gray-200 dark:bg-gray-700 animate-pulse" />
    <div className="p-6">
      <div className="h-6 bg-gray-200 dark:bg-gray-700 rounded w-3/4 mb-4 animate-pulse" />
      <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/2 mb-4 animate-pulse" />
      <div className="flex space-x-4 mb-4">
        <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/4 animate-pulse" />
        <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/4 animate-pulse" />
        <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/4 animate-pulse" />
      </div>
      <div className="flex justify-between items-center">
        <div className="h-6 bg-gray-200 dark:bg-gray-700 rounded w-1/3 animate-pulse" />
        <div className="h-10 bg-gray-200 dark:bg-gray-700 rounded w-1/4 animate-pulse" />
      </div>
    </div>
  </div>
);

const Properties = () => {
  const [properties, setProperties] = useState([]);
  const [loading, setLoading] = useState(true);
  const [residenceTypeOptions, setResidenceTypeOptions] = useState([]);
  const [showFilters, setShowFilters] = useState(false);
  const [filters, setFilters] = useState({
    type: '',
    minPrice: '',
    maxPrice: '',
    minBedrooms: '',
    city: '',
    status: ''
  });
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 9,
    total: 0,
    pages: 0
  });
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    let cancelled = false;
    (async () => {
      const res = await adminService.getAllPropertyTypes();
      if (!cancelled && res.success && Array.isArray(res.data)) {
        setResidenceTypeOptions(res.data);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const typeLabelsByCode = useMemo(() => {
    const map = {};
    residenceTypeOptions.forEach((t) => {
      if (t.id) map[t.id] = t.name;
    });
    return map;
  }, [residenceTypeOptions]);

  const fetchProperties = useCallback(async () => {
    try {
      setLoading(true);
      const queryParams = {
        page: pagination.page,
        limit: pagination.limit,
        ...filters,
        search: searchTerm
      };

      const response = await adminService.getAllProperties(queryParams);

      if (response.success) {
        // Transformer les données backend pour correspondre à l'interface
        const transformedProperties = response.data.map(property => ({
          id: property._id || property.id,
          title: property.title,
          description: property.description,
          price: property.price,
          type: property.type || 'apartment',
          city: property.city,
          address: property.address,
          images: property.images || [],
          status: property.status || 'available',
          bedrooms: property.bedrooms || 0,
          bathrooms: property.bathrooms || 0,
          area: property.area || 0,
          amenities: property.amenities || [],
          partner: property.partner,
          createdAt: property.createdAt,
          // Champs additionnels pour l'interface
          stars: property.stars || 0,
          featured: property.featured || false,
          verified: property.verified || false
        }));
        
        setProperties(transformedProperties);
        setPagination(prev => ({
          ...prev,
          total: response.pagination?.total || transformedProperties.length,
          pages: response.pagination?.pages || Math.ceil(transformedProperties.length / pagination.limit)
        }));
      } else {
        throw new Error(response.error || 'Erreur lors du chargement des propriétés');
      }
    } catch (error) {
      console.error('Erreur lors du chargement des propriétés:', error);
      toast.error(error.message || 'Erreur lors du chargement des propriétés');
      // En cas d'erreur, utiliser des données de fallback
      setProperties([]);
    } finally {
      setLoading(false);
    }
  }, [pagination.page, pagination.limit, filters, searchTerm]);

  // Handlers CRUD pour les propriétés
  const handleValidateProperty = async (propertyId) => {
    try {
      const response = await adminService.validateProperty(propertyId);
      if (response.success) {
        toast.success('Propriété validée avec succès');
        fetchProperties(); // Recharger la liste
      } else {
        throw new Error(response.error || 'Erreur lors de la validation');
      }
    } catch (error) {
      toast.error(error.message || 'Erreur lors de la validation');
    }
  };

  const handleRejectProperty = async (propertyId, reason = '') => {
    try {
      const response = await adminService.rejectProperty(propertyId, reason);
      if (response.success) {
        toast.success('Propriété rejetée avec succès');
        fetchProperties(); // Recharger la liste
      } else {
        throw new Error(response.error || 'Erreur lors du rejet');
      }
    } catch (error) {
      toast.error(error.message || 'Erreur lors du rejet');
    }
  };

  const handleDeleteProperty = async (propertyId) => {
    if (!window.confirm('Êtes-vous sûr de vouloir supprimer cette propriété ?')) {
      return;
    }
    
    try {
      const response = await adminService.deleteProperty(propertyId);
      if (response.success) {
        toast.success('Propriété supprimée avec succès');
        fetchProperties(); // Recharger la liste
      } else {
        throw new Error(response.error || 'Erreur lors de la suppression');
      }
    } catch (error) {
      toast.error(error.message || 'Erreur lors de la suppression');
    }
  };

  const handleVerifyProperty = async (propertyId) => {
    try {
      const response = await adminService.verifyProperty(propertyId);
      if (response.success) {
        toast.success('Propriété vérifiée avec succès');
        fetchProperties(); // Recharger la liste
      } else {
        throw new Error(response.error || 'Erreur lors de la vérification');
      }
    } catch (error) {
      toast.error(error.message || 'Erreur lors de la vérification');
    }
  };

  useEffect(() => {
    fetchProperties();
  }, [fetchProperties]);

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setFilters(prev => ({
      ...prev,
      [name]: value
    }));
    setPagination(prev => ({ ...prev, page: 1 }));
  };

  const clearFilters = () => {
    setFilters({
      type: '',
      minPrice: '',
      maxPrice: '',
      minBedrooms: '',
      city: '',
      status: ''
    });
    setSearchTerm('');
    setPagination(prev => ({ ...prev, page: 1 }));
  };

  return (
    <div className="p-6">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 space-y-4 md:space-y-0">
        <div className="flex items-center">
          <HomeIcon className="w-8 h-8 text-primary mr-3" />
          <h1 className="text-2xl font-bold text-gray-800 dark:text-white">
            Propriétés
          </h1>
        </div>
        
        <div className="flex flex-col md:flex-row space-y-4 md:space-y-0 md:space-x-4 w-full md:w-auto">
          <div className="relative flex-1 md:flex-initial">
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Rechercher une propriété..."
              className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-primary focus:border-primary bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
            />
            <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
          </div>
          
          <button
            onClick={() => setShowFilters(!showFilters)}
            className="flex items-center px-4 py-2 bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-200 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors duration-200 shadow-sm"
          >
            <FunnelIcon className="w-5 h-5 mr-2" />
            Filtres
          </button>
        </div>
      </div>

      <AnimatePresence>
        {showFilters && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 mb-6"
          >
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-medium text-gray-900 dark:text-white">
                Filtres
              </h2>
              <button
                onClick={clearFilters}
                className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                <XMarkIcon className="w-5 h-5" />
              </button>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Type de propriété
                </label>
                <select
                  name="type"
                  value={filters.type}
                  onChange={handleFilterChange}
                  className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
                >
                  <option value="">Tous</option>
                  {residenceTypeOptions.map((t) => (
                    <option key={t.id} value={t.id}>
                      {t.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Prix minimum
                </label>
                <input
                  type="number"
                  name="minPrice"
                  value={filters.minPrice}
                  onChange={handleFilterChange}
                  placeholder="Prix min"
                  className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Prix maximum
                </label>
                <input
                  type="number"
                  name="maxPrice"
                  value={filters.maxPrice}
                  onChange={handleFilterChange}
                  placeholder="Prix max"
                  className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Chambres minimum
                </label>
                <input
                  type="number"
                  name="minBedrooms"
                  value={filters.minBedrooms}
                  onChange={handleFilterChange}
                  placeholder="Nombre min"
                  className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Ville
                </label>
                <input
                  type="text"
                  name="city"
                  value={filters.city}
                  onChange={handleFilterChange}
                  placeholder="Ville"
                  className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Statut
                </label>
                <select
                  name="status"
                  value={filters.status}
                  onChange={handleFilterChange}
                  className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
                >
                  <option value="">Tous</option>
                  <option value="available">Disponible</option>
                  <option value="unavailable">Non disponible</option>
                  <option value="maintenance">En maintenance</option>
                </select>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {loading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[...Array(6)].map((_, index) => (
            <PropertySkeleton key={index} />
          ))}
        </div>
      ) : properties.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-12">
          <HomeIcon className="w-16 h-16 text-gray-400 mb-4" />
          <h2 className="text-xl font-medium text-gray-900 dark:text-white mb-2">
            Aucune propriété trouvée
          </h2>
          <p className="text-gray-600 dark:text-gray-400">
            Essayez de modifier vos filtres de recherche
          </p>
        </div>
      ) : (
        <motion.div layout className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <AnimatePresence>
            {properties.map(property => (
              <PropertyCard 
                key={property._id || property.id}
                typeLabel={typeLabelsByCode[property.type]}
                property={property}
                onValidate={handleValidateProperty}
                onReject={handleRejectProperty}
                onDelete={handleDeleteProperty}
                onVerify={handleVerifyProperty}
              />
            ))}
          </AnimatePresence>
        </motion.div>
      )}

      {pagination.pages > 1 && (
        <div className="mt-6 flex items-center justify-between border-t border-gray-200 dark:border-gray-700 pt-6">
          <button
            onClick={() => setPagination(prev => ({ ...prev, page: Math.max(1, prev.page - 1) }))}
            disabled={pagination.page === 1}
            className="flex items-center px-4 py-2 text-sm font-medium text-gray-700 bg-white dark:bg-gray-800 dark:text-gray-300 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50"
          >
            <ChevronLeftIcon className="w-5 h-5 mr-2" />
            Précédent
          </button>
          
          <span className="text-sm text-gray-700 dark:text-gray-300">
            Page {pagination.page} sur {pagination.pages}
          </span>
          
          <button
            onClick={() => setPagination(prev => ({ ...prev, page: Math.min(pagination.pages, prev.page + 1) }))}
            disabled={pagination.page === pagination.pages}
            className="flex items-center px-4 py-2 text-sm font-medium text-gray-700 bg-white dark:bg-gray-800 dark:text-gray-300 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50"
          >
            Suivant
            <ChevronRightIcon className="w-5 h-5 ml-2" />
          </button>
        </div>
      )}
    </div>
  );
};

export default Properties;
