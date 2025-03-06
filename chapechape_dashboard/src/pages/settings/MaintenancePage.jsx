import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  CardHeader,
  Button,
  LinearProgress,
  Alert,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  ListItemSecondaryAction,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Switch,
  FormControlLabel,
  Chip,
} from '@mui/material';
import {
  BuildCircle as BuildIcon,
  Storage as StorageIcon,
  DeleteSweep as CleanupIcon,
  Backup as BackupIcon,
  Restore as RestoreIcon,
  CloudUpload as UploadIcon,
  Check as CheckIcon,
  Warning as WarningIcon,
  Error as ErrorIcon,
  Schedule as ScheduleIcon,
  Delete as DeleteIcon,
  Download as DownloadIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';

const MaintenancePage = () => {
  const [maintenanceMode, setMaintenanceMode] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [backups, setBackups] = useState([
    {
      id: 1,
      name: 'backup_20250306_143000.zip',
      size: '256MB',
      date: '2025-03-06T14:30:00',
      type: 'auto',
      status: 'success'
    },
    // Autres sauvegardes...
  ]);
  const [systemStatus, setSystemStatus] = useState({
    diskSpace: {
      total: 1000,
      used: 450,
      available: 550
    },
    databaseSize: 120,
    cacheSize: 25,
    uploadSize: 305,
    lastCleanup: '2025-03-01T10:00:00'
  });
  const [openBackupDialog, setOpenBackupDialog] = useState(false);
  const [backupName, setBackupName] = useState('');

  const handleMaintenanceToggle = async () => {
    try {
      setLoading(true);
      // TODO: Appel API pour activer/désactiver le mode maintenance
      setMaintenanceMode(!maintenanceMode);
      setSuccess(`Mode maintenance ${!maintenanceMode ? 'activé' : 'désactivé'}`);
    } catch (error) {
      setError('Erreur lors du changement du mode maintenance');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateBackup = async () => {
    if (!backupName) return;
    try {
      setLoading(true);
      // TODO: Appel API pour créer une sauvegarde
      const newBackup = {
        id: Date.now(),
        name: backupName,
        size: '0MB',
        date: new Date().toISOString(),
        type: 'manual',
        status: 'pending'
      };
      setBackups([newBackup, ...backups]);
      setOpenBackupDialog(false);
      setBackupName('');
      setSuccess('Sauvegarde lancée avec succès');
    } catch (error) {
      setError('Erreur lors de la création de la sauvegarde');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteBackup = async (backupId) => {
    try {
      setLoading(true);
      // TODO: Appel API pour supprimer la sauvegarde
      setBackups(backups.filter(b => b.id !== backupId));
      setSuccess('Sauvegarde supprimée avec succès');
    } catch (error) {
      setError('Erreur lors de la suppression de la sauvegarde');
    } finally {
      setLoading(false);
    }
  };

  const handleCleanup = async (type) => {
    try {
      setLoading(true);
      // TODO: Appel API pour le nettoyage
      setSuccess(`Nettoyage ${type} effectué avec succès`);
    } catch (error) {
      setError(`Erreur lors du nettoyage ${type}`);
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'success':
        return 'success';
      case 'pending':
        return 'warning';
      case 'error':
        return 'error';
      default:
        return 'default';
    }
  };

  const formatSize = (size) => {
    return `${size}GB`;
  };

  const formatDate = (date) => {
    return format(new Date(date), 'dd/MM/yyyy HH:mm', { locale: fr });
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Maintenance Système
        </Typography>
        <FormControlLabel
          control={
            <Switch
              checked={maintenanceMode}
              onChange={handleMaintenanceToggle}
              disabled={loading}
            />
          }
          label={maintenanceMode ? 'Mode maintenance actif' : 'Mode maintenance inactif'}
        />
      </Box>

      {loading && <LinearProgress sx={{ mb: 2 }} />}

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {success && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess(null)}>
          {success}
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* État du Système */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardHeader 
              title="État du Système"
              avatar={<BuildIcon />}
            />
            <CardContent>
              <List>
                <ListItem>
                  <ListItemIcon>
                    <StorageIcon />
                  </ListItemIcon>
                  <ListItemText 
                    primary="Espace Disque"
                    secondary={`${formatSize(systemStatus.diskSpace.used)} utilisés sur ${formatSize(systemStatus.diskSpace.total)}`}
                  />
                  <LinearProgress 
                    variant="determinate"
                    value={(systemStatus.diskSpace.used / systemStatus.diskSpace.total) * 100}
                    sx={{ width: 100, ml: 2 }}
                  />
                </ListItem>
                <ListItem>
                  <ListItemIcon>
                    <StorageIcon />
                  </ListItemIcon>
                  <ListItemText 
                    primary="Taille Base de Données"
                    secondary={`${formatSize(systemStatus.databaseSize)}`}
                  />
                </ListItem>
                <ListItem>
                  <ListItemIcon>
                    <StorageIcon />
                  </ListItemIcon>
                  <ListItemText 
                    primary="Taille Cache"
                    secondary={`${formatSize(systemStatus.cacheSize)}`}
                  />
                </ListItem>
                <ListItem>
                  <ListItemIcon>
                    <UploadIcon />
                  </ListItemIcon>
                  <ListItemText 
                    primary="Taille Fichiers Uploadés"
                    secondary={`${formatSize(systemStatus.uploadSize)}`}
                  />
                </ListItem>
                <ListItem>
                  <ListItemIcon>
                    <ScheduleIcon />
                  </ListItemIcon>
                  <ListItemText 
                    primary="Dernier Nettoyage"
                    secondary={formatDate(systemStatus.lastCleanup)}
                  />
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* Actions de Maintenance */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardHeader 
              title="Actions de Maintenance"
              avatar={<CleanupIcon />}
            />
            <CardContent>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <Button
                    fullWidth
                    variant="outlined"
                    startIcon={<CleanupIcon />}
                    onClick={() => handleCleanup('cache')}
                    disabled={loading}
                  >
                    Nettoyer le Cache
                  </Button>
                </Grid>
                <Grid item xs={12}>
                  <Button
                    fullWidth
                    variant="outlined"
                    startIcon={<CleanupIcon />}
                    onClick={() => handleCleanup('temp')}
                    disabled={loading}
                  >
                    Nettoyer les Fichiers Temporaires
                  </Button>
                </Grid>
                <Grid item xs={12}>
                  <Button
                    fullWidth
                    variant="outlined"
                    startIcon={<CleanupIcon />}
                    onClick={() => handleCleanup('logs')}
                    disabled={loading}
                  >
                    Archiver les Logs
                  </Button>
                </Grid>
                <Grid item xs={12}>
                  <Button
                    fullWidth
                    variant="outlined"
                    color="warning"
                    startIcon={<CleanupIcon />}
                    onClick={() => handleCleanup('sessions')}
                    disabled={loading}
                  >
                    Nettoyer les Sessions Expirées
                  </Button>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Sauvegardes */}
        <Grid item xs={12}>
          <Card>
            <CardHeader 
              title="Sauvegardes"
              avatar={<BackupIcon />}
              action={
                <Button
                  variant="contained"
                  startIcon={<BackupIcon />}
                  onClick={() => setOpenBackupDialog(true)}
                  disabled={loading}
                >
                  Nouvelle Sauvegarde
                </Button>
              }
            />
            <CardContent>
              <List>
                {backups.map((backup) => (
                  <ListItem key={backup.id}>
                    <ListItemIcon>
                      {backup.status === 'success' ? (
                        <CheckIcon color="success" />
                      ) : backup.status === 'pending' ? (
                        <WarningIcon color="warning" />
                      ) : (
                        <ErrorIcon color="error" />
                      )}
                    </ListItemIcon>
                    <ListItemText
                      primary={backup.name}
                      secondary={`${backup.size} • ${formatDate(backup.date)}`}
                    />
                    <Chip
                      label={backup.type === 'auto' ? 'Auto' : 'Manuel'}
                      size="small"
                      sx={{ mr: 1 }}
                    />
                    <Chip
                      label={backup.status}
                      color={getStatusColor(backup.status)}
                      size="small"
                      sx={{ mr: 1 }}
                    />
                    <ListItemSecondaryAction>
                      <IconButton
                        edge="end"
                        onClick={() => {/* TODO: Télécharger */}}
                        disabled={backup.status !== 'success'}
                        sx={{ mr: 1 }}
                      >
                        <DownloadIcon />
                      </IconButton>
                      <IconButton
                        edge="end"
                        onClick={() => handleDeleteBackup(backup.id)}
                        disabled={loading}
                      >
                        <DeleteIcon />
                      </IconButton>
                    </ListItemSecondaryAction>
                  </ListItem>
                ))}
              </List>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Dialog Nouvelle Sauvegarde */}
      <Dialog 
        open={openBackupDialog} 
        onClose={() => setOpenBackupDialog(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          Nouvelle Sauvegarde
        </DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            label="Nom de la sauvegarde"
            value={backupName}
            onChange={(e) => setBackupName(e.target.value)}
            sx={{ mt: 2 }}
            placeholder="backup_manuel_20250306"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenBackupDialog(false)}>
            Annuler
          </Button>
          <Button 
            variant="contained"
            onClick={handleCreateBackup}
            disabled={!backupName}
          >
            Créer
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default MaintenancePage;
