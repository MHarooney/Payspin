import React from 'react';
import { Add as AddIcon } from '@mui/icons-material';
import { GradientButton } from '../Common/GradientButton';

interface CreateUserButtonProps {
  onClick: () => void;
  disabled?: boolean;
  loading?: boolean;
}

export const CreateUserButton: React.FC<CreateUserButtonProps> = ({
  onClick,
  disabled = false,
  loading = false,
}) => {
  return (
    <GradientButton
      onClick={onClick}
      disabled={disabled}
      loading={loading}
      text="Create User"
      startIcon={<AddIcon />}
      size="large"
      variant="primary"
    />
  );
}; 