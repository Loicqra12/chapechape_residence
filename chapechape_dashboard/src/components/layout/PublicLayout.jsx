import React from 'react';
import { Outlet } from 'react-router-dom';
import { AppBar, Toolbar, Typography, Button, Container } from '@mui/material';
import { Link as RouterLink } from 'react-router-dom';

const PublicLayout = () => {
  return (
    <>
      <AppBar position="fixed" sx={{ background: 'linear-gradient(to right, #1A237E, #283593)' }}>
        <Toolbar>
          <Typography variant="h6" component={RouterLink} to="/" sx={{ flexGrow: 1, textDecoration: 'none', color: 'white' }}>
            ChapeChape Residence
          </Typography>
          <Button color="inherit" component={RouterLink} to="/properties">
            Résidences
          </Button>
          <Button color="inherit" component={RouterLink} to="/contact">
            Contact
          </Button>
          <Button color="inherit" component={RouterLink} to="/admin/login">
            Espace Admin
          </Button>
        </Toolbar>
      </AppBar>
      <Container sx={{ mt: 10, mb: 4 }}>
        <Outlet />
      </Container>
    </>
  );
};

export default PublicLayout;
