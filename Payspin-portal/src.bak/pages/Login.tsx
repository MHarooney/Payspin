import React, { useState } from 'react';
import {
  Box,
  Paper,
  TextField,
  Button,
  Typography,
  Alert,
  CircularProgress
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import { getAuth, signInWithEmailAndPassword } from 'firebase/auth';
import { getFirestore, doc, getDoc } from 'firebase/firestore';
import Logo from '../assets/Logo_Gradient-01.png';
import { ADMIN_EMAIL, validateAdminCredentials } from '../config/admin';

const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    // Validate if it's the admin email
    if (!validateAdminCredentials(email, password)) {
      setError('Access denied. Invalid credentials.');
      setLoading(false);
      return;
    }

    try {
      const auth = getAuth();
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      
      // Additional check in Firestore for admin role
      const db = getFirestore();
      const userDoc = await getDoc(doc(db, 'admin_users', userCredential.user.uid));
      
      if (!userDoc.exists() || userDoc.data()?.role !== 'admin') {
        // If not admin, sign out and show error
        await auth.signOut();
        setError('Access denied. Insufficient privileges.');
        setLoading(false);
        return;
      }

      navigate('/dashboard');
    } catch (error: any) {
      setError('Invalid credentials');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box
      sx={{
        height: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'linear-gradient(45deg, #07D8DD 30%, #FC00FF 90%)',
      }}
    >
      <Paper
        elevation={3}
        sx={{
          p: 4,
          width: '100%',
          maxWidth: 400,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        <img
          src={Logo}
          alt="Payspin Logo"
          style={{
            width: '200px',
            marginBottom: '2rem',
          }}
        />

        <Typography variant="h5" component="h1" gutterBottom>
          Admin Login
        </Typography>

        {error && (
          <Alert severity="error" sx={{ width: '100%', mb: 2 }}>
            {error}
          </Alert>
        )}

        <Box component="form" onSubmit={handleLogin} sx={{ width: '100%' }}>
          <TextField
            fullWidth
            label="Email"
            variant="outlined"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            margin="normal"
            required
            inputProps={{
              autoComplete: 'username',
            }}
          />

          <TextField
            fullWidth
            label="Password"
            variant="outlined"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            margin="normal"
            required
            inputProps={{
              autoComplete: 'current-password',
            }}
          />

          <Button
            type="submit"
            fullWidth
            variant="contained"
            sx={{
              mt: 3,
              mb: 2,
              background: 'linear-gradient(45deg, #07D8DD 30%, #FC00FF 90%)',
              color: 'white',
              '&:hover': {
                background: 'linear-gradient(45deg, #06C2C7 30%, #E300E6 90%)',
              },
            }}
            disabled={loading}
          >
            {loading ? <CircularProgress size={24} /> : 'Login'}
          </Button>
        </Box>
      </Paper>
    </Box>
  );
};

export default Login; 