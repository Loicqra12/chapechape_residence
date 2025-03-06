import React, { useState } from 'react';
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

const propertyTypes = [
  {
    id: 'apartment',
    name: 'Appartement',
    icon: BuildingOfficeIcon,
    description: 'Unité d\'habitation dans un immeuble résidentiel',
    features: ['Balcon possible', 'Vue ville', 'Sécurité commune'],
    color: 'blue'
  },
  {
    id: 'studio',
    name: 'Studio',
    icon: BuildingOfficeIcon,
    description: 'Petit appartement compact tout-en-un',
    features: ['Compact', 'Fonctionnel', 'Économique'],
    color: 'orange'
  },
  {
    id: 'villa',
    name: 'Villa',
    icon: HomeModernIcon,
    description: 'Grande propriété luxueuse avec extérieurs',
    features: ['Piscine possible', 'Grand jardin', 'Prestige'],
    color: 'purple'
  },
  {
    id: 'room',
    name: 'Chambre',
    icon: HomeIcon,
    description: 'Chambre individuelle dans une résidence',
    features: ['Économique', 'Idéal court séjour', 'Colocation possible'],
    color: 'yellow'
  },
  {
    id: 'bungalow',
    name: 'Bungalow',
    icon: HomeIcon,
    description: 'Petite maison de plain-pied',
    features: ['Plain-pied', 'Jardin privé', 'Intimité'],
    color: 'green'
  },
  {
    id: 'penthouse',
    name: 'Penthouse',
    icon: BuildingLibraryIcon,
    description: 'Appartement luxueux au dernier étage',
    features: ['Vue panoramique', 'Prestige', 'Grande terrasse'],
    color: 'indigo'
  },
  {
    id: 'hotel',
    name: 'Hôtel',
    icon: BuildingStorefrontIcon,
    description: 'Chambre ou suite d\'hôtel',
    features: ['Service complet', 'Confort', 'Flexibilité'],
    color: 'red'
  },
  {
    id: 'luxury',
    name: 'Luxe',
    icon: HomeModernIcon,
    description: 'Propriété haut de gamme avec prestations exclusives',
    features: ['Sur-mesure', 'Services premium', 'Emplacement privilégié'],
    color: 'pink'
  },
  {
    id: 'coworking',
    name: 'Coworking',
    icon: BriefcaseIcon,
    description: 'Espace de travail partagé',
    features: ['Internet haut débit', 'Salles de réunion', 'Espace commun'],
    color: 'cyan'
  },
  {
    id: 'student',
    name: 'Étudiant',
    icon: AcademicCapIcon,
    description: 'Logement adapté aux étudiants',
    features: ['Proche campus', 'Meublé', 'Prix abordable'],
    color: 'teal'
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
  const [types, setTypes] = useState(propertyTypes);

  const handleEdit = (type) => {
    setSelectedType(type);
    setIsModalOpen(true);
  };

  const handleDelete = (type) => {
    if (window.confirm(`Êtes-vous sûr de vouloir supprimer le type "${type.name}" ?`)) {
      setTypes(prev => prev.filter(t => t.id !== type.id));
      toast.success('Type de propriété supprimé avec succès');
    }
  };

  const handleSave = (formData) => {
    if (selectedType) {
      setTypes(prev => prev.map(t => t.id === selectedType.id ? formData : t));
      toast.success('Type de propriété mis à jour avec succès');
    } else {
      setTypes(prev => [...prev, formData]);
      toast.success('Type de propriété créé avec succès');
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
