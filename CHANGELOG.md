# Changelog

Each entry is one version of this Railway template. Breaking changes come first.
Deployers get an "update available" notice in Railway when `main` changes; read
the entry before applying it.

## 1.4.2 (2026-11-18)

First release of the template.

- OpenMAIC 1.4.2, built from the upstream tag `v1.4.2` (commit `eb7c1bcccc3d083684c26ae1d5d187d41122cb10`), on the official `node:22.23.5-bookworm-slim` image pinned by digest.
- Railway PostgreSQL for courses, folders, chat history and generated media.
- Volume at `/app/data` for uploaded materials, classroom media, usage records and the instance key.
- Generated `ACCESS_CODE` and `OPENMAIC_SECRET_KEY`; the app refuses to start with an empty `ACCESS_CODE`.
- Health check on `/api/health`.
