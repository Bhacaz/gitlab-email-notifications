# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user

  Reason = Struct.new(:name, :value, :display_name, :icon_class)

  REASONS = [
    Reason.new(:other, 0, 'Other', 'bi bi-bell'),
    Reason.new(:pipeline_failed, 1, 'Pipeline Failed', 'bi bi-exclamation-triangle'),
    Reason.new(:pipeline_fixed, 2, 'Pipeline Fixed', 'bi bi-check-circle'),
    Reason.new(:mr_discussion, 3, 'MR Discussion', 'bi bi-chat-left-dots'),
    Reason.new(:mr_comment, 4, 'MR Comment', 'bi bi-chat-left-text'),
    Reason.new(:mr_approved, 5, 'MR Approved', 'bi bi-check2-circle'),
    Reason.new(:mr_reviewed, 6, 'MR Reviewed', 'bi bi-eye'),
    Reason.new(:cannot_be_merged, 7, 'Cannot Be Merged', 'bi bi-exclamation-circle'),
    Reason.new(:discussions_resolved, 8, 'Discussions Resolved', 'bi bi-check-all'),
    Reason.new(:reviewer_added, 9, 'Reviewer Added', 'bi bi-person-check'),
    Reason.new(:pushed_commits, 10, 'Pushed Commits', 'bi bi-git'),
    Reason.new(:mr_reassigned, 11, 'MR Reassigned', 'bi bi-person-fill-gear')
  ].freeze

  enum :reason,
       REASONS.to_h { |reason| [reason.name, reason.value] },
       prefix: true

  enum :status, { new: 0, seen: 1, done: 2 }, prefix: true

  scope :visible, -> { where.not(status: :done) }
  scope :new_status, -> { where(status: :new) }
  scope :old, -> { where(status: :seen) }

  def reason_display_name
    REASONS.find { |r| r.name.to_s == reason }&.display_name || reason.to_s.humanize
  end

  after_create_commit :broadcast_new_banner
  after_create_commit :enqueue_push_notification
  after_update_commit :broadcast_seen, if: -> { status_previously_was == 'new' && status_seen? }

  def self.sidebar_locals_for(user, active_reason: nil, active_repo: nil, active_status: nil)
    base = user.notifications.visible
    reason_counts = base.group(:reason).count
    statuses = base.group(:status).count
    {
      all_count: base.count,
      reasons: REASONS
               .to_h { |r| [r.name.to_s, reason_counts.fetch(r.name.to_s, 0)] }
               .select { |_, c| c.positive? },
      repos: base.where.not(repo: nil).group(:repo).count.sort_by { |_, c| -c },
      new_count: statuses.fetch('new', 0),
      seen_count: statuses.fetch('seen', 0),
      active_reason: active_reason,
      active_repo: active_repo,
      active_status: active_status
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

  def enqueue_push_notification
    return unless Rails.application.config.x.web_push.enabled? && user.push_subscriptions.exists?

    SendPushNotificationJob.perform_later(id)
  end

  def broadcast_seen
    Turbo::StreamsChannel.broadcast_replace_to(
      "notifications_#{user_id}",
      target: "notification_#{id}",
      partial: 'notifications/notification',
      locals: { notification: self }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      "notifications_#{user_id}",
      target: 'notifications-sidebar',
      partial: 'home/sidebar_filters',
      locals: Notification.sidebar_locals_for(user)
    )
  end
end
