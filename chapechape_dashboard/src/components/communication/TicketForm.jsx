import React, { useState } from 'react';
import {
  Box,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Typography,
  Paper,
  Stack,
} from '@mui/material';
import { Send as SendIcon } from '@mui/icons-material';

const TicketForm = ({ onSubmit, loading }) => {
  const [formData, setFormData] = useState({
    subject: '',
    category: '',
    priority: 'normal',
    description: '',
    attachments: []
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(formData);
  };

  const handleFileChange = (e) => {
    const files = Array.from(e.target.files);
    setFormData(prev => ({
      ...prev,
      attachments: [...prev.attachments, ...files]
    }));
  };

  const categories = [
    { id: 'technical', label: 'Problème technique' },
    { id: 'billing', label: 'Facturation' },
    { id: 'reservation', label: 'Réservation' },
    { id: 'account', label: 'Compte utilisateur' },
    { id: 'other', label: 'Autre' }
  ];

  const priorities = [
    { id: 'low', label: 'Basse' },
    { id: 'normal', label: 'Normale' },
    { id: 'high', label: 'Haute' },
    { id: 'urgent', label: 'Urgente' }
  ];

  return (
    <Paper elevation={0} sx={{ p: 3 }}>
      <form onSubmit={handleSubmit}>
        <Stack spacing={3}>
          <Typography variant="h6" gutterBottom>
            Créer un nouveau ticket
          </Typography>

          <TextField
            fullWidth
            label="Sujet"
            required
            value={formData.subject}
            onChange={(e) => setFormData(prev => ({ ...prev, subject: e.target.value }))}
            helperText="Décrivez brièvement votre problème"
          />

          <Box sx={{ display: 'flex', gap: 2 }}>
            <FormControl fullWidth required>
              <InputLabel>Catégorie</InputLabel>
              <Select
                value={formData.category}
                label="Catégorie"
                onChange={(e) => setFormData(prev => ({ ...prev, category: e.target.value }))}
              >
                {categories.map(category => (
                  <MenuItem key={category.id} value={category.id}>
                    {category.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <FormControl fullWidth>
              <InputLabel>Priorité</InputLabel>
              <Select
                value={formData.priority}
                label="Priorité"
                onChange={(e) => setFormData(prev => ({ ...prev, priority: e.target.value }))}
              >
                {priorities.map(priority => (
                  <MenuItem key={priority.id} value={priority.id}>
                    {priority.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Box>

          <TextField
            fullWidth
            multiline
            rows={6}
            label="Description détaillée"
            required
            value={formData.description}
            onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
            helperText="Fournissez autant de détails que possible"
          />

          <Box>
            <input
              type="file"
              multiple
              onChange={handleFileChange}
              style={{ display: 'none' }}
              id="ticket-attachments"
            />
            <label htmlFor="ticket-attachments">
              <Button
                component="span"
                variant="outlined"
                sx={{ mr: 2 }}
              >
                Ajouter des fichiers
              </Button>
            </label>
            {formData.attachments.length > 0 && (
              <Typography variant="caption" color="text.secondary">
                {formData.attachments.length} fichier(s) sélectionné(s)
              </Typography>
            )}
          </Box>

          <Button
            type="submit"
            variant="contained"
            startIcon={<SendIcon />}
            disabled={loading || !formData.subject || !formData.category || !formData.description}
          >
            Soumettre le ticket
          </Button>
        </Stack>
      </form>
    </Paper>
  );
};

export default TicketForm;
