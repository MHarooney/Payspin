import React, { useState } from 'react';
import {
  Box,
  TextField,
  Button,
  Typography,
  Paper,
  Switch,
  FormControlLabel,
  Alert,
  Snackbar
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import { getFirestore, collection, addDoc } from 'firebase/firestore';
import { getMessaging, getToken } from 'firebase/messaging';

interface Announcement {
  title: string;
  content: string;
  sendPushNotification: boolean;
  publishDate: Date;
  author: string;
  status: 'draft' | 'published';
}

const NewsEditor: React.FC = () => {
  const navigate = useNavigate();
  const [announcement, setAnnouncement] = useState<Announcement>({
    title: '',
    content: '',
    sendPushNotification: false,
    publishDate: new Date(),
    author: 'Admin',
    status: 'draft'
  });
  const [snackbar, setSnackbar] = useState({
    open: false,
    message: '',
    severity: 'success' as 'success' | 'error'
  });

  const handleTitleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setAnnouncement({ ...announcement, title: event.target.value });
  };

  const handleContentChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setAnnouncement({ ...announcement, content: event.target.value });
  };

  const handlePushNotificationChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setAnnouncement({ ...announcement, sendPushNotification: event.target.checked });
  };

  const sendPushNotification = async () => {
    try {
      const messaging = getMessaging();
      const token = await getToken(messaging);
      
      // Here you would typically send this token to your server
      // which would then use FCM to send the actual notification
      console.log('FCM Token:', token);
      
      return true;
    } catch (error) {
      console.error('Error sending push notification:', error);
      return false;
    }
  };

  const handleSave = async (status: 'draft' | 'published') => {
    try {
      const db = getFirestore();
      const announcementData = {
        ...announcement,
        status,
        publishDate: new Date().toISOString()
      };

      await addDoc(collection(db, 'announcements'), announcementData);

      if (status === 'published' && announcement.sendPushNotification) {
        const notificationSent = await sendPushNotification();
        if (!notificationSent) {
          setSnackbar({
            open: true,
            message: 'Announcement saved but push notification failed',
            severity: 'error'
          });
          return;
        }
      }

      setSnackbar({
        open: true,
        message: `Announcement ${status === 'published' ? 'published' : 'saved as draft'} successfully`,
        severity: 'success'
      });

      setTimeout(() => {
        navigate('/news');
      }, 2000);
    } catch (error) {
      console.error('Error saving announcement:', error);
      setSnackbar({
        open: true,
        message: 'Error saving announcement',
        severity: 'error'
      });
    }
  };

  return (
    <Box sx={{ maxWidth: 1200, margin: '0 auto', p: 3 }}>
      <Paper elevation={3} sx={{ p: 3 }}>
        <Typography variant="h4" gutterBottom>
          Create New Announcement
        </Typography>
        
        <TextField
          fullWidth
          label="Title"
          variant="outlined"
          value={announcement.title}
          onChange={handleTitleChange}
          sx={{ mb: 3 }}
        />

        <TextField
          fullWidth
          label="Content"
          variant="outlined"
          multiline
          rows={6}
          value={announcement.content}
          onChange={handleContentChange}
          sx={{ mb: 3 }}
        />

        <FormControlLabel
          control={
            <Switch
              checked={announcement.sendPushNotification}
              onChange={handlePushNotificationChange}
              color="primary"
            />
          }
          label="Send Push Notification"
          sx={{ mb: 3 }}
        />

        <Box sx={{ display: 'flex', gap: 2, justifyContent: 'flex-end' }}>
          <Button
            variant="outlined"
            onClick={() => navigate('/news')}
          >
            Cancel
          </Button>
          <Button
            variant="outlined"
            onClick={() => handleSave('draft')}
          >
            Save as Draft
          </Button>
          <Button
            variant="contained"
            onClick={() => handleSave('published')}
            sx={{
              background: 'linear-gradient(45deg, #07D8DD 30%, #FC00FF 90%)',
              color: 'white',
            }}
          >
            Publish
          </Button>
        </Box>
      </Paper>

      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
      >
        <Alert
          onClose={() => setSnackbar({ ...snackbar, open: false })}
          severity={snackbar.severity}
          sx={{ width: '100%' }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default NewsEditor; 