# GitLab Email Notifications

A self-hosted notification center for GitLab, built because [GitLab doesn't have one](https://gitlab.com/gitlab-org/gitlab/-/work_items/14889).

It ingests GitLab notification emails via Mailgun and presents them in a unified, filterable inbox. Authentication is handled via GitLab OAuth.

## Quick start with Docker Compose

**1. Clone the repo and copy the environment template:**

```sh
git clone https://github.com/your-org/gitlab-email-notifications.git
cd gitlab-email-notifications
cp .env.example .env
```

**2. Fill in `.env`** — see [Environment variables](#environment-variables) below.

**3. Start the app:**

```sh
docker compose up -d
```

The app will be available on port 80. All data (SQLite databases) is persisted in the named `storage` volume.

---

## Environment variables

All configuration is done via environment variables. Set them in `.env` for local development, or pass them directly in `docker-compose.yml` / your hosting platform for production.

| Variable | Required | Description |
|---|---|---|
| `SECRET_KEY_BASE` | Yes | Random secret for cookies and encrypted tokens. Generate with `bin/rails secret`. |
| `GITLAB_APP_ID` | Yes | OAuth Application ID from GitLab. |
| `GITLAB_APP_SECRET` | Yes | OAuth Application Secret from GitLab. |
| `GITLAB_CALLBACK_URL` | Yes | Full URL to `/oauth/gitlab/callback` on your domain. |
| `EMAIL_DOMAIN` | Yes | The custom domain configured in Mailgun (e.g. `gitlab.example.com`). |
| `MAILGUN_SIGNING_KEY` | Yes | HTTP webhook signing key from Mailgun API Security. |
| `ADMIN_USERNAME` | Yes | Username for the admin panel (HTTP Basic Auth). |
| `ADMIN_PASSWORD` | Yes | Password for the admin panel (HTTP Basic Auth). |

### Generating SECRET_KEY_BASE

```sh
docker run --rm $(docker build -q .) bin/rails secret
```

Or if you have Ruby installed locally:

```sh
bin/rails secret
```

---

## GitLab OAuth Application

1. Go to <https://gitlab.com/-/profile/applications> and create a new application:
   - **Name:** GitLab Email Notifications
   - **Redirect URI:** `https://your-domain.example.com/oauth/gitlab/callback`
   - **Scopes:** `read_user`
2. Copy the **Application ID** → `GITLAB_APP_ID`
3. Copy the **Secret** → `GITLAB_APP_SECRET`
4. Set `GITLAB_CALLBACK_URL` to the same redirect URI you entered above.

---

## Mailgun setup

1. Add a custom domain in Mailgun (e.g. `gitlab.example.com`).
2. Add the DNS records Mailgun provides and verify the domain.
3. Create a **Route**:
   - **Match recipient:** `.*@gitlab.example.com`
   - **Action → Forward:** `https://your-domain.example.com/rails/action_mailbox/mailgun/inbound_emails/mime`
4. Go to **API Security** → copy the **HTTP webhook signing key** → `MAILGUN_SIGNING_KEY`.
5. Set `EMAIL_DOMAIN=gitlab.example.com`.

In GitLab, configure your notification emails to go to
`<your-prefix>@gitlab.example.com`. Each user's personal forwarding address is
shown in the onboarding flow after sign-in.

---

## Admin panel

The following engines are mounted under `/admin/*` and protected by HTTP Basic Auth
(`ADMIN_USERNAME` / `ADMIN_PASSWORD`):

| Path | Description |
|---|---|
| `/admin/errors` | Application errors (SolidErrors) |
| `/admin/apm` | Performance monitoring (SolidAPM) |
| `/admin/jobs` | Background job queue (SolidQueueDashboard) |

---

## Development setup

**Prerequisites:** Ruby (see `.ruby-version`), Bundler.

```sh
cp .env.example .env
# Fill in .env with your credentials

bundle install
bin/rails db:setup
bin/rails server
```

The dev login shortcut at `GET /dev/login` signs you in as the first user in the
database — no OAuth flow needed for local testing.

### Rails master key

The repo ships encrypted credential files (`config/credentials/*.yml.enc`) for
development convenience. They are **not required** for deployment — all secrets
are loaded from environment variables. If you want to use `bin/rails credentials:edit`
locally, generate a fresh key:

```sh
# Remove the existing encrypted file and regenerate
rm config/credentials/development.yml.enc
bin/rails credentials:edit --environment development
```

Or simply ignore the credentials system entirely and rely on `.env`.

---

## Docker image

The `Dockerfile` builds a production image. To build and run manually:

```sh
docker build -t gitlab-email-notifications .
docker run -d -p 80:80 \
  --env-file .env \
  -v gitlab_storage:/rails/storage \
  --name gitlab-email-notifications \
  gitlab-email-notifications
```
