# Payspin Admin Portal

A comprehensive admin portal for managing the Payspin mobile application platform. Built with React, TypeScript, Material-UI, and Firebase.

## 🚀 Features

### 📊 Dashboard & Analytics
- Real-time statistics and metrics
- User activity monitoring
- Circle performance tracking
- Financial volume tracking
- Completion rate analysis

### 👥 User Management
- View all registered users
- Manage user roles and permissions
- Track user activity and engagement
- User status management (active/inactive)

### 🔄 Circle Management
- Monitor all payment circles
- Track circle progress and turns
- Manage participants and payments
- Circle analytics and reporting

### 📝 Content Management
- Blog post creation and management
- News and announcements
- Content categorization and tagging
- SEO optimization tools

### 📱 Communication
- Push notification management
- In-app messaging
- Announcement broadcasting
- User engagement tracking

### 💰 Financial Management
- Payment method configuration
- Transaction monitoring
- Payout management
- Financial reporting

## 🏗️ Architecture

### Clean Architecture & SOLID Principles
The project follows clean architecture principles with clear separation of concerns:

```
src/
├── components/           # Reusable UI components
│   ├── Common/          # Shared components
│   ├── Layout/          # Layout components
│   └── Auth/            # Authentication components
├── contexts/            # React contexts for state management
├── pages/               # Page components
├── services/            # Business logic and API services
│   └── firebase/        # Firebase service layer
│       ├── repositories/# Data access layer
│       └── BaseRepository.ts
├── theme/               # Material-UI theme configuration
├── types/               # TypeScript type definitions
└── config/              # Configuration files
```

### Service Layer (Repository Pattern)
- **BaseRepository**: Abstract base class for common CRUD operations
- **UserRepository**: User-specific operations
- **CircleRepository**: Circle and circle user management
- **BlogRepository**: Content management operations
- **NewsRepository**: News and announcements
- **NotificationRepository**: Notification management

### Design System
- **Payspin Brand Colors**: Custom color palette with gradient support
- **Typography**: Raleway (headings) + Inter (body text)
- **Material-UI Theme**: Custom theme with Payspin branding
- **Responsive Design**: Mobile-first responsive layout

## 🛠️ Technology Stack

- **Frontend**: React 18 + TypeScript
- **UI Framework**: Material-UI (MUI) v5
- **Backend**: Firebase (Firestore, Auth, Storage)
- **State Management**: React Context API
- **Routing**: React Router v6
- **Forms**: React Hook Form + Yup validation
- **Notifications**: React Hot Toast
- **Charts**: Chart.js + React Chart.js 2
- **Development**: Create React App

## 📋 Prerequisites

- Node.js 18+ and npm
- Firebase project with Firestore enabled
- Firebase CLI installed and authenticated

## 🚀 Getting Started

### 1. Firebase Setup

First, ensure you have Firebase CLI authenticated:

```bash
npx firebase-tools@latest login --reauth
```

### 2. Project Installation

```bash
# Clone or navigate to the project
cd admin-portal

# Install dependencies
npm install
```

### 3. Environment Configuration

Create a `.env.local` file in the root directory:

```env
# Firebase Configuration
REACT_APP_FIREBASE_API_KEY=your_api_key_here
REACT_APP_FIREBASE_AUTH_DOMAIN=payspin-app.firebaseapp.com
REACT_APP_FIREBASE_PROJECT_ID=payspin-app
REACT_APP_FIREBASE_STORAGE_BUCKET=payspin-app.appspot.com
REACT_APP_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
REACT_APP_FIREBASE_APP_ID=your_app_id
```

### 4. Firebase Project Configuration

The admin portal is configured to work with the `payspin-app` Firebase project. Ensure your Firebase project has:

- **Firestore Database** enabled
- **Authentication** configured
- **Storage** enabled (optional)
- **Security Rules** properly configured

### 5. Start Development Server

```bash
npm start
```

The application will open at `http://localhost:3000`

## 🔐 Authentication

### Admin Access
Only users with `admin` or `moderator` roles can access the admin portal. The authentication system:

1. Checks Firebase Authentication status
2. Verifies user document exists in Firestore
3. Validates user role permissions
4. Redirects unauthorized users to login

### Demo Credentials
```
Email: payspin.app@gmail.com
Password: Payspin@2023
```

## 📱 Firestore Database Structure

The admin portal works with the following Firestore collections:

### Core Collections
- **users**: User profiles and authentication data
- **circles**: Payment circles and group information
- **circleUsers**: Circle participants (subcollection)
- **blogs**: Blog posts and content
- **News**: Announcements and updates
- **notifications**: Push notifications
- **offers**: Promotional offers
- **payment_methods**: Payment configuration
- **Circle_Payouts**: Payout transactions

### Data Models
All data models are fully typed with TypeScript interfaces in `src/types/firestore.ts`

## 🎨 Design System

### Brand Colors
```typescript
export const PayspinColors = {
  primary: '#07D8DD',      // Turquoise
  secondary: '#FC00FF',    // Magenta
  purple: '#8E0FF2',       // Purple
  blue: '#5C7AEA',         // Blue
  yellow: '#FFC408',       // Yellow
  gradient: 'linear-gradient(90deg, #FC00FF 0%, #07D8DD 50%)',
};
```

### Typography
- **Primary Font**: Raleway (headings, buttons)
- **Secondary Font**: Inter (body text, captions)
- **Font Weights**: 300-900 available

### Components
- Custom Material-UI theme
- Gradient button support
- Responsive grid system
- Loading states and animations

## 📊 Dashboard Features

### Statistics Cards
- Total Users with growth trends
- Active Circles monitoring
- Financial volume tracking
- Completion rate metrics

### Recent Activity
- User registrations
- Circle creations
- Content updates
- System events

### Quick Actions
- User management shortcuts
- Circle creation tools
- Content publishing
- Notification sending

## 🔧 Development

### Available Scripts
```bash
npm start          # Start development server
npm test           # Run tests
npm run build      # Build for production
npm run eject      # Eject from Create React App
```

### Code Structure
- **Components**: Functional components with TypeScript
- **Hooks**: Custom hooks for data fetching and state management
- **Services**: Business logic separated from UI components
- **Types**: Comprehensive TypeScript definitions

### Best Practices
- SOLID principles implementation
- Repository pattern for data access
- Component composition over inheritance
- Responsive design patterns
- Error boundary implementation

## 🚀 Deployment

### Build for Production
```bash
npm run build
```

### Firebase Hosting (Recommended)
```bash
# Initialize Firebase hosting
firebase init hosting

# Deploy to Firebase
firebase deploy --only hosting
```

### Other Deployment Options
- Vercel
- Netlify
- AWS S3 + CloudFront
- Docker containerization

## 🛡️ Security

### Authentication
- Firebase Authentication integration
- Role-based access control
- Session management
- Automatic token refresh

### Data Security
- Firestore Security Rules enforced
- Input validation and sanitization
- XSS protection
- CSRF protection

## 📈 Performance

### Optimization Features
- Code splitting with React.lazy
- Image optimization
- Bundle size optimization
- Memoization for expensive operations
- Efficient re-rendering patterns

### Monitoring
- Real-time error tracking
- Performance metrics
- User analytics
- System health monitoring

## 🤝 Contributing

1. Follow the established code structure
2. Use TypeScript for all new code
3. Follow Material-UI design patterns
4. Implement proper error handling
5. Add comprehensive documentation

## 📄 License

This project is part of the Payspin platform. All rights reserved.

## 🆘 Support

For technical support or questions:
- Review the Firestore security rules
- Check the Firebase Console for errors
- Verify environment configuration
- Check browser console for client-side errors

---

**Built with ❤️ for the Payspin platform**
