# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user

  Reason = Struct.new(:name, :value, :display_name, :icon_class)

  REASONS = [
    Reason.new(:other, 0, 'Other', 'bi bi-bell'),
    Reason.new(:pipeline_failed, 1, 'Pipeline Failed', 'bi bi-exclamation-triangle'),
    Reason.new(:pipeline_fixed, 2, 'Pipeline Fixed', 'bi bi-check-circle'),
    Reason.new(:mr_discussion, 3, 'MR Discussion', 'bi bi-chat-left-dots'),
    Reason.new(:mr_comment, 4, 'MR Comment', 'bi bi-chat-left-text')
  ].freeze

  enum :reason,
       REASONS.to_h { |reason| [reason.name, reason.value] },
       prefix: true

  scope :visible, -> { where(hidden: false) }

  after_create_commit :broadcast_new_banner

  def self.sidebar_locals_for(user, active_reason: nil, active_repo: nil)
    base = user.notifications.visible
    reason_counts = base.group(:reason).count
    {
      all_count: base.count,
      reasons: REASONS.to_h { |r| [r.name.to_s, reason_counts.fetch(r.name.to_s, 0)] },
      repos: base.where.not(repo: nil).group(:repo).count.sort_by { |_, c| -c },
      active_reason: active_reason,
      active_repo: active_repo
    }
  end

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
