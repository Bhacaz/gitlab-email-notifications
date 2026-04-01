# frozen_string_literal: true

class NotificationsMailbox < ApplicationMailbox
  def process
    user = User.find_by(email_prefix: mail.to.first.split('@').first)
    return unless user

    user.notifications.create!(
      title: mail.subject,
      message_id: mail.message_id
    )
  end
end
