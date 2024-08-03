#!/bin/bash

# Check if the number of arguments passed is exactly 4
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <domain> <record> <ACCESS_KEY> <ACCESS_KEY_ID>"
  exit 1
fi

# Export the domain name and stack name from the passed arguments
export DOMAIN_NAME=$1
export STACK_NAME=$2

# Navigate to the /opt directory
cd /opt

# Clone the LiveKit examples repository
git clone https://github.com/livekit-examples/meet

# Navigate to the cloned repository directory
cd meet

# Copy the example environment file to a local environment file
cp .env.example .env.local

# Set LIVEKIT_API_KEY in .env.local
sed -i 's|LIVEKIT_API_KEY=.*|LIVEKIT_API_KEY='"$3"'|' .env.local

# Set LIVEKIT_API_SECRET in .env.local
sed -i 's|LIVEKIT_API_SECRET=.*|LIVEKIT_API_SECRET='"$4"'|' .env.local

# Set LIVEKIT_URL in .env.local
sed -i 's|LIVEKIT_URL=.*|LIVEKIT_URL=wss://'"$2.$1"':8443|' .env.local

# Download and execute the Node.js setup script for Node.js version 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -

# Install Node.js
apt-get install -y nodejs

# Install pnpm globally
npm install -g pnpm

# Install project dependencies using pnpm
pnpm install

# Download a server.js file from an S3 bucket
wget https://lostshadow.s3.amazonaws.com/free-videoconferencing-platform/next/server.js

# Replace 'next start' with 'node server.js' in the package.json file
sed -i 's/next start/node server.js/' package.json

# Build the project using pnpm
pnpm build

# Start the application and redirect logs to app.log
pnpm start > /opt/meet/app.log 2>&1 &
