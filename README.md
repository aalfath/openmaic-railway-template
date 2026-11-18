[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/openmaic-3?utm_medium=integration&utm_source=button&utm_campaign=openmaic)

# OpenMAIC on Railway

A one-click Railway template for [OpenMAIC](https://github.com/THU-MAIC/OpenMAIC) (Open Multi-Agent Interactive Classroom), the open-source AI classroom from Tsinghua University's MAIC team: give it a topic or a document and AI agents build and teach a lesson with slides, narration, quizzes and interactive scenes.

## What it deploys

| Service | Source | Data |
|---|---|---|
| **OpenMAIC** | this repo's `Dockerfile`: OpenMAIC **1.4.2**, built from the upstream tag `v1.4.2` (commit `eb7c1bc`) on `node:22.23.5-bookworm-slim`, pinned by digest | volume at `/app/data` (uploaded materials, classroom media, usage records, instance key) |
| **Postgres** | Railway's PostgreSQL | volume (courses, folders, chat history, generated media) |

Upstream publishes no official container image, so the Dockerfile fetches the release commit and follows upstream's own multi-stage Dockerfile. The OpenMAIC service gets a public `*.up.railway.app` domain on port 3000 and a health check on `/api/health`.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `ACCESS_CODE` | `${{secret(32,…)}}` | Site password, generated per deploy. Find it in the service's Variables tab. Everyone with it shares the one course library. |
| `OPENMAIC_SECRET_KEY` | `${{secret(48)}}` | Encrypts the provider keys you save in Settings. Back it up with the database. |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | Private-network connection to the bundled Postgres. |
| `PORT` | `3000` | Port the server listens on; the public domain targets it. |

Nothing to fill in at deploy time. The start script (`railway-start.sh`) also sets `OWNER_SINGLE_USER=true` (one owner and library, as upstream's Docker Compose setup) and `TRUST_PROXY_HEADERS=true` (Railway's edge sets the client address, so the access-code limit of 10 attempts a minute works per visitor). It refuses to start with an empty `ACCESS_CODE`; set `OPENMAIC_ALLOW_NO_ACCESS_CODE=true` only if your own login proxy sits in front.

Optional features (web search, image and video generation, text-to-speech, server-managed model keys) are set in the app under **Settings** or with the variables in upstream's [`.env.example`](https://github.com/THU-MAIC/OpenMAIC/blob/v1.4.2/.env.example). `NEXT_PUBLIC_*` feature flags are build-time and are not set here. MP4 video export needs upstream's separate render service and is not included.

## After deploy

1. Open the service's **Variables** tab and copy `ACCESS_CODE`.
2. Open the public URL and enter the code.
3. Under **Settings → Model Services**, add a key for at least one AI provider. Then create your first course.

## Updates

Each OpenMAIC release is a commit to `main` here that bumps the pinned tag and commit, with a [`CHANGELOG.md`](CHANGELOG.md) entry (breaking changes first). Railway then shows an "update available" notice in projects deployed from this template, and you choose when to apply it. Back up Postgres and keep `OPENMAIC_SECRET_KEY` first: OpenMAIC migrates its tables on first use and does not support rolling back.

## Local test

`docker compose -f docker-compose.test.yml up --build` runs the same setup locally (test-only credentials) on http://localhost:3000.

## Licence

OpenMAIC is MIT-licensed, by THU-MAIC and contributors. This wrapper adds a Dockerfile and a start script.
