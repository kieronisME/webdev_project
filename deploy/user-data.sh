#!/usr/bin/env bash
set -e

# Install Docker
dnf install -y docker
systemctl enable --now docker

# Write the deploy script to /usr/local/bin/deploy-webdev_project
cat > /usr/local/bin/deploy-webdev_project <<'SCRIPT'
#!/usr/bin/env bash
# Deploys one image of the webdev_project.
# Usage: deploy-webdev_project <tag>
set -euo pipefail

# Send errors to the same place as normal output, so that GitHub Actions
# shows everything in one block.
exec 2>&1

TAG="$1"
REGION=eu-west-1

# Works out the registry address from the account the instance belongs to
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"
IMAGE="$REGISTRY/webdev_project:$TAG"

echo "Deploying $IMAGE"

# Fetches all env vars beginning with /webdev_project/ from the parameter store
# and copies them into a .env file called webdev_project.env
aws ssm get-parameters-by-path \
  --region "$REGION" \
  --path /webdev_project/ \
  --with-decryption \
  --query 'Parameters[].[Name,Value]' \
  --output text \
  | sed 's|^/webdev_project/||' \
  | tr '\t' '=' > /etc/webdev_project.env

# Sets permissions for file owner only to have access to .env file
chmod 600 /etc/webdev_project.env

# Login to ECR to pull webdev_project containers
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

docker pull "$IMAGE"

# Replace the running container with one from the new image
docker rm -f webdev_project || true
docker run -d \
  --name webdev_project \
  --restart unless-stopped \
  -p 80:8000 \
  --env-file /etc/webdev_project.env \
  "$IMAGE"

# Delete images that no container is using, so old versions don't fill the disk
docker image prune -af

echo "Deployed $IMAGE"
SCRIPT

chmod +x /usr/local/bin/deploy-webdev_project

# Start the newest image
/usr/local/bin/deploy-webdev_project latest