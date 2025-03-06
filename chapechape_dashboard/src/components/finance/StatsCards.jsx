import React from 'react';
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
} from '@mui/material';
import {
  TrendingUp as TrendingUpIcon,
  AccountBalance as AccountBalanceIcon,
  CheckCircle as CheckCircleIcon,
  MoneyOff as MoneyOffIcon,
} from '@mui/icons-material';
import PropTypes from 'prop-types';

const formatCurrency = (amount) => {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'XOF'
  }).format(amount);
};

const StatsCard = ({ title, value, icon: Icon, isMonetary }) => (
  <Grid item xs={12} sm={6} md={3}>
    <Card>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
          <Icon sx={{ color: 'primary.main', mr: 1 }} />
          <Typography variant="subtitle2" color="text.secondary">
            {title}
          </Typography>
        </Box>
        <Typography variant="h4">
          {isMonetary ? formatCurrency(value) : value}
        </Typography>
      </CardContent>
    </Card>
  </Grid>
);

StatsCard.propTypes = {
  title: PropTypes.string.isRequired,
  value: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  icon: PropTypes.elementType.isRequired,
  isMonetary: PropTypes.bool,
};

const StatsCards = ({ stats }) => {
  if (!stats) return null;

  const cards = [
    {
      title: 'Chiffre d\'affaires',
      value: stats.totalRevenue || stats.totalVolume || 0,
      icon: AccountBalanceIcon,
      isMonetary: true,
    },
    {
      title: 'Transactions du jour',
      value: stats.todayTransactions || 0,
      icon: TrendingUpIcon,
      isMonetary: false,
    },
    {
      title: 'Taux de réussite',
      value: `${stats.successRate || 0}%`,
      icon: CheckCircleIcon,
      isMonetary: false,
    },
    {
      title: 'Remboursements',
      value: stats.refundAmount || 0,
      icon: MoneyOffIcon,
      isMonetary: true,
    },
  ];

  return (
    <Grid container spacing={3} sx={{ mb: 4 }}>
      {cards.map((card, index) => (
        <StatsCard key={index} {...card} />
      ))}
    </Grid>
  );
};

StatsCards.propTypes = {
  stats: PropTypes.shape({
    totalRevenue: PropTypes.number,
    totalVolume: PropTypes.number,
    todayTransactions: PropTypes.number,
    successRate: PropTypes.number,
    refundAmount: PropTypes.number,
  }),
};

export default StatsCards;
