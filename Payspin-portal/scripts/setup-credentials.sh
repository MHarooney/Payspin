#!/bin/bash

# Create the credentials file
cat > firebase-credentials.json << EOL
{
  "type": "service_account",
  "project_id": "payspin-app",
  "private_key_id": "",
  "private_key": "",
  "client_email": "firebase-adminsdk-2cr3x@payspin-app.iam.gserviceaccount.com",
  "client_id": "",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-2cr3x%40payspin-app.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
EOL

# Set the environment variable
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/firebase-credentials.json"

echo "Please add your private_key_id and private_key to firebase-credentials.json"
echo "Then you can run: node exportSchema.js" 