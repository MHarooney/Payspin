import React, { useEffect, useState } from 'react';
import {
  Typography,
  Box,
  Card,
  CardContent,
  Grid,
  Chip,
  Avatar,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  Divider,
} from '@mui/material';
import { useParams } from 'react-router-dom';
import { firebaseService } from '../services/firebase';
import LoadingSpinner from '../components/Common/LoadingSpinner';
import { Circle } from '../types/firestore';
import { PayspinColors } from '../theme/theme';
import { Timestamp, DocumentReference } from 'firebase/firestore';

// Helper function to convert Firestore Timestamp to Date
const convertTimestamp = (timestamp: unknown): Date | null => {
  if (!timestamp) return null;
  if (timestamp instanceof Date) return timestamp;
  if (timestamp instanceof Timestamp) return timestamp.toDate();
  if (typeof timestamp === 'object' && timestamp !== null) {
    // Handle raw Firestore timestamp object
    const ts = timestamp as { seconds: number; nanoseconds: number };
    if ('seconds' in ts && 'nanoseconds' in ts) {
      return new Date(ts.seconds * 1000 + ts.nanoseconds / 1000000);
    }
  }
  if (typeof timestamp === 'string') {
    const date = new Date(timestamp);
    return isNaN(date.getTime()) ? null : date;
  }
  return null;
};

// Helper function to get ID from DocumentReference
const getRefId = (ref: DocumentReference | null | undefined): string | null => {
  if (!ref) return null;
  try {
    if (ref instanceof DocumentReference) {
      return ref.id;
    }
    return null;
  } catch (error) {
    console.error('Error getting reference ID:', error);
    return null;
  }
};

interface CircleUser {
  id?: string;
  name?: string;
  turn?: number;
  role?: string;
  [key: string]: any;
}

interface CleanCircle extends Omit<Circle, 'startdate' | 'endDate' | 'RealUsers'> {
  adminId: string | null;
  notificationId: string | null;
  startDate: Date | null;
  endDate: Date | null;
  RealUsers: CircleUser[];
}

export const CircleDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const [circle, setCircle] = useState<CleanCircle | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchCircleDetails = async () => {
      if (!id) {
        setError('Circle ID is required');
        setLoading(false);
        return;
      }

      try {
        const circleData = await firebaseService.circles.getById(id);
        if (!circleData) {
          setError('Circle not found');
          setLoading(false);
          return;
        }

        // Clean the circle data to handle Firestore references
        const cleanCircle: CleanCircle = {
          ...circleData,
          // Convert admin reference to ID
          adminId: getRefId(circleData.adminDocRef),
          // Convert notification reference to ID
          notificationId: getRefId(circleData.adminNotificationRef),
          // Clean dates
          startDate: convertTimestamp(circleData.startdate),
          endDate: convertTimestamp(circleData.endDate),
          // Clean arrays
          generatedUsers: Array.isArray(circleData.generatedUsers) ? 
            circleData.generatedUsers.map((user: any) => typeof user === 'object' ? { ...user } : user) : [],
          roles: Array.isArray(circleData.roles) ?
            circleData.roles.map((role: any) => typeof role === 'object' ? { ...role } : role) : [],
          RealUsers: Array.isArray(circleData.RealUsers) ?
            circleData.RealUsers.map((user: any) => typeof user === 'object' ? { ...user } : user) : []
        };

        setCircle(cleanCircle);
      } catch (err) {
        console.error('Error fetching circle details:', err);
        setError('Failed to load circle details');
      } finally {
        setLoading(false);
      }
    };

    fetchCircleDetails();
  }, [id]);

  if (loading) {
    return <LoadingSpinner message="Loading circle details..." />;
  }

  if (error || !circle) {
    return (
      <Box sx={{ p: 3 }}>
        <Typography color="error">{error || 'No circle data available'}</Typography>
      </Box>
    );
  }

  const formatDate = (date: Date | null): string => {
    if (!date) return 'Not set';
    return date.toLocaleDateString();
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        Circle Details
      </Typography>

      <Grid container spacing={3}>
        {/* Basic Information */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Basic Information
              </Typography>
              <Box sx={{ mb: 2 }}>
                <Typography variant="subtitle2" color="text.secondary">
                  Circle Name
                </Typography>
                <Typography variant="body1">{circle.name}</Typography>
              </Box>
              <Box sx={{ mb: 2 }}>
                <Typography variant="subtitle2" color="text.secondary">
                  Circle ID
                </Typography>
                <Typography variant="body1">{circle.circle_id}</Typography>
              </Box>
              <Box sx={{ mb: 2 }}>
                <Typography variant="subtitle2" color="text.secondary">
                  Status
                </Typography>
                <Chip
                  label={circle.finished ? 'Completed' : 'Active'}
                  color={circle.finished ? 'success' : 'primary'}
                  size="small"
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Payment Information */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Payment Information
              </Typography>
              <Box sx={{ mb: 2 }}>
                <Typography variant="subtitle2" color="text.secondary">
                  Payment per Month
                </Typography>
                <Typography variant="body1">
                  ${circle.payment_per_month?.toLocaleString() || 0}
                </Typography>
              </Box>
              <Box sx={{ mb: 2 }}>
                <Typography variant="subtitle2" color="text.secondary">
                  Duration
                </Typography>
                <Typography variant="body1">{circle.months} months</Typography>
              </Box>
              <Box sx={{ mb: 2 }}>
                <Typography variant="subtitle2" color="text.secondary">
                  Period
                </Typography>
                <Typography variant="body1">
                  {formatDate(circle.startDate)} - {formatDate(circle.endDate)}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Members List */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Members
              </Typography>
              <List>
                {circle.RealUsers?.map((user, index) => (
                  <React.Fragment key={user.id || index}>
                    <ListItem>
                      <ListItemAvatar>
                        <Avatar>{user.name?.[0]?.toUpperCase() || 'U'}</Avatar>
                      </ListItemAvatar>
                      <ListItemText
                        primary={user.name || 'Unknown User'}
                        secondary={`Turn: ${user.turn || 'Not assigned'}`}
                      />
                      <Chip
                        label={`Role: ${user.role || 'Member'}`}
                        size="small"
                        color="primary"
                      />
                    </ListItem>
                    {index < (circle.RealUsers?.length || 0) - 1 && <Divider />}
                  </React.Fragment>
                ))}
                {(!circle.RealUsers || circle.RealUsers.length === 0) && (
                  <Typography variant="body2" color="text.secondary" textAlign="center" py={2}>
                    No members in this circle
                  </Typography>
                )}
              </List>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}; 