# OpenMAIC (https://github.com/THU-MAIC/OpenMAIC) for Railway.
#
# Upstream publishes no official container image, so this builds the upstream
# release from its pinned tag commit, following upstream's own Dockerfile
# (v1.4.2) stage by stage. Differences from upstream's Dockerfile:
#   - the source is fetched at a pinned commit instead of COPY . .
#   - no BuildKit cache mounts (Railway's builder needs service-scoped cache ids)
#   - a small start script that hands the Railway volume at /app/data to the
#     app user, then runs the server as that user (uid 1001)
# To update: bump OPENMAIC_VERSION and OPENMAIC_COMMIT together (and the Node
# base if upstream's .nvmrc moves), and add a CHANGELOG.md entry.

ARG NODE_IMAGE=node:22.23.5-alpine@sha256:1314fb30ec37592d5845e5a160d522c0e680972aa534549940b8d73bde88481a

# ---- Source at the pinned release commit ----
FROM ${NODE_IMAGE} AS source
ARG OPENMAIC_VERSION=1.4.2
ARG OPENMAIC_COMMIT=eb7c1bcccc3d083684c26ae1d5d187d41122cb10
RUN apk add --no-cache git
WORKDIR /src
RUN git init -q . \
 && git remote add origin https://github.com/THU-MAIC/OpenMAIC.git \
 && git fetch -q --depth 1 origin "${OPENMAIC_COMMIT}" \
 && git checkout -q FETCH_HEAD \
 && test "$(git rev-parse HEAD)" = "${OPENMAIC_COMMIT}" \
 && grep -q "\"version\": \"${OPENMAIC_VERSION}\"" package.json \
 # same exclusions as upstream's .dockerignore
 && rm -r .git assets render-service \
 && rm -f ./*.md .env.local openmaic.yml

# ---- Base ----
FROM ${NODE_IMAGE} AS base
RUN apk add --no-cache libc6-compat \
 && corepack enable \
 && corepack prepare pnpm@10.28.0 --activate
WORKDIR /app

# ---- Dependencies ----
FROM base AS deps
# Native build tools for sharp, @napi-rs/canvas
RUN apk add --no-cache python3 build-base g++ cairo-dev pango-dev jpeg-dev giflib-dev librsvg-dev
COPY --from=source /src/package.json /src/pnpm-lock.yaml /src/pnpm-workspace.yaml ./
COPY --from=source /src/packages/ ./packages/
COPY --from=source /src/scripts/ ./scripts/
RUN pnpm install --frozen-lockfile --ignore-scripts

# ---- Builder ----
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/packages ./packages
COPY --from=source /src/ ./
RUN NODE_OPTIONS=--max-old-space-size=1024 pnpm run build:packages
RUN pnpm build

# ---- Runner ----
FROM ${NODE_IMAGE} AS runner
WORKDIR /app
ENV NODE_ENV=production \
    HOSTNAME=0.0.0.0 \
    PORT=3000
RUN apk add --no-cache libc6-compat cairo pango jpeg giflib librsvg su-exec \
 && addgroup --system --gid 1001 nodejs \
 && adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
RUN mkdir -p /app/data && chown -R nextjs:nodejs /app/data
COPY --chmod=755 railway-start.sh /usr/local/bin/railway-start.sh
EXPOSE 3000
# Starts as root only to take ownership of the volume, then runs as nextjs.
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
