# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :set_notification, except: :mark_all_done

  def show
    @notification.status_seen! unless @notification.status_seen? || @notification.status_done?

    mail = @notification.mail
    @html_body = mail&.html_part&.decoded
  end

  def visit
    @notification.status_seen! unless @notification.status_seen? || @notification.status_done?
    redirect_to @notification.link, allow_other_host: true
  end

  def done
    @notification.status_done!
    respond_to do |format|
      format.turbo_stream { render turbo_stream: done_turbo_streams }
      format.html { redirect_to root_path }
    end
  end

  def mark_all_done
    current_user.notifications.visible_filters(
      reason: params[:reason],
      repo: params[:repo],
      status: params[:status]
    ).update_all(status: Notification.statuses[:done]) # rubocop:disable Rails/SkipsModelValidations -- bulk op, no callbacks wanted

    respond_to do |format|
      format.turbo_stream { render turbo_stream: done_turbo_streams }
      format.html { redirect_to root_path }
    end
  end

  private

  def done_turbo_streams
    active_reason = params[:reason]
    active_repo   = params[:repo]
    active_status = params[:status]

    streams = [
      turbo_stream.replace(
        'notifications-sidebar',
        partial: 'home/sidebar_filters',
        locals: Notification.sidebar_locals_for(
          current_user,
          active_reason: active_reason,
          active_repo: active_repo,
          active_status: active_status
        )
      )
    ]
    streams << notification_list_streams(active_reason, active_repo, active_status)
    streams
  end

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def notification_list_streams(active_reason = nil, active_repo = nil, active_status = nil)
    remaining = current_user.notifications.visible_filters(
      reason: active_reason,
      repo: active_repo,
      status: active_status
    )

    if remaining.none?
      turbo_stream.replace(
        'notification-list',
        partial: 'home/notification_list',
        locals: { notifications: remaining, active_reason: active_reason, active_repo: active_repo,
                  active_status: active_status }
      )
    else
      turbo_stream.remove("notification_#{@notification.id}")
    end
  end
end
