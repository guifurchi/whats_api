# Use the official Node.js Alpine image as the base image
FROM node:20-alpine as app

# Set the working directory
WORKDIR /usr/src/app

# Install Chromium
ENV CHROME_BIN="/usr/bin/chromium-browser" \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD="true" \
    NODE_ENV="production"
RUN set -x \
    && apk update \
    && apk upgrade \
    && apk add --no-cache \
    udev \
    ttf-freefont \
    chromium

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install the dependencies
RUN npm ci --only=production --ignore-scripts

# Copy the rest of the source code to the working directory
COPY . .

# Expose the port the API will run on
EXPOSE 3000

# Start the API
CMD ["npm", "start"]

# Nginx Stage
FROM nginx:alpine as nginx

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY certs/fullchain.pem /etc/ssl/certs/fullchain.pem
COPY certs/privkey.pem /etc/ssl/private/privkey.pem

# Expose ports for Nginx
EXPOSE 8080 8443

# Final Stage
FROM nginx:alpine

# Copy Node.js app from the previous stage
COPY --from=app /usr/src/app /usr/src/app

# Copy Nginx configuration and SSL certificates
COPY --from=nginx /etc/nginx /etc/nginx

# Set the working directory for the Node.js app
WORKDIR /usr/src/app

# Start Nginx and the Node.js app
CMD ["nginx", "-g", "daemon off;"]