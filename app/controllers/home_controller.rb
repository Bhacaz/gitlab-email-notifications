# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    base = current_user.notifications.visible

    # Build sidebar facet data from the full unfiltered set
    @all_count = base.count
    reason_counts = base.group(:reason).count
    @reasons     = Notification::REASONS
                   .to_h { |r| [r.name.to_s, reason_counts.fetch(r.name.to_s, 0)] }
                   .select { |_, c| c > 0 }
    @repos       = base.where.not(repo: nil).group(:repo).count.sort_by { |_, c| -c }

    # Apply filters from params
    scope = base
    scope = scope.where(reason: params[:reason]) if params[:reason].present?
    scope = scope.where(repo: params[:repo])     if params[:repo].present?

    @notifications   = scope.order(created_at: :desc)
    @active_reason   = params[:reason]
    @active_repo     = params[:repo]
  end
end
