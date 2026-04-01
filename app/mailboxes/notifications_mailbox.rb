# frozen_string_literal: true

class NotificationsMailbox < ApplicationMailbox
  CONFIRMATION_SUBJECT = 'Confirmation instructions'

  def process
    user = User.find_by(email_prefix: mail.to.first.split('@').first)
    return unless user

    if confirmation_email?
      process_confirmation_email(user)
    else
      process_notification_email(user)
    end
  end

  private

  def confirmation_email?
    mail.subject == CONFIRMATION_SUBJECT
  end

  def process_confirmation_email(user)
    link = extract_confirmation_link
    onboarding = user.onboarding || user.build_onboarding
    onboarding.assign_attributes(
      state: :awaiting_confirmation,
      message_id: mail.message_id,
      confirmation_link: link
    )
    onboarding.save!

    Turbo::StreamsChannel.broadcast_replace_to(
      "onboarding_#{user.id}",
      target: 'onboarding-status',
      partial: 'onboardings/status',
      locals: { onboarding: onboarding }
    )
  end

  def process_notification_email(user)
    handler = notification_handler
    attrs = handler ? handler.attributes : {}

    user.notifications.create!(
      {
        title: mail.subject,
        message_id: mail.message_id
      }.merge(attrs)
    )
  end

  # Returns an instantiated handler for the first matching class, or nil.
  def notification_handler
    handler_class = NotificationHandlers::Base.descendants.find { |klass| klass.matches?(mail) }
    handler_class&.new(mail)
  end

  def extract_confirmation_link
    body = mail.text_part&.decoded || mail.body.decoded
    body[%r{https?://\S+/-/profile/emails/confirmation\?\S+}]
  end
end
