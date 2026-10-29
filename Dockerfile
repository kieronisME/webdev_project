# set up version of node to use when file is downloaded 
FROM node:22-slim AS base

# root dir shortcut 
WORKDIR /app 

# this line copies depencies from package.json within the back end
COPY backend/package.json backend/package-lock.json ./

# set poty to 8000
ENV PORT=8000
EXPOSE 8000

FROM base AS dev

RUN npm ci
COPY backend/ ./

CMD ["npm", "run", "dev"]


FROM node:22-slim AS frontend

WORKDIR /frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# now in production on the depenecies from frontend and back end w need will run 
FROM base AS production

ENV NODE_ENV=production

RUN npm ci --omit=dev
COPY backend/ ./

COPY --from=frontend /frontend/dist ./dist

RUN mkdir -p uploads && chown node:node uploads

# use node as run
USER node

CMD ["node", "server.js"]