import React, { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  TextField,
  Button,
  Switch,
  FormControlLabel,
  Divider,
  Alert,
  Card,
  CardContent,
  CardHeader,
  IconButton,
  InputAdornment,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
} from '@mui/material';
import {
  Save as SaveIcon,
  Edit as EditIcon,
  Language as LanguageIcon,
  Euro as EuroIcon,
  Notifications as NotificationsIcon,
  Email as EmailIcon,
  Storage as StorageIcon,
  Security as SecurityIcon,
} from '@mui/icons-material';

const SettingsPage = () => {
  const [settings, setSettings] = useState({
    siteName: 'ChapeChape Residence',
    siteDescription: 'Plateforme de réservation de résidences de luxe',
    contactEmail: 'contact@chapechape.fr',
    supportPhone: '+33 1 23 45 67 89',
    language: 'fr',
    currency: 'EUR',
    timezone: 'Europe/Paris',
    bookingAutoConfirm: false,
    emailNotifications: true,
    smsNotifications: true,
    maintenanceMode: false,
    defaultCommission: 10,
    maxBookingsPerDay: 50,
    maxImagesPerProperty: 20,
    maxFileSize: 10,
  });

  const [edited, setEdited] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);

  const handleChange = (field) => (event) => {
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    setSettings(prev => ({
      ...prev,
      [field]: value
    }));
    setEdited(true);
    setSuccess(false);
  };

  const handleSave = async () => {
    try {
      // TODO: Implémenter la sauvegarde API
      setSuccess(true);
      setEdited(false);
    } catch (error) {
      setError('Erreur lors de la sauvegarde des paramètres');
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Paramètres Système
        </Typography>
        <Button
          variant="contained"
          color="primary"
          startIcon={<SaveIcon />}
          onClick={handleSave}
          disabled={!edited}
        >
          Enregistrer les modifications
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {success && (
        <Alert severity="success" sx={{ mb: 3 }} onClose={() => setSuccess(false)}>
          Les paramètres ont été enregistrés avec succès
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Paramètres Généraux */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardHeader 
              title="Paramètres Généraux"
              avatar={<LanguageIcon />}
            />
            <CardContent>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Nom du site"
                    value={settings.siteName}
                    onChange={handleChange('siteName')}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Description"
                    value={settings.siteDescription}
                    multiline
                    rows={2}
                    onChange={handleChange('siteDescription')}
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <FormControl fullWidth>
                    <InputLabel>Langue par défaut</InputLabel>
                    <Select
                      value={settings.language}
                      label="Langue par défaut"
                      onChange={handleChange('language')}
                    >
                      <MenuItem value="fr">Français</MenuItem>
                      <MenuItem value="en">English</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>
                <Grid item xs={12} md={6}>
                  <FormControl fullWidth>
                    <InputLabel>Fuseau horaire</InputLabel>
                    <Select
                      value={settings.timezone}
                      label="Fuseau horaire"
                      onChange={handleChange('timezone')}
                    >
                      <MenuItem value="Europe/Paris">Paris (UTC+1)</MenuItem>
                      <MenuItem value="UTC">UTC</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Paramètres de Contact */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardHeader 
              title="Contact"
              avatar={<EmailIcon />}
            />
            <CardContent>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Email de contact"
                    value={settings.contactEmail}
                    onChange={handleChange('contactEmail')}
                    type="email"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Téléphone support"
                    value={settings.supportPhone}
                    onChange={handleChange('supportPhone')}
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Paramètres de Réservation */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardHeader 
              title="Réservations"
              avatar={<EuroIcon />}
            />
            <CardContent>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Commission par défaut (%)"
                    value={settings.defaultCommission}
                    onChange={handleChange('defaultCommission')}
                    type="number"
                    InputProps={{
                      endAdornment: <InputAdornment position="end">%</InputAdornment>,
                    }}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Réservations max par jour"
                    value={settings.maxBookingsPerDay}
                    onChange={handleChange('maxBookingsPerDay')}
                    type="number"
                  />
                </Grid>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={settings.bookingAutoConfirm}
                        onChange={handleChange('bookingAutoConfirm')}
                      />
                    }
                    label="Confirmation automatique des réservations"
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Paramètres de Notification */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardHeader 
              title="Notifications"
              avatar={<NotificationsIcon />}
            />
            <CardContent>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={settings.emailNotifications}
                        onChange={handleChange('emailNotifications')}
                      />
                    }
                    label="Notifications par email"
                  />
                </Grid>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={settings.smsNotifications}
                        onChange={handleChange('smsNotifications')}
                      />
                    }
                    label="Notifications par SMS"
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Paramètres de Stockage */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardHeader 
              title="Stockage"
              avatar={<StorageIcon />}
            />
            <CardContent>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Images max par résidence"
                    value={settings.maxImagesPerProperty}
                    onChange={handleChange('maxImagesPerProperty')}
                    type="number"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Taille max des fichiers"
                    value={settings.maxFileSize}
                    onChange={handleChange('maxFileSize')}
                    type="number"
                    InputProps={{
                      endAdornment: <InputAdornment position="end">MB</InputAdornment>,
                    }}
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Paramètres de Maintenance */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardHeader 
              title="Maintenance"
              avatar={<SecurityIcon />}
            />
            <CardContent>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={settings.maintenanceMode}
                        onChange={handleChange('maintenanceMode')}
                      />
                    }
                    label="Mode maintenance"
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default SettingsPage;
