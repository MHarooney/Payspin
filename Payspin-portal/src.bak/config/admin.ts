export const ADMIN_EMAIL = 'payspin.app@gmail.com';

// This is used only for validation, not for storing the actual password
export const validateAdminCredentials = (email: string, password: string) => {
  return email === ADMIN_EMAIL;
}; 