# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    base = current_user.notifications.visible

    # Build sidebar facet data from the full unfiltered set
    @all_count   = base.count
    @reasons     = base.group(:reason).count
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
