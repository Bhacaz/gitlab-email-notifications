# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    base = current_user.notifications.visible
    build_sidebar(base)
    @notifications = current_user.notifications.visible_filters(
      reason: params[:reason],
      repo: params[:repo],
      status: params[:status]
    ).order(created_at: :desc)
    @active_reason = params[:reason]
    @active_repo   = params[:repo]
    @active_status = params[:status]
  end

  private

  def build_sidebar(base)
    @all_count = base.count
    reason_counts = base.group(:reason).count
    @reasons = Notification::REASONS
               .to_h { |r| [r.name.to_s, reason_counts.fetch(r.name.to_s, 0)] }
               .select { |_, c| c.positive? }
    @repos = base.where.not(repo: nil).group(:repo).count.sort_by { |_, c| -c }
    statuses = base.group(:status).count
    @new_count = statuses.fetch('new', 0)
    @seen_count = statuses.fetch('seen', 0)
  end
end
