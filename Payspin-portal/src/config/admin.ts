import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const serviceAccount = {
  type: "service_account",
  project_id: "payspin-app",
  private_key_id: "a05132e63774ace1e5bf6562e54e648041c76ea0",
  private_key: "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDUjI1Rg07Y6b6k\nkRyIlKUPwfBbv7kOR+wEsGbyCfts3pQuxpLH6qR5zwh3hUtmjrGyayR4q8tXBAaz\n+oM3s40s9y+W7Wp+1Y6mz/fq8WosgxZeVNsByhmsTBwGrUvo49U+MMUP/gP0dcZj\nyQR62uMhQfRBGGG76mLjcsy18viqglF/ChxbBTVJbx2ravfXrhnI9FRStVUF3RDY\nIjARG5CZtnoJvC5J5In/993e/egmUaUekbAt8N6wCD+f9WvMtCcZQPVaDyinXFGg\nxjDFkgWJlNU2/U56N3JPN4KkmLXDicO2rymXLW21xYi5SVgmeH/BW0L1lEv5zV/T\nESnpBHS3AgMBAAECggEAArQMPlwlDrPL4uJAs6KOSFT46Gi4/qDU5N3kDJv+aN6a\nZcaGQs6huMwPHJhkSk1GIxCaYGf52gLm8VY0UD8IWuSfHXwl/Qf7p5xHSsj5XQVB\n3j8rzQSPYa+0ICt5+qr7Svlarp/1HtD19/pYYPK9b9zVG5Qm/3LNazZb3iTDrTN6\nCfJEdkIGT3ozO6bxcoI4cjjU59z+c6MaqQPFAvdx+iWkZi27tGc3OVKWgjgw/yB5\nmT4cccZJI90MZWFrdyO2Zy64BZpAjZrb4ur6T8Cpwfc5u63+lS0SUiiD3n4/iSN8\n3Xi2Ugefk8WApZEJA824V6ILvKbSbjJDnaiAxc485QKBgQDyPIMXzBMknyXAhxxm\nPXNYYCF7HfoNSjj2XUoMF8ORENPBzOzFH//D5bDbXraw4alXcyZfpI9R1HiebcfB\n7Ny1ugN1PRdTFOGyqd4zNpbDWH3rqSlVYkJMdoMm81lomsIxIi9FF9KFGz43QfVz\nD/DK/1nk6Euu3EYfMFyY9ctwqwKBgQDgoDfKpu6WFu6HE/8OYRLhTKQ+GxXppg5k\n58424pDvMmoKxuxZJVqDJIoGjuPTefEg/tGizq8KfsMBD/FYQuSttk9fbWYItyjt\nmrLvfLBVJBr4kZo8zK4mVPiuEt3evsg9Fv0KmiJ7J/j9kVnekkWjygvQA60CEcQZ\nkzOKp4+EJQKBgQDAQ5lFXRvgmFTNkC/RUnrnrT1FzBA5Vi0KFhd8q6v0yydYDj/r\nYi+OHBQYuf9FO4c+Os49YY7Dw2GNVdMUL90qfB7cggWuUselGECd43kcSXOAhb6h\n36CBshr84m+XoCX7+4cLTxIvxeTG1RptHjzf0ndWQa44dutNPARy/7xeiwKBgQCB\nDsy/XIX8KhTF+1Ex28hTNguvuzQt2ECw7RZoJmiLZfXTV1N4LKQCcT30Yqi3WnqW\nMJIV7pZXe1ljBNvvkA9/Vx3ngB19qG6VhaqFOqi9Yk80vcNWZ2svjuaKbUCYuBio\nMMsWClUBWYgPeDGgVX45it6al2IRrE91OkQEyB0HGQKBgAyoHrvsXGJ5h5av+raK\nz2UWEaF0G2vknAgfZS0JAqyRgZ4qJmvJoksVzWAUIHXBeln4krX8GlC6aB8lm65P\nOEfaCRaehyVoK9XW7MFF3Blv6ef0LiWoPse2Srze6b+Tv7eCwtRXgTzBcdDiglHj\n/VQ7Zp+t66pl2hkhZa8IB6Km\n-----END PRIVATE KEY-----\n",
  client_email: "firebase-adminsdk-2cr3x@payspin-app.iam.gserviceaccount.com",
  client_id: "103808866427727635763",
  auth_uri: "https://accounts.google.com/o/oauth2/auth",
  token_uri: "https://oauth2.googleapis.com/token",
  auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
  client_x509_cert_url: "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-2cr3x%40payspin-app.iam.gserviceaccount.com",
  universe_domain: "googleapis.com"
} as const;

// Initialize Firebase Admin
const app = initializeApp({
  credential: cert(serviceAccount as any), // Type assertion needed due to browser environment
  projectId: "payspin-app",
  storageBucket: "payspin-app.appspot.com",
});

// Initialize Firestore
export const adminDb = getFirestore(app);

export default app; 