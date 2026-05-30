import React from 'react';
import { Typography, Box } from '@mui/material';

export const PaymentMethods: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Payment Methods
      </Typography>
      <Typography variant="body1">
        Manage payment methods and configurations
      </Typography>
    </Box>
  );
}; 