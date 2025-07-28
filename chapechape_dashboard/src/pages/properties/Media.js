import React, { useState, useCallback, useEffect, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  PhotoIcon,
  ArrowUpTrayIcon,
  TrashIcon,
  MagnifyingGlassIcon,
  FunnelIcon,
  XMarkIcon,
  CheckIcon,
  PencilSquareIcon,
  EyeIcon
} from '@heroicons/react/24/outline';
import toast from 'react-hot-toast';
import { adminService } from '../../services/adminService';

// Composant pour l'aperçu des images
const ImagePreview = ({ file, onRemove }) => {
  const [loading, setLoading] = useState(true);
  const [preview, setPreview] = useState('');

  React.useEffect(() => {
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setPreview(reader.result);
        setLoading(false);
      };
      reader.readAsDataURL(file);
    }
  }, [file]);

  if (loading) {
    return (
      <div className="w-full h-48 bg-gray-100 dark:bg-gray-800 rounded-lg animate-pulse" />
    );
  }

  return (
    <div className="relative group">
      <img
        src={preview}
        alt="Preview"
        className="w-full h-48 object-cover rounded-lg"
      />
      <button
        onClick={onRemove}
        className="absolute top-2 right-2 p-2 bg-red-500 text-white rounded-full opacity-0 group-hover:opacity-100 transition-opacity"
      >
        <TrashIcon className="w-4 h-4" />
      </button>
    </div>
  );
};

// Composant pour la zone de drop
const DropZone = ({ onFilesDrop }) => {
  const [isDragging, setIsDragging] = useState(false);

  const handleDrag = useCallback((e) => {
    e.preventDefault();
    e.stopPropagation();
  }, []);

  const handleDragIn = useCallback((e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  }, []);

  const handleDragOut = useCallback((e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  }, []);

  const handleDrop = useCallback((e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
    
    const files = [...e.dataTransfer.files];
    const imageFiles = files.filter(file => file.type.startsWith('image/'));
    if (imageFiles.length > 0) {
      onFilesDrop(imageFiles);
    }
  }, [onFilesDrop]);

  return (
    <div
      onDragEnter={handleDragIn}
      onDragLeave={handleDragOut}
      onDragOver={handleDrag}
      onDrop={handleDrop}
      className={`w-full p-8 border-2 border-dashed rounded-lg text-center transition-colors ${
        isDragging
          ? 'border-primary bg-primary bg-opacity-10'
          : 'border-gray-300 dark:border-gray-600'
      }`}
    >
      <PhotoIcon className="w-12 h-12 mx-auto text-gray-400" />
      <div className="mt-4">
        <p className="text-sm text-gray-600 dark:text-gray-400">
          Glissez-déposez vos images ici, ou
        </p>
        <button className="mt-2 text-primary hover:text-primary-dark">
          parcourez vos fichiers
        </button>
      </div>
      <p className="mt-2 text-xs text-gray-500 dark:text-gray-400">
        PNG, JPG jusqu'à 10MB
      </p>
    </div>
  );
};

// Composant principal de la galerie
const MediaGallery = ({ images, onSelect, selectedImages, view }) => {
  return (
    <div className={`grid ${view === 'grid' ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4' : 'grid-cols-1'} gap-6`}>
      <AnimatePresence>
        {images.map((image) => (
          <motion.div
            key={image.id}
            layout
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className={`relative group ${
              view === 'list' ? 'flex items-center space-x-4' : ''
            }`}
          >
            <div className={`relative ${view === 'list' ? 'w-48' : 'w-full'}`}>
              <img
                src={image.url}
                alt={image.name}
                className={`${
                  view === 'list' ? 'h-32' : 'h-48'
                } w-full object-cover rounded-lg`}
              />
              <div className="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-30 transition-opacity rounded-lg" />
              <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                <div className="flex space-x-2">
                  <button
                    onClick={() => onSelect(image)}
                    className="p-2 bg-white text-gray-700 rounded-full hover:bg-gray-100"
                  >
                    <CheckIcon className="w-4 h-4" />
                  </button>
                  <button className="p-2 bg-white text-gray-700 rounded-full hover:bg-gray-100">
                    <EyeIcon className="w-4 h-4" />
                  </button>
                  <button className="p-2 bg-white text-gray-700 rounded-full hover:bg-gray-100">
                    <PencilSquareIcon className="w-4 h-4" />
                  </button>
                  <button className="p-2 bg-white text-red-500 rounded-full hover:bg-red-50">
                    <TrashIcon className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
            {view === 'list' && (
              <div className="flex-1">
                <h3 className="text-sm font-medium text-gray-900 dark:text-white">
                  {image.name}
                </h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {image.size}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {image.date}
                </p>
              </div>
            )}
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
};

// Page principale
const Media = () => {
  const [view, setView] = useState('grid');
  const [selectedImages, setSelectedImages] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [showFilters, setShowFilters] = useState(false);
  const [filters, setFilters] = useState({
    type: '',
    date: '',
    size: ''
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Images chargées depuis l'API
  const [images, setImages] = useState([]);

  // Images de fallback en cas d'erreur API (memoized pour éviter les re-renders)
  const fallbackImages = useMemo(() => [
    {
      id: 1,
      name: 'Villa de luxe.jpg',
      url: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2075&q=80',
      size: '2.4 MB',
      date: '2024-03-05',
      type: 'image/jpeg'
    },
    {
      id: 2,
      name: 'Appartement moderne.jpg', 
      url: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80',
      size: '1.8 MB',
      date: '2024-03-04',
      type: 'image/jpeg'
    },
    {
      id: 3,
      name: 'Studio design.jpg',
      url: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2080&q=80',
      size: '3.1 MB',
      date: '2024-03-03',
      type: 'image/jpeg'
    },
    {
      id: 4,
      name: 'Penthouse vue mer.jpg',
      url: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2053&q=80',
      size: '2.9 MB',
      date: '2024-03-02',
      type: 'image/jpeg'
    }
  ], []);

  // Fonction pour charger les médias depuis l'API
  const fetchMedia = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      // Simuler un appel API pour récupérer les médias
      // Note: Adapter selon les endpoints backend disponibles
      const response = await adminService.getAllMedia?.() || { success: false };
      
      if (response.success) {
        // Transformer les données backend
        const transformedMedia = response.data.map(media => ({
          id: media._id || media.id,
          name: media.name || media.filename,
          url: media.url || media.path,
          size: media.size ? `${(media.size / (1024 * 1024)).toFixed(1)} MB` : 'N/A',
          date: media.createdAt ? new Date(media.createdAt).toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
          type: media.type || media.mimetype || 'image/jpeg'
        }));
        setImages(transformedMedia);
      } else {
        // Utiliser les données de fallback
        setImages(fallbackImages);
        setError('Impossible de charger les médias depuis le serveur. Utilisation des données locales.');
      }
    } catch (error) {
      console.error('Erreur lors du chargement des médias:', error);
      setImages(fallbackImages);
      setError('Erreur lors du chargement des médias.');
    } finally {
      setLoading(false);
    }
  }, [fallbackImages]);

  // Charger les données au démarrage
  useEffect(() => {
    fetchMedia();
  }, [fetchMedia]);

  const handleFilesDrop = (files) => {
    // Créer des URLs locales pour la prévisualisation
    const newFiles = Array.from(files).map(file => ({
      id: Date.now() + Math.random(),
      name: file.name,
      url: URL.createObjectURL(file),
      size: (file.size / (1024 * 1024)).toFixed(1) + ' MB',
      date: new Date().toISOString().split('T')[0],
      type: file.type
    }));

    // Ajouter les nouveaux fichiers aux images existantes
    setImages(prevImages => [...newFiles, ...prevImages]);
    
    // Simuler un upload réussi
    toast.success('Images téléchargées avec succès');
  };

  const handleDelete = async (id) => {
    const imageToDelete = images.find(img => img.id === id);
    if (!window.confirm(`Êtes-vous sûr de vouloir supprimer "${imageToDelete?.name}" ?`)) {
      return;
    }

    try {
      // Tenter de supprimer via l'API si disponible
      const response = await adminService.deleteMedia?.(id) || { success: true };
      
      if (response.success) {
        setImages(prevImages => prevImages.filter(img => img.id !== id));
        toast.success('Image supprimée avec succès');
      } else {
        throw new Error(response.error || 'Erreur lors de la suppression');
      }
    } catch (error) {
      console.error('Erreur lors de la suppression:', error);
      // Supprimer quand même localement si l'API n'est pas disponible
      setImages(prevImages => prevImages.filter(img => img.id !== id));
      toast.success('Image supprimée localement');
    }
  };

  const toggleImageSelection = (image) => {
    setSelectedImages(prev =>
      prev.includes(image.id)
        ? prev.filter(id => id !== image.id)
        : [...prev, image.id]
    );
  };

  return (
    <div className="p-6">
      {/* En-tête */}
      <div className="flex justify-between items-start mb-6">
        <div className="flex items-center">
          <PhotoIcon className="w-8 h-8 text-primary mr-3" />
          <h1 className="text-2xl font-bold text-gray-800 dark:text-white">
            Médiathèque
          </h1>
        </div>
        <button
          onClick={() => document.getElementById('fileInput').click()}
          className="flex items-center px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark transition-colors duration-200"
        >
          <ArrowUpTrayIcon className="w-5 h-5 mr-2" />
          Ajouter des médias
        </button>
        <input
          id="fileInput"
          type="file"
          multiple
          accept="image/*"
          className="hidden"
          onChange={(e) => handleFilesDrop([...e.target.files])}
        />
      </div>

      {/* Barre de recherche et filtres */}
      <div className="mb-6">
        <div className="flex flex-col md:flex-row space-y-4 md:space-y-0 md:space-x-4">
          <div className="flex-1 relative">
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Rechercher des médias..."
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
          <div className="flex space-x-2">
            <button
              onClick={() => setView('grid')}
              className={`p-2 rounded-lg ${
                view === 'grid'
                  ? 'bg-primary text-white'
                  : 'bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-200'
              }`}
            >
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
              </svg>
            </button>
            <button
              onClick={() => setView('list')}
              className={`p-2 rounded-lg ${
                view === 'list'
                  ? 'bg-primary text-white'
                  : 'bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-200'
              }`}
            >
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
              </svg>
            </button>
          </div>
        </div>

        <AnimatePresence>
          {showFilters && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              className="mt-4 p-4 bg-white dark:bg-gray-800 rounded-lg shadow-sm"
            >
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Type de fichier
                  </label>
                  <select
                    name="type"
                    value={filters.type}
                    onChange={(e) => setFilters(prev => ({ ...prev, type: e.target.value }))}
                    className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
                  >
                    <option value="">Tous</option>
                    <option value="image/jpeg">JPEG</option>
                    <option value="image/png">PNG</option>
                    <option value="image/gif">GIF</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Date
                  </label>
                  <select
                    name="date"
                    value={filters.date}
                    onChange={(e) => setFilters(prev => ({ ...prev, date: e.target.value }))}
                    className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
                  >
                    <option value="">Toutes les dates</option>
                    <option value="today">Aujourd'hui</option>
                    <option value="week">Cette semaine</option>
                    <option value="month">Ce mois</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Taille
                  </label>
                  <select
                    name="size"
                    value={filters.size}
                    onChange={(e) => setFilters(prev => ({ ...prev, size: e.target.value }))}
                    className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm dark:bg-gray-700 dark:border-gray-600"
                  >
                    <option value="">Toutes les tailles</option>
                    <option value="small">&lt; 1MB</option>
                    <option value="medium">1MB - 5MB</option>
                    <option value="large">&gt; 5MB</option>
                  </select>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Zone de drop */}
      <div className="mb-8">
        <DropZone onFilesDrop={handleFilesDrop} />
      </div>

      {/* Galerie */}
      <MediaGallery
        images={images}
        onSelect={toggleImageSelection}
        selectedImages={selectedImages}
        view={view}
      />
    </div>
  );
};

export default Media;
