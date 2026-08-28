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
    sidebar = Notification.sidebar_locals_for(
      current_user,
      active_reason: params[:reason],
      active_repo: params[:repo],
      active_status: params[:status]
    )

    @all_count = sidebar[:all_count]
    @reasons = sidebar[:reasons]
    @repos = sidebar[:repos]
    @new_count = sidebar[:new_count]
    @seen_count = sidebar[:seen_count]
  end
end
