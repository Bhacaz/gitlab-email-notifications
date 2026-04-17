# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :set_notification

  def show
    mail = @notification.mail
    @html_body = mail&.html_part&.decoded
    @show ||= mail&.body&.decoded
  end

  def hide
    @notification.update!(hidden: true)

    respond_to do |format|
      format.turbo_stream do
        streams = [
          turbo_stream.replace(
            'notifications-sidebar',
            partial: 'home/sidebar_filters',
            locals: Notification.sidebar_locals_for(current_user)
          )
        ]
        streams << notification_list_streams

        render turbo_stream: streams
      end
      format.html { redirect_to root_path }
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def notification_list_streams
    remaining = current_user.notifications.visible
    if remaining.none?
      turbo_stream.replace(
        'notification-list',
        partial: 'home/notification_list',
        locals: { notifications: remaining, active_reason: nil, active_repo: nil }
      )
    else
      turbo_stream.remove("notification_#{@notification.id}")
    end
  end
end
