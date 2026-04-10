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
        render turbo_stream: [
          turbo_stream.remove("notification_#{@notification.id}"),
          turbo_stream.replace(
            'notifications-sidebar',
            partial: 'home/sidebar_filters',
            locals: Notification.sidebar_locals_for(current_user)
          )
        ]
      end
      format.html { redirect_to root_path }
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
