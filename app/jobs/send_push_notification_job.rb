# frozen_string_literal: true

class SendPushNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_id)
    notification = Notification.find_by(id: notification_id)
    return unless notification

    user = notification.user
    return if user.push_subscriptions.empty?

    payload = {
      title: notification.title.presence || notification.reason_display_name,
      body: notification.repo.presence || '',
      path: Rails.application.routes.url_helpers.notification_path(notification)
    }.to_json

    vapid = {
      public_key: ENV.fetch('VAPID_PUBLIC_KEY'),
      private_key: ENV.fetch('VAPID_PRIVATE_KEY'),
      subject: "mailto:#{ENV.fetch('VAPID_SUBJECT', 'push@example.com')}"
    }

    user.push_subscriptions.find_each do |sub|
      WebPush.payload_send(
        message: payload,
        endpoint: sub.endpoint,
        p256dh: sub.p256dh,
        auth: sub.auth,
        vapid: vapid
      )
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      sub.destroy
    rescue WebPush::Error => e
      Rails.logger.error("[SendPushNotificationJob] WebPush error for sub #{sub.id}: #{e.message}")
    end
  end
end
