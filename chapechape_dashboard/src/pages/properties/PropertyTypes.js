import React, { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  BuildingOfficeIcon,
  HomeIcon,
  HomeModernIcon,
  PlusIcon,
  PencilSquareIcon,
  TrashIcon,
  XMarkIcon,
  AcademicCapIcon,
  BuildingLibraryIcon,
  BuildingStorefrontIcon,
  BriefcaseIcon
} from '@heroicons/react/24/outline';
import toast from 'react-hot-toast';
import { adminService } from '../../services/adminService';

const propertyTypes = [
  // Résidences Meublées
  {
    id: 'studio_meuble',
    name: 'Studio Meublé',
    icon: BuildingOfficeIcon,
    description: 'Studio entièrement meublé et équipé',
    features: ['Meublé', 'Compact', 'Tout équipé'],
    color: 'blue'
  },
  {
    id: 'appartement_meuble',
    name: 'Appartement Meublé',
    icon: BuildingOfficeIcon,
    description: 'Appartement complet avec mobilier',
    features: ['Meublé', 'Plusieurs pièces', 'Confort'],
    color: 'blue'
  },
  {
    id: 'villa_meublee',
    name: 'Villa Meublée',
    icon: HomeModernIcon,
    description: 'Villa indépendante meublée',
    features: ['Jardin', 'Espace', 'Standing'],
    color: 'purple'
  },
  {
    id: 'penthouse',
    name: 'Penthouse',
    icon: BuildingLibraryIcon,
    description: 'Appartement de luxe au dernier étage',
    features: ['Vue panoramique', 'Luxe', 'Terrasse'],
    color: 'indigo'
  },
  {
    id: 'loft',
    name: 'Loft',
    icon: HomeModernIcon,
    description: 'Espace ouvert style industriel',
    features: ['Grand volume', 'Moderne', 'Atypique'],
    color: 'cyan'
  },
  {
    id: 'grenier',
    name: 'Grenier Aménagé',
    icon: HomeIcon,
    description: 'Espace sous les toits aménagé',
    features: ['Cosy', 'Atypique', 'Calme'],
    color: 'orange'
  },

  // Hôtels & Hébergements classiques
  {
    id: 'hotel_passage',
    name: 'Hôtel de Passage',
    icon: BuildingStorefrontIcon,
    description: 'Hôtel pour courts séjours',
    features: ['Court séjour', 'Service', 'Discrétion'],
    color: 'red'
  },
  {
    id: 'motel',
    name: 'Motel',
    icon: BuildingStorefrontIcon,
    description: 'Hébergement étape sur route',
    features: ['Parking', 'Accès facile', 'Étape'],
    color: 'red'
  },
  {
    id: 'boutique_hotel',
    name: 'Boutique-Hôtel',
    icon: BuildingStorefrontIcon,
    description: 'Petit hôtel de charme',
    features: ['Charme', 'Design', 'Service personnalisé'],
    color: 'pink'
  },
  {
    id: 'hotel_luxe',
    name: 'Hôtel de Luxe',
    icon: BuildingLibraryIcon,
    description: 'Hôtel haut de gamme 5 étoiles',
    features: ['Prestige', 'Service complet', 'Excellence'],
    color: 'pink'
  },
  {
    id: 'guest_house',
    name: 'Guest House',
    icon: HomeIcon,
    description: 'Maison d\'hôtes conviviale',
    features: ['Convivial', 'Petit déjeuner', 'Accueil'],
    color: 'green'
  },
  {
    id: 'residence_hoteliere',
    name: 'Résidence Hôtelière',
    icon: BuildingOfficeIcon,
    description: 'Appartements avec services hôteliers',
    features: ['Services', 'Indépendance', 'Long séjour'],
    color: 'blue'
  },

  // Hébergements insolites & nature
  {
    id: 'bungalow',
    name: 'Bungalow',
    icon: HomeIcon,
    description: 'Petite maison légère de plain-pied',
    features: ['Nature', 'Indépendant', 'Vacances'],
    color: 'green'
  },
  {
    id: 'lodge',
    name: 'Lodge & Écolodge',
    icon: HomeModernIcon,
    description: 'Hébergement en pleine nature',
    features: ['Nature', 'Écologique', 'Dépaysement'],
    color: 'green'
  },
  {
    id: 'case_traditionnelle',
    name: 'Case Traditionnelle',
    icon: HomeIcon,
    description: 'Habitat traditionnel local',
    features: ['Authentique', 'Culturel', 'Simple'],
    color: 'orange'
  },
  {
    id: 'maison_flottante',
    name: 'Maison Flottante',
    icon: HomeModernIcon,
    description: 'Habitation sur l\'eau',
    features: ['Eau', 'Insolite', 'Vue'],
    color: 'cyan'
  },
  {
    id: 'campement_touristique',
    name: 'Campement Touristique',
    icon: HomeIcon,
    description: 'Structure légère pour tourisme',
    features: ['Aventure', 'Nature', 'Groupe'],
    color: 'yellow'
  },

  // Colocation & résidences partagées
  {
    id: 'chambre_colocation',
    name: 'Chambre en Colocation',
    icon: HomeIcon,
    description: 'Chambre dans un logement partagé',
    features: ['Partage', 'Économique', 'Social'],
    color: 'yellow'
  },
  {
    id: 'coliving',
    name: 'Coliving',
    icon: BuildingOfficeIcon,
    description: 'Espace de vie et travail partagé',
    features: ['Communauté', 'Services', 'Flexibilité'],
    color: 'indigo'
  },
  {
    id: 'maison_hotes',
    name: 'Maison d\'Hôtes',
    icon: HomeIcon,
    description: 'Chambre chez l\'habitant',
    features: ['Accueil', 'Local', 'Convivial'],
    color: 'green'
  },
  {
    id: 'residence_universitaire',
    name: 'Résidence Universitaire',
    icon: AcademicCapIcon,
    description: 'Logement pour étudiants',
    features: ['Étudiant', 'Campus', 'Services'],
    color: 'teal'
  },
  {
    id: 'cite_dortoir',
    name: 'Cité & Dortoir',
    icon: BuildingOfficeIcon,
    description: 'Hébergement collectif économique',
    features: ['Collectif', 'Économique', 'Basique'],
    color: 'gray'
  },

  // Résidences longue durée
  {
    id: 'appartement_vide',
    name: 'Appartement Non Meublé',
    icon: BuildingOfficeIcon,
    description: 'Appartement vide à louer',
    features: ['Vide', 'Longue durée', 'Liberté'],
    color: 'blue'
  },
  {
    id: 'villa_vide',
    name: 'Villa Non Meublée',
    icon: HomeModernIcon,
    description: 'Villa vide à louer',
    features: ['Vide', 'Espace', 'Famille'],
    color: 'purple'
  },
  {
    id: 'immeuble',
    name: 'Immeuble',
    icon: BuildingOfficeIcon,
    description: 'Bâtiment entier',
    features: ['Investissement', 'Grand', 'Multiple'],
    color: 'gray'
  },
  {
    id: 'cour_commune',
    name: 'Cour Commune',
    icon: HomeIcon,
    description: 'Habitation en cour commune',
    features: ['Populaire', 'Convivial', 'Économique'],
    color: 'orange'
  },

  // Hébergements économiques
  {
    id: 'maison_hotes_economique',
    name: 'Maison d\'Hôtes Éco',
    icon: HomeIcon,
    description: 'Maison d\'hôtes à petit prix',
    features: ['Économique', 'Simple', 'Accueil'],
    color: 'green'
  },
  {
    id: 'residence_familiale',
    name: 'Résidence Familiale',
    icon: HomeIcon,
    description: 'Logement pour famille',
    features: ['Famille', 'Espace', 'Calme'],
    color: 'blue'
  },
  {
    id: 'chambres_passage',
    name: 'Chambres de Passage',
    icon: HomeIcon,
    description: 'Chambre pour courte durée',
    features: ['Court séjour', 'Simple', 'Pratique'],
    color: 'red'
  }
];

const PropertyTypeCard = ({ type, onEdit, onDelete }) => {
  const Icon = type.icon;
  const colors = {
    blue: 'bg-blue-50 text-blue-700 border-blue-200 dark:bg-blue-900/50 dark:text-blue-300 dark:border-blue-800',
    green: 'bg-green-50 text-green-700 border-green-200 dark:bg-green-900/50 dark:text-green-300 dark:border-green-800',
    purple: 'bg-purple-50 text-purple-700 border-purple-200 dark:bg-purple-900/50 dark:text-purple-300 dark:border-purple-800',
    orange: 'bg-orange-50 text-orange-700 border-orange-200 dark:bg-orange-900/50 dark:text-orange-300 dark:border-orange-800',
    yellow: 'bg-yellow-50 text-yellow-700 border-yellow-200 dark:bg-yellow-900/50 dark:text-yellow-300 dark:border-yellow-800',
    indigo: 'bg-indigo-50 text-indigo-700 border-indigo-200 dark:bg-indigo-900/50 dark:text-indigo-300 dark:border-indigo-800',
    red: 'bg-red-50 text-red-700 border-red-200 dark:bg-red-900/50 dark:text-red-300 dark:border-red-800',
    pink: 'bg-pink-50 text-pink-700 border-pink-200 dark:bg-pink-900/50 dark:text-pink-300 dark:border-pink-800',
    cyan: 'bg-cyan-50 text-cyan-700 border-cyan-200 dark:bg-cyan-900/50 dark:text-cyan-300 dark:border-cyan-800',
    teal: 'bg-teal-50 text-teal-700 border-teal-200 dark:bg-teal-900/50 dark:text-teal-300 dark:border-teal-800'
  };

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className={`p-6 rounded-xl border ${colors[type.color]} transition-all duration-300`}
    >
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center">
          <div className={`p-3 rounded-lg ${colors[type.color]} bg-opacity-20`}>
            <Icon className="w-6 h-6" />
          </div>
          <h3 className="ml-3 text-lg font-semibold">{type.name}</h3>
        </div>
        <div className="flex space-x-2">
          <button
            onClick={() => onEdit(type)}
            className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors duration-200"
          >
            <PencilSquareIcon className="w-5 h-5" />
          </button>
          <button
            onClick={() => onDelete(type)}
            className="p-2 rounded-lg hover:bg-red-100 dark:hover:bg-red-900/50 transition-colors duration-200 text-red-600 dark:text-red-400"
          >
            <TrashIcon className="w-5 h-5" />
          </button>
        </div>
      </div>

      <p className="text-gray-600 dark:text-gray-400 mb-4">
        {type.description}
      </p>

      <div className="flex flex-wrap gap-2">
        {type.features.map((feature, index) => (
          <span
            key={index}
            className={`px-3 py-1 rounded-full text-sm ${colors[type.color]} bg-opacity-10`}
          >
            {feature}
          </span>
        ))}
      </div>
    </motion.div>
  );
};

const PropertyTypeModal = ({ isOpen, onClose, type, onSave }) => {
  const [formData, setFormData] = useState(
    type || {
      id: '',
      name: '',
      description: '',
      features: [''],
      color: 'blue'
    }
  );

  const handleSubmit = (e) => {
    e.preventDefault();
    onSave(formData);
    onClose();
  };

  const addFeature = () => {
    setFormData(prev => ({
      ...prev,
      features: [...prev.features, '']
    }));
  };

  const removeFeature = (index) => {
    setFormData(prev => ({
      ...prev,
      features: prev.features.filter((_, i) => i !== index)
    }));
  };

  const updateFeature = (index, value) => {
    setFormData(prev => ({
      ...prev,
      features: prev.features.map((f, i) => i === index ? value : f)
    }));
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
        className="bg-white dark:bg-gray-800 rounded-xl shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto"
      >
        <div className="flex justify-between items-center p-6 border-b border-gray-200 dark:border-gray-700">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
            {type ? 'Modifier le type' : 'Nouveau type'}
          </h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
          >
            <XMarkIcon className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6">
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Identifiant
              </label>
              <input
                type="text"
                value={formData.id}
                onChange={(e) => setFormData(prev => ({ ...prev, id: e.target.value }))}
                className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Nom
              </label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Description
              </label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                rows={3}
                className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Couleur
              </label>
              <select
                value={formData.color}
                onChange={(e) => setFormData(prev => ({ ...prev, color: e.target.value }))}
                className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
              >
                <option value="blue">Bleu</option>
                <option value="green">Vert</option>
                <option value="purple">Violet</option>
                <option value="orange">Orange</option>
                <option value="yellow">Jaune</option>
                <option value="indigo">Indigo</option>
                <option value="red">Rouge</option>
                <option value="pink">Rose</option>
                <option value="cyan">Cyan</option>
                <option value="teal">Teal</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Caractéristiques
              </label>
              <div className="space-y-2">
                {formData.features.map((feature, index) => (
                  <div key={index} className="flex gap-2">
                    <input
                      type="text"
                      value={feature}
                      onChange={(e) => updateFeature(index, e.target.value)}
                      className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
                      placeholder="Caractéristique"
                      required
                    />
                    <button
                      type="button"
                      onClick={() => removeFeature(index)}
                      className="p-2 text-red-600 hover:bg-red-100 rounded-lg dark:text-red-400 dark:hover:bg-red-900/50"
                    >
                      <XMarkIcon className="w-5 h-5" />
                    </button>
                  </div>
                ))}
                <button
                  type="button"
                  onClick={addFeature}
                  className="flex items-center text-primary hover:text-primary-dark"
                >
                  <PlusIcon className="w-5 h-5 mr-1" />
                  Ajouter une caractéristique
                </button>
              </div>
            </div>
          </div>

          <div className="mt-6 flex justify-end space-x-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
            >
              Annuler
            </button>
            <button
              type="submit"
              className="px-4 py-2 bg-primary text-white rounded-md hover:bg-primary-dark"
            >
              {type ? 'Mettre à jour' : 'Créer'}
            </button>
          </div>
        </form>
      </motion.div>
    </div>
  );
};

const PropertyTypes = () => {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedType, setSelectedType] = useState(null);
  const [types, setTypes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Charger les types de propriétés depuis l'API
  const fetchPropertyTypes = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await adminService.getAllPropertyTypes();

      if (response.success) {
        // Transformer les données backend pour correspondre à l'interface
        const transformedTypes = response.data.map(type => ({
          id: type._id || type.id,
          name: type.name,
          icon: type.icon || BuildingOfficeIcon, // Fallback icon
          description: type.description,
          features: type.features || [],
          color: type.color || 'blue'
        }));
        setTypes(transformedTypes);
      } else {
        // En cas d'erreur API, utiliser les données de fallback
        setTypes(propertyTypes);
        setError('Impossible de charger les types de propriétés depuis le serveur. Utilisation des données locales.');
      }
    } catch (error) {
      console.error('Erreur lors du chargement des types de propriétés:', error);
      setTypes(propertyTypes); // Fallback vers les données mockées
      setError('Erreur lors du chargement des types de propriétés.');
    } finally {
      setLoading(false);
    }
  }, []);

  // Charger les données au démarrage du composant
  useEffect(() => {
    fetchPropertyTypes();
  }, [fetchPropertyTypes]);

  const handleEdit = (type) => {
    setSelectedType(type);
    setIsModalOpen(true);
  };

  const handleDelete = async (type) => {
    if (!window.confirm(`Êtes-vous sûr de vouloir supprimer le type "${type.name}" ?`)) {
      return;
    }

    try {
      const response = await adminService.deletePropertyType(type.id);
      if (response.success) {
        setTypes(prev => prev.filter(t => t.id !== type.id));
        toast.success('Type de propriété supprimé avec succès');
      } else {
        throw new Error(response.error || 'Erreur lors de la suppression');
      }
    } catch (error) {
      console.error('Erreur lors de la suppression:', error);
      toast.error(error.message || 'Erreur lors de la suppression du type de propriété');
    }
  };

  const handleSave = async (formData) => {
    try {
      let response;
      if (selectedType) {
        // Mise à jour
        response = await adminService.updatePropertyType(selectedType.id, formData);
        if (response.success) {
          setTypes(prev => prev.map(t => t.id === selectedType.id ? { ...formData, id: selectedType.id } : t));
          toast.success('Type de propriété mis à jour avec succès');
        } else {
          throw new Error(response.error || 'Erreur lors de la mise à jour');
        }
      } else {
        // Création
        response = await adminService.createPropertyType(formData);
        if (response.success) {
          const newType = { ...formData, id: response.data._id || response.data.id };
          setTypes(prev => [...prev, newType]);
          toast.success('Type de propriété créé avec succès');
        } else {
          throw new Error(response.error || 'Erreur lors de la création');
        }
      }
    } catch (error) {
      console.error('Erreur lors de la sauvegarde:', error);
      toast.error(error.message || 'Erreur lors de la sauvegarde du type de propriété');
    }
  };

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center">
          <BuildingOfficeIcon className="w-8 h-8 text-primary mr-3" />
          <h1 className="text-2xl font-bold text-gray-800 dark:text-white">
            Types de propriété
          </h1>
        </div>
        <button
          onClick={() => {
            setSelectedType(null);
            setIsModalOpen(true);
          }}
          className="flex items-center px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark transition-colors duration-200"
        >
          <PlusIcon className="w-5 h-5 mr-2" />
          Nouveau type
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <AnimatePresence>
          {types.map(type => (
            <PropertyTypeCard
              key={type.id}
              type={type}
              onEdit={handleEdit}
              onDelete={handleDelete}
            />
          ))}
        </AnimatePresence>
      </div>

      <AnimatePresence>
        {isModalOpen && (
          <PropertyTypeModal
            isOpen={isModalOpen}
            onClose={() => {
              setIsModalOpen(false);
              setSelectedType(null);
            }}
            type={selectedType}
            onSave={handleSave}
          />
        )}
      </AnimatePresence>
    </div>
  );
};

export default PropertyTypes;
