import React from 'react';
import { Chip, CircularProgress } from '@mui/material';
import {
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
  MoneyOff as MoneyOffIcon,
  Pending as PendingIcon,
  Sync as SyncIcon,
} from '@mui/icons-material';
import PropTypes from 'prop-types';

const statusConfig = {
  pending: {
    label: 'En attente',
    color: 'warning',
    icon: PendingIcon,
  },
  processing: {
    label: 'En cours',
    color: 'info',
    icon: SyncIcon,
  },
  completed: {
    label: 'Complété',
    color: 'success',
    icon: CheckCircleIcon,
  },
  failed: {
    label: 'Échoué',
    color: 'error',
    icon: CancelIcon,
  },
  refunded: {
    label: 'Remboursé',
    color: 'default',
    icon: MoneyOffIcon,
  },
  cancelled: {
    label: 'Annulé',
    color: 'default',
    icon: CancelIcon,
  },
};

const StatusChip = ({ status, size = 'small', className }) => {
  const config = statusConfig[status] || statusConfig.pending;
  const Icon = config.icon;

  return (
    <Chip
      icon={status === 'processing' ? <CircularProgress size={16} /> : <Icon />}
      label={config.label}
      color={config.color}
      size={size}
      className={className}
    />
  );
};

StatusChip.propTypes = {
  status: PropTypes.oneOf(Object.keys(statusConfig)).isRequired,
  size: PropTypes.oneOf(['small', 'medium']),
  className: PropTypes.string,
};

export default StatusChip;
