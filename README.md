# GitlabEmailNotifications

Attempt to create the Notification center that GitLab doesn't have. https://gitlab.com/gitlab-org/gitlab/-/work_items/14889

By ingesting email GitLab notifications.

## GitLab OAuth Application

Go to https://gitlab.com/-/profile/applications and create a new application with the following settings:
* Name: GitLab Email Notifications
* Redirect URI: http://your-domain.example.com/oauth/gitlab/callback
* Scopes: `read_user`
* Save the Application Id and Secret in credentials

```yaml
# bin/rails credentials:edit

gitlab:
  application_id: abc
  secret_id: gloas-abc
  callback_url: http://your-domain.example.com/oauth/gitlab/callback
```

## Mailgun config

* Add custom domain.
* Add DNS records for the domain and make sure they are verified.
* Routes
  * Match recipient: `.*@gitlab.example.com`
  * Forward to: `https://your-domain.example.com/rails/action_mailbox/mailgun/inbound_emails/mime`
* Go to API Security
  * Copy the _HTTP webhook signing key_
  * Save it in credentials for ActionMailbox

```yaml
# bin/rails credentials:edit

# Custom domain
email_domain: gitlab.example.com

action_mailbox:
  mailgun_signing_key: key-abc
```

## Admin view and engine

The project mount some admin views:

* SolidErrors: App error. Accessible at `/admin/errors`
* SolidApm: App performance monitoring. Accessible at `/admin/apm`
* MissionControl: Background jobs monitoring. Accessible at `/admin/jobs`

Setup admin username and password in credentials:

```yaml
# bin/rails credentials:edit
admin:
  username: admin
  password: password
```
