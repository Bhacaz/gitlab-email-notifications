# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user

  Reason = Struct.new(:name, :value, :display_name, :icon_class)

  REASONS = [
    Reason.new(:other, 0, 'Other', 'bi bi-bell'),
    Reason.new(:pipeline_failed, 1, 'Pipeline Failed', 'bi bi-exclamation-triangle'),
    Reason.new(:pipeline_fixed, 2, 'Pipeline Fixed', 'bi bi-check-circle')
  ].freeze

  enum :reason,
       REASONS.to_h { |reason| [reason.name, reason.value] },
       prefix: true

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
