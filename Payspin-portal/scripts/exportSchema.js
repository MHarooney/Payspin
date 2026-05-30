const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin with the service account key file
const serviceAccount = require('../payspin-app-firebase-adminsdk-2cr3x-a05132e637.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://payspin-app-default-rtdb.europe-west1.firebasedatabase.app"
});

const db = admin.firestore();

async function getCollectionSchema(collectionRef, schema = {}, depth = 0) {
  if (depth > 3) return schema; // Prevent infinite recursion
  
  console.log(`Analyzing collection: ${collectionRef.path}`);
  const snapshot = await collectionRef.limit(100).get();
  
  for (const doc of snapshot.docs) {
    const data = doc.data();
    
    // Get subcollections for this document
    const subcollections = await doc.ref.listCollections();
    
    // Process main document data
    Object.entries(data).forEach(([field, value]) => {
      if (!schema[field]) {
        schema[field] = new Set();
      }
      
      // Handle different types of values
      if (value === null) {
        schema[field].add('null');
      } else if (Array.isArray(value)) {
        schema[field].add('array');
        // Check array contents if not empty
        if (value.length > 0) {
          const itemType = typeof value[0];
          schema[field].add(`array<${itemType}>`);
        }
      } else if (value instanceof admin.firestore.Timestamp) {
        schema[field].add('timestamp');
      } else if (value instanceof admin.firestore.DocumentReference) {
        schema[field].add('reference');
        schema[field].add(`reference<${value.path}>`);
      } else if (typeof value === 'object') {
        schema[field].add('object');
        // Process nested object fields
        Object.entries(value).forEach(([nestedField, nestedValue]) => {
          const fullPath = `${field}.${nestedField}`;
          if (!schema[fullPath]) {
            schema[fullPath] = new Set();
          }
          schema[fullPath].add(typeof nestedValue);
        });
      } else {
        schema[field].add(typeof value);
      }
    });
    
    // Process subcollections recursively
    for (const subcoll of subcollections) {
      const subcollName = `${collectionRef.path}/${doc.id}/${subcoll.id}`;
      console.log(`Found subcollection: ${subcollName}`);
      schema[`${subcollName} (subcollection)`] = await getCollectionSchema(subcoll, {}, depth + 1);
    }
  }
  
  return schema;
}

async function exportSchema() {
  const collections = ['users', 'circles', 'circleUsers', 'notification', 'fcm_tokens'];
  const schema = {};
  
  for (const collection of collections) {
    console.log(`\nProcessing root collection: ${collection}`);
    const collectionRef = db.collection(collection);
    schema[collection] = await getCollectionSchema(collectionRef);
  }
  
  // Convert Sets to Arrays for JSON serialization
  const processSchema = (obj) => {
    if (obj instanceof Set) {
      return Array.from(obj);
    }
    if (typeof obj === 'object' && obj !== null) {
      return Object.fromEntries(
        Object.entries(obj).map(([key, value]) => [key, processSchema(value)])
      );
    }
    return obj;
  };
  
  const processedSchema = processSchema(schema);
  
  fs.writeFileSync('firestore-schema.json', JSON.stringify(processedSchema, null, 2));
  console.log('\nSchema exported to firestore-schema.json');
  process.exit(0);
}

exportSchema().catch(error => {
  console.error('Error exporting schema:', error);
  process.exit(1);
}); 