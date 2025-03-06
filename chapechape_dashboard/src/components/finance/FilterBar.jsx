import React from 'react';
import {
  Card,
  CardContent,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  TextField,
  Button,
} from '@mui/material';
import {
  Search as SearchIcon,
  FilterList as FilterIcon,
} from '@mui/icons-material';
import PropTypes from 'prop-types';
import { financeService } from '../../services/financeService';

const FilterBar = ({
  searchTerm,
  onSearchChange,
  filters,
  onFiltersChange,
  onApplyFilters,
  loading,
}) => {
  const handleFilterChange = (field) => (event) => {
    onFiltersChange({
      ...filters,
      [field]: event.target.value,
    });
  };

  return (
    <Card sx={{ mb: 4 }}>
      <CardContent>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={4}>
            <TextField
              fullWidth
              label="Rechercher"
              value={searchTerm}
              onChange={(e) => onSearchChange(e.target.value)}
              InputProps={{
                startAdornment: <SearchIcon sx={{ color: 'action.active', mr: 1 }} />,
              }}
            />
          </Grid>
          <Grid item xs={12} sm={3}>
            <FormControl fullWidth>
              <InputLabel>Statut</InputLabel>
              <Select
                value={filters.status}
                onChange={handleFilterChange('status')}
                label="Statut"
              >
                <MenuItem value="">Tous</MenuItem>
                {Object.entries(financeService.getPaymentStatuses()).map(([key, { label }]) => (
                  <MenuItem key={key} value={key}>{label}</MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={3}>
            <FormControl fullWidth>
              <InputLabel>Méthode de paiement</InputLabel>
              <Select
                value={filters.paymentMethod}
                onChange={handleFilterChange('paymentMethod')}
                label="Méthode de paiement"
              >
                <MenuItem value="">Toutes</MenuItem>
                {financeService.getPaymentMethods().map(method => (
                  <MenuItem key={method.id} value={method.id}>{method.name}</MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={2}>
            <Button
              fullWidth
              variant="contained"
              startIcon={<FilterIcon />}
              onClick={onApplyFilters}
              disabled={loading}
            >
              Filtrer
            </Button>
          </Grid>
        </Grid>
      </CardContent>
    </Card>
  );
};

FilterBar.propTypes = {
  searchTerm: PropTypes.string.isRequired,
  onSearchChange: PropTypes.func.isRequired,
  filters: PropTypes.shape({
    status: PropTypes.string,
    paymentMethod: PropTypes.string,
    startDate: PropTypes.string,
    endDate: PropTypes.string,
  }).isRequired,
  onFiltersChange: PropTypes.func.isRequired,
  onApplyFilters: PropTypes.func.isRequired,
  loading: PropTypes.bool,
};

FilterBar.defaultProps = {
  loading: false,
};

export default FilterBar;
