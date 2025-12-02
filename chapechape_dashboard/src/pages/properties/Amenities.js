import React, { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  WifiIcon,
  SunIcon,
  Square2StackIcon,
  HomeModernIcon,
  ShieldCheckIcon,
  BuildingOfficeIcon,
  PlusIcon,
  PencilSquareIcon,
  TrashIcon,
  XMarkIcon,
  SwatchIcon,
  WindowIcon,
  HomeIcon,
  BeakerIcon,
  BuildingStorefrontIcon
} from '@heroicons/react/24/outline';
import toast from 'react-hot-toast';
import { adminService } from '../../services/adminService';

const amenities = [
  // Connectivité & Multimédia
  {
    id: 'wifi',
    name: 'Wi-Fi',
    icon: WifiIcon,
    description: 'Internet sans fil',
    features: ['Haut débit', 'Gratuit'],
    color: 'blue'
  },
  {
    id: 'fiber_optic',
    name: 'Fibre Optique',
    icon: WifiIcon,
    description: 'Connexion internet très haut débit',
    features: ['Très haut débit', 'Stable'],
    color: 'blue'
  },
  {
    id: 'ethernet',
    name: 'Ethernet',
    icon: WifiIcon,
    description: 'Prise réseau filaire',
    features: ['Connexion filaire', 'Stable'],
    color: 'blue'
  },
  {
    id: 'tv',
    name: 'Télévision',
    icon: WindowIcon,
    description: 'Téléviseur disponible',
    features: ['Chaînes câblées', 'Smart TV'],
    color: 'gray'
  },

  // Confort & Climatisation
  {
    id: 'air_conditioning',
    name: 'Climatisation',
    icon: SunIcon,
    description: 'Air conditionné',
    features: ['Réglable', 'Toutes pièces'],
    color: 'cyan'
  },
  {
    id: 'fan',
    name: 'Ventilateur',
    icon: SunIcon,
    description: 'Ventilateur sur pied ou mural',
    features: ['Ventilation', 'Mobile'],
    color: 'cyan'
  },
  {
    id: 'ceiling_fan',
    name: 'Ventilateur Plafond',
    icon: SunIcon,
    description: 'Ventilateur de plafond',
    features: ['Silencieux', 'Efficace'],
    color: 'cyan'
  },
  {
    id: 'hot_water',
    name: 'Eau Chaude',
    icon: BeakerIcon,
    description: 'Eau chaude disponible',
    features: ['Douche', 'Cuisine'],
    color: 'red'
  },

  // Cuisine & Électroménager
  {
    id: 'kitchen',
    name: 'Cuisine',
    icon: HomeModernIcon,
    description: 'Espace cuisine disponible',
    features: ['Évier', 'Plan de travail'],
    color: 'orange'
  },
  {
    id: 'full_kitchen',
    name: 'Cuisine Équipée',
    icon: HomeModernIcon,
    description: 'Cuisine entièrement équipée',
    features: ['Four', 'Plaques', 'Frigo'],
    color: 'orange'
  },
  {
    id: 'kitchenette',
    name: 'Kitchenette',
    icon: HomeModernIcon,
    description: 'Petite cuisine d\'appoint',
    features: ['Compact', 'Basique'],
    color: 'orange'
  },
  {
    id: 'shared_kitchen',
    name: 'Cuisine Partagée',
    icon: HomeModernIcon,
    description: 'Cuisine commune',
    features: ['Partage', 'Équipé'],
    color: 'orange'
  },
  {
    id: 'refrigerator',
    name: 'Réfrigérateur',
    icon: HomeModernIcon,
    description: 'Réfrigérateur disponible',
    features: ['Froid', 'Conservation'],
    color: 'gray'
  },
  {
    id: 'microwave',
    name: 'Micro-ondes',
    icon: HomeModernIcon,
    description: 'Four micro-ondes',
    features: ['Réchauffage', 'Rapide'],
    color: 'gray'
  },
  {
    id: 'oven',
    name: 'Four',
    icon: HomeModernIcon,
    description: 'Four traditionnel',
    features: ['Cuisson', 'Pâtisserie'],
    color: 'gray'
  },

  // Extérieur & Détente
  {
    id: 'pool',
    name: 'Piscine',
    icon: HomeModernIcon,
    description: 'Accès piscine',
    features: ['Baignade', 'Détente'],
    color: 'blue'
  },
  {
    id: 'garden',
    name: 'Jardin',
    icon: SwatchIcon,
    description: 'Espace vert',
    features: ['Verdure', 'Calme'],
    color: 'green'
  },
  {
    id: 'terrace',
    name: 'Terrasse',
    icon: WindowIcon,
    description: 'Terrasse aménagée',
    features: ['Extérieur', 'Repas'],
    color: 'yellow'
  },
  {
    id: 'balcony',
    name: 'Balcon',
    icon: WindowIcon,
    description: 'Balcon privé',
    features: ['Vue', 'Air frais'],
    color: 'yellow'
  },
  {
    id: 'gym',
    name: 'Salle de Sport',
    icon: HomeModernIcon,
    description: 'Espace fitness',
    features: ['Musculation', 'Cardio'],
    color: 'red'
  },
  {
    id: 'spa',
    name: 'Spa / Bien-être',
    icon: HomeModernIcon,
    description: 'Espace détente et soins',
    features: ['Massage', 'Sauna'],
    color: 'purple'
  },

  // Services & Commodités
  {
    id: 'parking',
    name: 'Parking',
    icon: Square2StackIcon,
    description: 'Place de stationnement',
    features: ['Sécurisé', 'Privé'],
    color: 'gray'
  },
  {
    id: 'elevator',
    name: 'Ascenseur',
    icon: BuildingOfficeIcon,
    description: 'Accès étages',
    features: ['Pratique', 'Accessible'],
    color: 'gray'
  },
  {
    id: 'cleaning',
    name: 'Ménage',
    icon: HomeIcon,
    description: 'Service de ménage inclus',
    features: ['Propreté', 'Régulier'],
    color: 'green'
  },
  {
    id: 'laundry',
    name: 'Laverie / Pressing',
    icon: HomeIcon,
    description: 'Service de linge',
    features: ['Lavage', 'Repassage'],
    color: 'blue'
  },
  {
    id: 'restaurant',
    name: 'Restaurant',
    icon: BuildingStorefrontIcon,
    description: 'Restauration sur place',
    features: ['Repas', 'Carte'],
    color: 'red'
  },
  {
    id: 'bar',
    name: 'Bar',
    icon: BuildingStorefrontIcon,
    description: 'Bar sur place',
    features: ['Boissons', 'Détente'],
    color: 'purple'
  },
  {
    id: 'room_service',
    name: 'Room Service',
    icon: HomeIcon,
    description: 'Service en chambre',
    features: ['Repas', 'Confort'],
    color: 'pink'
  },
  {
    id: 'meeting_room',
    name: 'Salle de Réunion',
    icon: BuildingOfficeIcon,
    description: 'Espace de travail pro',
    features: ['Professionnel', 'Équipé'],
    color: 'gray'
  },

  // Sécurité & Infrastructures
  {
    id: 'security',
    name: 'Sécurité 24/7',
    icon: ShieldCheckIcon,
    description: 'Dispositif de sécurité',
    features: ['Gardien', 'Surveillance'],
    color: 'green'
  },
  {
    id: 'security_guard',
    name: 'Gardien',
    icon: ShieldCheckIcon,
    description: 'Agent de sécurité sur place',
    features: ['Présence', 'Contrôle'],
    color: 'green'
  },
  {
    id: 'cctv',
    name: 'Vidéosurveillance',
    icon: ShieldCheckIcon,
    description: 'Caméras de sécurité',
    features: ['Enregistrement', 'Dissuasion'],
    color: 'green'
  },
  {
    id: 'alarm_system',
    name: 'Alarme',
    icon: ShieldCheckIcon,
    description: 'Système d\'alarme',
    features: ['Protection', 'Alerte'],
    color: 'red'
  },
  {
    id: 'generator',
    name: 'Groupe Électrogène',
    icon: SunIcon,
    description: 'Alimentation de secours',
    features: ['Autonomie', 'Continuité'],
    color: 'yellow'
  },
  {
    id: 'solar_energy',
    name: 'Énergie Solaire',
    icon: SunIcon,
    description: 'Panneaux solaires',
    features: ['Écologique', 'Économie'],
    color: 'yellow'
  },
  {
    id: 'inverter',
    name: 'Onduleur',
    icon: SunIcon,
    description: 'Système de secours électrique',
    features: ['Batterie', 'Relais'],
    color: 'yellow'
  },
  {
    id: 'electricity',
    name: 'Électricité',
    icon: SunIcon,
    description: 'Raccordement électrique',
    features: ['Stable', 'Compteur'],
    color: 'yellow'
  },
  {
    id: 'water_tank',
    name: 'Réservoir d\'Eau',
    icon: BeakerIcon,
    description: 'Réserve d\'eau autonome',
    features: ['Autonomie', 'Secours'],
    color: 'blue'
  },
  {
    id: 'running_water',
    name: 'Eau Courante',
    icon: BeakerIcon,
    description: 'Raccordement eau de ville',
    features: ['SODECI', 'Pression'],
    color: 'blue'
  }
];

const AmenityCard = ({ amenity, onEdit, onDelete }) => {
  const Icon = amenity.icon;
  const colors = {
    blue: 'bg-blue-50 text-blue-700 border-blue-200 dark:bg-blue-900/50 dark:text-blue-300 dark:border-blue-800',
    cyan: 'bg-cyan-50 text-cyan-700 border-cyan-200 dark:bg-cyan-900/50 dark:text-cyan-300 dark:border-cyan-800',
    gray: 'bg-gray-50 text-gray-700 border-gray-200 dark:bg-gray-900/50 dark:text-gray-300 dark:border-gray-800',
    green: 'bg-green-50 text-green-700 border-green-200 dark:bg-green-900/50 dark:text-green-300 dark:border-green-800',
    red: 'bg-red-50 text-red-700 border-red-200 dark:bg-red-900/50 dark:text-red-300 dark:border-red-800',
    purple: 'bg-purple-50 text-purple-700 border-purple-200 dark:bg-purple-900/50 dark:text-purple-300 dark:border-purple-800',
    yellow: 'bg-yellow-50 text-yellow-700 border-yellow-200 dark:bg-yellow-900/50 dark:text-yellow-300 dark:border-yellow-800',
    orange: 'bg-orange-50 text-orange-700 border-orange-200 dark:bg-orange-900/50 dark:text-orange-300 dark:border-orange-800'
  };

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className={`p-6 rounded-xl border ${colors[amenity.color]} transition-all duration-300 hover:shadow-lg`}
    >
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center">
          <div className={`p-3 rounded-lg ${colors[amenity.color]} bg-opacity-20`}>
            <Icon className="w-6 h-6" />
          </div>
          <h3 className="ml-3 text-lg font-semibold">{amenity.name}</h3>
        </div>
        <div className="flex space-x-2">
          <button
            onClick={() => onEdit(amenity)}
            className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors duration-200"
            title="Modifier"
          >
            <PencilSquareIcon className="w-5 h-5" />
          </button>
          <button
            onClick={() => onDelete(amenity)}
            className="p-2 rounded-lg hover:bg-red-100 dark:hover:bg-red-900/50 transition-colors duration-200 text-red-600 dark:text-red-400"
            title="Supprimer"
          >
            <TrashIcon className="w-5 h-5" />
          </button>
        </div>
      </div>

      <p className="text-gray-600 dark:text-gray-400 mb-4">
        {amenity.description}
      </p>

      <div className="flex flex-wrap gap-2">
        {amenity.features.map((feature, index) => (
          <span
            key={index}
            className={`px-3 py-1 rounded-full text-sm ${colors[amenity.color]} bg-opacity-10`}
          >
            {feature}
          </span>
        ))}
      </div>
    </motion.div>
  );
};

const AmenityModal = ({ isOpen, onClose, amenity, onSave }) => {
  const [formData, setFormData] = useState(
    amenity || {
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
            {amenity ? 'Modifier l\'équipement' : 'Nouvel équipement'}
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
                <option value="cyan">Cyan</option>
                <option value="gray">Gris</option>
                <option value="green">Vert</option>
                <option value="red">Rouge</option>
                <option value="purple">Violet</option>
                <option value="yellow">Jaune</option>
                <option value="orange">Orange</option>
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
              {amenity ? 'Mettre à jour' : 'Créer'}
            </button>
          </div>
        </form>
      </motion.div>
    </div>
  );
};

const Amenities = () => {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedAmenity, setSelectedAmenity] = useState(null);
  const [amenitiesList, setAmenitiesList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Charger les amenities depuis l'API
  const fetchAmenities = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await adminService.getAllAmenities();

      if (response.success) {
        // Transformer les données backend pour correspondre à l'interface
        const transformedAmenities = response.data.map(amenity => ({
          id: amenity._id || amenity.id,
          name: amenity.name,
          icon: amenity.icon || WifiIcon, // Fallback icon
          description: amenity.description,
          features: amenity.features || [],
          color: amenity.color || 'blue'
        }));
        setAmenitiesList(transformedAmenities);
      } else {
        // En cas d'erreur API, utiliser les données de fallback
        setAmenitiesList(amenities);
        setError('Impossible de charger les amenities depuis le serveur. Utilisation des données locales.');
      }
    } catch (error) {
      console.error('Erreur lors du chargement des amenities:', error);
      setAmenitiesList(amenities); // Fallback vers les données mockées
      setError('Erreur lors du chargement des amenities.');
    } finally {
      setLoading(false);
    }
  }, []);

  // Charger les données au démarrage du composant
  useEffect(() => {
    fetchAmenities();
  }, [fetchAmenities]);

  const handleEdit = (amenity) => {
    setSelectedAmenity(amenity);
    setIsModalOpen(true);
  };

  const handleDelete = async (amenity) => {
    if (!window.confirm(`Êtes-vous sûr de vouloir supprimer l'équipement "${amenity.name}" ?`)) {
      return;
    }

    try {
      const response = await adminService.deleteAmenity(amenity.id);
      if (response.success) {
        setAmenitiesList(prev => prev.filter(a => a.id !== amenity.id));
        toast.success('Équipement supprimé avec succès');
      } else {
        throw new Error(response.error || 'Erreur lors de la suppression');
      }
    } catch (error) {
      console.error('Erreur lors de la suppression:', error);
      toast.error(error.message || 'Erreur lors de la suppression de l\'équipement');
    }
  };

  const handleSave = async (formData) => {
    try {
      let response;
      if (selectedAmenity) {
        // Mise à jour
        response = await adminService.updateAmenity(selectedAmenity.id, formData);
        if (response.success) {
          setAmenitiesList(prev => prev.map(a => a.id === selectedAmenity.id ? { ...formData, id: selectedAmenity.id } : a));
          toast.success('Équipement mis à jour avec succès');
        } else {
          throw new Error(response.error || 'Erreur lors de la mise à jour');
        }
      } else {
        // Création
        response = await adminService.createAmenity(formData);
        if (response.success) {
          const newAmenity = { ...formData, id: response.data._id || response.data.id };
          setAmenitiesList(prev => [...prev, newAmenity]);
          toast.success('Équipement créé avec succès');
        } else {
          throw new Error(response.error || 'Erreur lors de la création');
        }
      }
    } catch (error) {
      console.error('Erreur lors de la sauvegarde:', error);
      toast.error(error.message || 'Erreur lors de la sauvegarde de l\'équipement');
    }
  };

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center">
          <HomeModernIcon className="w-8 h-8 text-primary mr-3" />
          <h1 className="text-2xl font-bold text-gray-800 dark:text-white">
            Équipements
          </h1>
        </div>
        <button
          onClick={() => {
            setSelectedAmenity(null);
            setIsModalOpen(true);
          }}
          className="flex items-center px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark transition-colors duration-200"
        >
          <PlusIcon className="w-5 h-5 mr-2" />
          Nouvel équipement
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <AnimatePresence>
          {amenitiesList.map(amenity => (
            <AmenityCard
              key={amenity.id}
              amenity={amenity}
              onEdit={handleEdit}
              onDelete={handleDelete}
            />
          ))}
        </AnimatePresence>
      </div>

      <AnimatePresence>
        {isModalOpen && (
          <AmenityModal
            isOpen={isModalOpen}
            onClose={() => {
              setIsModalOpen(false);
              setSelectedAmenity(null);
            }}
            amenity={selectedAmenity}
            onSave={handleSave}
          />
        )}
      </AnimatePresence>
    </div>
  );
};

export default Amenities;
