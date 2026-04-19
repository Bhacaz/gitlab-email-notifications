# frozen_string_literal: true

class SendPushNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_id)
    return unless vapid_configured?

    notification = Notification.find_by(id: notification_id)
    return unless notification

    send_to_all(notification)
  end

  private

  def vapid_configured?
    Rails.application.config.x.web_push.enabled?
  end

  def vapid
    {
      public_key: Rails.application.config.x.vapid.public_key,
      private_key: Rails.application.config.x.vapid.private_key,
      # email_domain is required in environment/production.rb
      subject: "mailto:contact@#{Rails.application.config.email_domain}"
    }
  end

  def build_payload(notification)
    url = Rails.application.routes.url_helpers.notification_path(notification)
    JSON.generate({
      title: "GitLab - #{notification.title.presence || notification.reason_display_name}",
      options: {
        body: notification.repo.presence || '',
        icon: '/gitlab.png',
        data: {
          url: url,
          path: url
          # badge: @badge
        }
      }
    })
  end

  def send_to_all(notification)
    payload = build_payload(notification)
    notification.user.push_subscriptions.find_each do |sub|
      deliver(sub, payload)
    end
  end

  def deliver(sub, payload)
    WebPush.payload_send(message: payload, endpoint: sub.endpoint,
                         p256dh: sub.p256dh, auth: sub.auth, vapid: vapid)
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    sub.destroy
  rescue WebPush::Error => e
    Rails.logger.error("[SendPushNotificationJob] WebPush error for sub #{sub.id}: #{e.message}")
  end
end
