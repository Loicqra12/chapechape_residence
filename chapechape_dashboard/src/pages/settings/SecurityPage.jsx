import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  CardHeader,
  TextField,
  Button,
  Switch,
  FormControlLabel,
  Alert,
  IconButton,
  InputAdornment,
  Divider,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from '@mui/material';
import {
  Security as SecurityIcon,
  VpnKey as KeyIcon,
  Lock as LockIcon,
  Shield as ShieldIcon,
  Timer as TimerIcon,
  Save as SaveIcon,
  Visibility as VisibilityIcon,
  VisibilityOff as VisibilityOffIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { settingsService } from '../../services/settingsService';
import toast from 'react-hot-toast';

const SecurityPage = () => {
  const [settings, setSettings] = useState({});
  const [loading, setLoading] = useState(true);
  const [edited, setEdited] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);
  const [showWhitelistInput, setShowWhitelistInput] = useState(false);
  const [newWhitelistIP, setNewWhitelistIP] = useState('');
  const [showOriginInput, setShowOriginInput] = useState(false);
  const [newOrigin, setNewOrigin] = useState('');

  useEffect(() => {
    loadSecuritySettings();
  }, []);

  const loadSecuritySettings = async () => {
    try {
      setLoading(true);
      const response = await settingsService.getSettings('security');

      if (response.success && response.data.security) {
        const flatSettings = {};
        Object.entries(response.data.security).forEach(([key, setting]) => {
          flatSettings[key.replace('security_', '')] = setting.value;
        });
        setSettings(flatSettings);
      } else {
        // Default values
        setSettings({
          passwordMinLength: 8,
          passwordRequireUppercase: true,
          passwordRequireNumbers: true,
          passwordRequireSpecial: true,
          passwordExpiryDays: 90,
          maxLoginAttempts: 5,
          lockoutDuration: 30,
          sessionTimeout: 60,
          twoFactorEnabled: true,
          twoFactorMandatory: false,
          jwtExpiryHours: 24,
          ipWhitelist: ['192.168.1.1', '10.0.0.1'],
          apiRateLimit: 100,
          sslEnabled: true,
          corsAllowedOrigins: ['https://chapechape.fr'],
        });
      }
    } catch (error) {
      console.error('Error loading security settings:', error);
      toast.error('Erreur lors du chargement des paramètres de sécurité');
    } finally {
      setLoading(false);
    }
  };

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
      setLoading(true);

      const settingsArray = Object.entries(settings).map(([key, value]) => ({
        key: `security_${key}`,
        value,
        category: 'security',
        type: Array.isArray(value) ? 'json' : typeof value === 'number' ? 'number' : typeof value === 'boolean' ? 'boolean' : 'string',
        description: `Security setting for ${key}`
      }));

      const response = await settingsService.updateSettings(settingsArray);

      if (response.success) {
        setSuccess(true);
        setEdited(false);
        toast.success('Paramètres de sécurité enregistrés');
        setTimeout(() => setSuccess(false), 3000);
      } else {
        setError(response.error);
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Error saving security settings:', error);
      setError('Erreur lors de la sauvegarde des paramètres de sécurité');
      toast.error('Erreur lors de la sauvegarde');
    } finally {
      setLoading(false);
    }
  };

  const handleAddWhitelistIP = () => {
    if (newWhitelistIP && !settings.ipWhitelist.includes(newWhitelistIP)) {
      setSettings(prev => ({
        ...prev,
        ipWhitelist: [...prev.ipWhitelist, newWhitelistIP]
      }));
      setNewWhitelistIP('');
      setEdited(true);
    }
  };

  const handleRemoveWhitelistIP = (ip) => {
    setSettings(prev => ({
      ...prev,
      ipWhitelist: prev.ipWhitelist.filter(item => item !== ip)
    }));
    setEdited(true);
  };

  const handleAddOrigin = () => {
    if (newOrigin && !settings.corsAllowedOrigins.includes(newOrigin)) {
      setSettings(prev => ({
        ...prev,
        corsAllowedOrigins: [...prev.corsAllowedOrigins, newOrigin]
      }));
      setNewOrigin('');
      setEdited(true);
    }
  };

  const handleRemoveOrigin = (origin) => {
    setSettings(prev => ({
      ...prev,
      corsAllowedOrigins: prev.corsAllowedOrigins.filter(item => item !== origin)
    }));
    setEdited(true);
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Paramètres de Sécurité
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
          Les paramètres de sécurité ont été enregistrés avec succès
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Politique de Mot de Passe */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardHeader
              title="Politique de Mot de Passe"
              avatar={<KeyIcon />}
            />
            <CardContent>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Longueur minimale"
                    value={settings.passwordMinLength}
                    onChange={handleChange('passwordMinLength')}
                    type="number"
                    InputProps={{
                      endAdornment: <InputAdornment position="end">caractères</InputAdornment>,
                    }}
                  />
                </Grid>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={settings.passwordRequireUppercase}
                        onChange={handleChange('passwordRequireUppercase')}
                      />
                    }
                    label="Exiger des majuscules"
                  />
                </Grid>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={settings.passwordRequireNumbers}
                        onChange={handleChange('passwordRequireNumbers')}
                      />
                    }
                    label="Exiger des chiffres"
                  />
                </Grid>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={settings.passwordRequireSpecial}
                        onChange={handleChange('passwordRequireSpecial')}
                      />
                    }
                    label="Exiger des caractères spéciaux"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Expiration du mot de passe"
                    value={settings.passwordExpiryDays}
                    onChange={handleChange('passwordExpiryDays')}
                    type="number"
                    InputProps={{
                      endAdornment: <InputAdornment position="end">jours</InputAdornment>,
                    }}
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Authentification */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardHeader
              title="Authentification"
              avatar={<LockIcon />}
            />
            <CardContent>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Tentatives de connexion max"
                    value={settings.maxLoginAttempts}
                    onChange={handleChange('maxLoginAttempts')}
                    type="number"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Durée de verrouillage"
                    value={settings.lockoutDuration}
                    onChange={handleChange('lockoutDuration')}
                    type="number"
                    InputProps={{
                      endAdornment: <InputAdornment position="end">minutes</InputAdornment>,
                    }}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Expiration du token JWT"
                    value={settings.jwtExpiryHours}
                    onChange={handleChange('jwtExpiryHours')}
                    type="number"
                    InputProps={{
                      endAdornment: <InputAdornment position="end">heures</InputAdornment>,
                    }}
                  />
                </Grid>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={settings.twoFactorEnabled}
                        onChange={handleChange('twoFactorEnabled')}
                      />
                    }
                    label="Activer l'authentification à deux facteurs"
                  />
                </Grid>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={settings.twoFactorMandatory}
                        onChange={handleChange('twoFactorMandatory')}
                      />
                    }
                    label="2FA obligatoire pour tous les utilisateurs"
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Sécurité des Sessions */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardHeader
              title="Sécurité des Sessions"
              avatar={<TimerIcon />}
            />
            <CardContent>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Timeout de session"
                    value={settings.sessionTimeout}
                    onChange={handleChange('sessionTimeout')}
                    type="number"
                    InputProps={{
                      endAdornment: <InputAdornment position="end">minutes</InputAdornment>,
                    }}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Limite de requêtes API"
                    value={settings.apiRateLimit}
                    onChange={handleChange('apiRateLimit')}
                    type="number"
                    InputProps={{
                      endAdornment: <InputAdornment position="end">req/min</InputAdornment>,
                    }}
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Liste Blanche IP */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardHeader
              title="Liste Blanche IP"
              avatar={<ShieldIcon />}
            />
            <CardContent>
              <List>
                {(settings.ipWhitelist || []).map((ip) => (
                  <ListItem key={ip}>
                    <ListItemText primary={ip} />
                    <ListItemSecondaryAction>
                      <IconButton
                        edge="end"
                        onClick={() => handleRemoveWhitelistIP(ip)}
                        size="small"
                      >
                        <DeleteIcon />
                      </IconButton>
                    </ListItemSecondaryAction>
                  </ListItem>
                ))}
              </List>
              <Box sx={{ mt: 2, display: 'flex', gap: 1 }}>
                <TextField
                  fullWidth
                  label="Nouvelle IP"
                  value={newWhitelistIP}
                  onChange={(e) => setNewWhitelistIP(e.target.value)}
                  placeholder="192.168.1.1"
                />
                <Button
                  variant="contained"
                  onClick={handleAddWhitelistIP}
                  disabled={!newWhitelistIP}
                >
                  Ajouter
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Paramètres CORS */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardHeader
              title="Paramètres CORS"
              avatar={<SecurityIcon />}
            />
            <CardContent>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.sslEnabled}
                    onChange={handleChange('sslEnabled')}
                  />
                }
                label="Forcer HTTPS"
              />
              <Typography variant="subtitle2" sx={{ mt: 2, mb: 1 }}>
                Origines autorisées
              </Typography>
              <List>
                {(settings.corsAllowedOrigins || []).map((origin) => (
                  <ListItem key={origin}>
                    <ListItemText primary={origin} />
                    <ListItemSecondaryAction>
                      <IconButton
                        edge="end"
                        onClick={() => handleRemoveOrigin(origin)}
                        size="small"
                      >
                        <DeleteIcon />
                      </IconButton>
                    </ListItemSecondaryAction>
                  </ListItem>
                ))}
              </List>
              <Box sx={{ mt: 2, display: 'flex', gap: 1 }}>
                <TextField
                  fullWidth
                  label="Nouvelle origine"
                  value={newOrigin}
                  onChange={(e) => setNewOrigin(e.target.value)}
                  placeholder="https://example.com"
                />
                <Button
                  variant="contained"
                  onClick={handleAddOrigin}
                  disabled={!newOrigin}
                >
                  Ajouter
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default SecurityPage;
