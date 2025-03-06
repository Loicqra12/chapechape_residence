import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Box,
  Autocomplete,
  Chip,
  IconButton,
  Typography,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from '@mui/material';
import {
  Close as CloseIcon,
  AttachFile as AttachFileIcon,
  Send as SendIcon,
} from '@mui/icons-material';

const ComposeMessage = ({ open, onClose, onSend, recipients = [], replyTo = null }) => {
  const [formData, setFormData] = useState({
    to: replyTo ? [replyTo.sender] : [],
    subject: replyTo ? `Re: ${replyTo.subject}` : '',
    content: '',
    priority: 'normal',
    attachments: []
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    onSend(formData);
    handleClose();
  };

  const handleClose = () => {
    setFormData({
      to: [],
      subject: '',
      content: '',
      priority: 'normal',
      attachments: []
    });
    onClose();
  };

  const handleFileChange = (e) => {
    const files = Array.from(e.target.files);
    setFormData(prev => ({
      ...prev,
      attachments: [...prev.attachments, ...files]
    }));
  };

  const removeAttachment = (index) => {
    setFormData(prev => ({
      ...prev,
      attachments: prev.attachments.filter((_, i) => i !== index)
    }));
  };

  return (
    <Dialog 
      open={open} 
      onClose={handleClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: {
          height: '80vh',
          display: 'flex',
          flexDirection: 'column'
        }
      }}
    >
      <DialogTitle sx={{ m: 0, p: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Typography variant="h6">
          {replyTo ? 'Répondre au message' : 'Nouveau message'}
        </Typography>
        <IconButton
          aria-label="close"
          onClick={handleClose}
          sx={{
            color: (theme) => theme.palette.grey[500],
          }}
        >
          <CloseIcon />
        </IconButton>
      </DialogTitle>

      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', flex: 1 }}>
        <DialogContent dividers sx={{ flex: 1 }}>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            {/* Destinataires */}
            <Autocomplete
              multiple
              options={recipients}
              value={formData.to}
              onChange={(_, newValue) => setFormData(prev => ({ ...prev, to: newValue }))}
              getOptionLabel={(option) => option.name}
              renderInput={(params) => (
                <TextField
                  {...params}
                  label="À"
                  placeholder="Sélectionnez les destinataires"
                />
              )}
              renderTags={(value, getTagProps) =>
                value.map((option, index) => (
                  <Chip
                    key={option._id}
                    label={option.name}
                    {...getTagProps({ index })}
                  />
                ))
              }
            />

            {/* Sujet et Priorité */}
            <Box sx={{ display: 'flex', gap: 2 }}>
              <TextField
                fullWidth
                label="Sujet"
                value={formData.subject}
                onChange={(e) => setFormData(prev => ({ ...prev, subject: e.target.value }))}
              />
              <FormControl sx={{ minWidth: 120 }}>
                <InputLabel>Priorité</InputLabel>
                <Select
                  value={formData.priority}
                  label="Priorité"
                  onChange={(e) => setFormData(prev => ({ ...prev, priority: e.target.value }))}
                >
                  <MenuItem value="low">Basse</MenuItem>
                  <MenuItem value="normal">Normale</MenuItem>
                  <MenuItem value="high">Haute</MenuItem>
                </Select>
              </FormControl>
            </Box>

            {/* Contenu */}
            <TextField
              fullWidth
              multiline
              rows={12}
              label="Message"
              value={formData.content}
              onChange={(e) => setFormData(prev => ({ ...prev, content: e.target.value }))}
            />

            {/* Pièces jointes */}
            <Box>
              <input
                type="file"
                multiple
                onChange={handleFileChange}
                style={{ display: 'none' }}
                id="file-input"
              />
              <label htmlFor="file-input">
                <Button
                  component="span"
                  startIcon={<AttachFileIcon />}
                  variant="outlined"
                >
                  Ajouter des pièces jointes
                </Button>
              </label>

              {formData.attachments.length > 0 && (
                <Box sx={{ mt: 2 }}>
                  <Typography variant="subtitle2" gutterBottom>
                    Pièces jointes ({formData.attachments.length})
                  </Typography>
                  <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                    {formData.attachments.map((file, index) => (
                      <Chip
                        key={index}
                        label={file.name}
                        onDelete={() => removeAttachment(index)}
                        variant="outlined"
                      />
                    ))}
                  </Box>
                </Box>
              )}
            </Box>
          </Box>
        </DialogContent>

        <DialogActions sx={{ p: 2 }}>
          <Button onClick={handleClose}>
            Annuler
          </Button>
          <Button
            type="submit"
            variant="contained"
            startIcon={<SendIcon />}
            disabled={!formData.to.length || !formData.subject || !formData.content}
          >
            Envoyer
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
};

export default ComposeMessage;
