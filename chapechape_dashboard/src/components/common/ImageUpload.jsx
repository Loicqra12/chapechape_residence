import React, { useState } from 'react';
import {
  Box,
  Button,
  CircularProgress,
  IconButton,
  Typography,
} from '@mui/material';
import {
  CloudUpload as UploadIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';

const ImageUpload = ({ currentImage, onImageChange, onImageDelete }) => {
  const [loading, setLoading] = useState(false);
  const [preview, setPreview] = useState(currentImage);

  const handleImageChange = async (event) => {
    const file = event.target.files[0];
    if (!file) return;

    // Vérifier le type de fichier
    if (!file.type.startsWith('image/')) {
      alert('Veuillez sélectionner une image');
      return;
    }

    // Vérifier la taille (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      alert('L\'image ne doit pas dépasser 5MB');
      return;
    }

    setLoading(true);

    try {
      // Créer une URL pour la prévisualisation
      const previewUrl = URL.createObjectURL(file);
      setPreview(previewUrl);

      // Appeler la fonction de callback avec le fichier
      if (onImageChange) {
        await onImageChange(file);
      }
    } catch (error) {
      console.error('Erreur lors du téléchargement:', error);
      alert('Erreur lors du téléchargement de l\'image');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = () => {
    setPreview(null);
    if (onImageDelete) {
      onImageDelete();
    }
  };

  return (
    <Box>
      {preview ? (
        <Box sx={{ position: 'relative', width: 'fit-content' }}>
          <img
            src={preview}
            alt="Preview"
            style={{
              width: '150px',
              height: '150px',
              objectFit: 'cover',
              borderRadius: '8px'
            }}
          />
          <IconButton
            onClick={handleDelete}
            sx={{
              position: 'absolute',
              top: -8,
              right: -8,
              bgcolor: 'background.paper',
              boxShadow: 1,
              '&:hover': { bgcolor: 'error.light', color: 'white' }
            }}
            size="small"
          >
            <DeleteIcon fontSize="small" />
          </IconButton>
        </Box>
      ) : (
        <Button
          component="label"
          variant="outlined"
          startIcon={loading ? <CircularProgress size={20} /> : <UploadIcon />}
          sx={{
            width: '150px',
            height: '150px',
            borderRadius: '8px',
            borderStyle: 'dashed'
          }}
          disabled={loading}
        >
          <input
            type="file"
            hidden
            accept="image/*"
            onChange={handleImageChange}
          />
          <Typography variant="body2" color="text.secondary">
            {loading ? 'Chargement...' : 'Télécharger une image'}
          </Typography>
        </Button>
      )}
    </Box>
  );
};

export default ImageUpload;
