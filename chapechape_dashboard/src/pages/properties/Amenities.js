import React, { useState } from 'react';
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
  HomeIcon
} from '@heroicons/react/24/outline';
import toast from 'react-hot-toast';

const amenities = [
  {
    id: 'wifi',
    name: 'Wi-Fi',
    icon: WifiIcon,
    description: 'Internet haut débit gratuit',
    features: ['Haut débit', 'Gratuit', 'Couverture complète'],
    color: 'blue'
  },
  {
    id: 'ac',
    name: 'Climatisation',
    icon: SunIcon,
    description: 'Climatisation dans toutes les pièces',
    features: ['Toutes les pièces', 'Contrôle individuel', 'Économie d\'énergie'],
    color: 'cyan'
  },
  {
    id: 'parking',
    name: 'Parking',
    icon: Square2StackIcon,
    description: 'Parking sécurisé disponible',
    features: ['Sécurisé', 'Disponible', 'Facile d\'accès'],
    color: 'gray'
  },
  {
    id: 'pool',
    name: 'Piscine',
    icon: HomeModernIcon,
    description: 'Piscine privée ou commune',
    features: ['Entretenue', 'Sécurisée', 'Accessible'],
    color: 'blue'
  },
  {
    id: 'gym',
    name: 'Salle de sport',
    icon: HomeModernIcon,
    description: 'Équipements de fitness modernes',
    features: ['Équipement moderne', 'Accessible', 'Entretenu'],
    color: 'red'
  },
  {
    id: 'security',
    name: 'Sécurité 24/7',
    icon: ShieldCheckIcon,
    description: 'Gardiennage et vidéosurveillance',
    features: ['24/7', 'Gardiennage', 'Vidéosurveillance'],
    color: 'green'
  },
  {
    id: 'elevator',
    name: 'Ascenseur',
    icon: BuildingOfficeIcon,
    description: 'Accès facile aux étages supérieurs',
    features: ['Moderne', 'Sécurisé', 'Accessible PMR'],
    color: 'purple'
  },
  {
    id: 'garden',
    name: 'Jardin',
    icon: SwatchIcon,
    description: 'Zone verte aménagée',
    features: ['Aménagé', 'Entretenu', 'Espace détente'],
    color: 'green'
  },
  {
    id: 'balcony',
    name: 'Balcon/Terrasse',
    icon: WindowIcon,
    description: 'Vue extérieure privée',
    features: ['Privé', 'Vue dégagée', 'Espace extérieur'],
    color: 'yellow'
  },
  {
    id: 'furnished',
    name: 'Meublé',
    icon: HomeIcon,
    description: 'Entièrement équipé et meublé',
    features: ['Équipé', 'Meublé', 'Prêt à vivre'],
    color: 'orange'
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
  const [amenitiesList, setAmenitiesList] = useState(amenities);

  const handleEdit = (amenity) => {
    setSelectedAmenity(amenity);
    setIsModalOpen(true);
  };

  const handleDelete = (amenity) => {
    if (window.confirm(`Êtes-vous sûr de vouloir supprimer l'équipement "${amenity.name}" ?`)) {
      setAmenitiesList(prev => prev.filter(a => a.id !== amenity.id));
      toast.success('Équipement supprimé avec succès');
    }
  };

  const handleSave = (formData) => {
    if (selectedAmenity) {
      setAmenitiesList(prev => prev.map(a => a.id === selectedAmenity.id ? formData : a));
      toast.success('Équipement mis à jour avec succès');
    } else {
      setAmenitiesList(prev => [...prev, formData]);
      toast.success('Équipement créé avec succès');
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
