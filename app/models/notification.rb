# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user

  enum :reason, {
    other: 0,
    pipeline_failed: 1,
    pipeline_fixed: 2
  }, prefix: true

  scope :visible, -> { where(hidden: false) }

  after_create_commit :broadcast_new_banner

  def mail
    ActionMailbox::InboundEmail.find_by(message_id: message_id).mail
  end

  private

  def broadcast_new_banner
    count = user.notifications.visible.count
    Turbo::StreamsChannel.broadcast_replace_to(
      "notifications_new_#{user_id}",
      target: 'new-notifications-banner',
      partial: 'notifications/new_banner',
      locals: { count: count }
    )
  end
end
