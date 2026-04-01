# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :set_notification

  def show
    inbound_email = ActionMailbox::InboundEmail.find_by(message_id: @notification.message_id)
    mail = inbound_email&.mail
    @html_body = mail&.html_part&.decoded
    @html_body ||= mail&.body&.decoded
  end

  def hide
    @notification.update!(hidden: true)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("notification_#{@notification.id}") }
      format.html { redirect_to root_path }
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
