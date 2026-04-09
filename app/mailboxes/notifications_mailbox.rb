# frozen_string_literal: true

# Force all NotificationHandlers subclasses to be loaded so that
# NotificationHandlers::Base.descendants is complete at runtime.
Rails.autoloaders.main.eager_load_dir(
  Rails.root.join('app/mailboxes/notification_handlers')
)

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
    handler_attrs = handler ? handler.attributes.compact : {}

    user.notifications.create!(
      {
        title: mail.subject,
        message_id: mail.message_id,
        repo: gitlab_project_path,
        unsubscribe_link: extract_unsubscribe_link,
        link: extract_gitlab_link
      }.merge(handler_attrs)
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

  def extract_unsubscribe_link
    header = mail.header['List-Unsubscribe']&.value
    return unless header

    header.scan(/<(https?:[^>]+)>/)&.flatten&.first
  end

  # Extracts the URL from the first <a> whose visible text is "view it on GitLab"
  # in the HTML part, falling back to nil when no such link is present.
  def extract_gitlab_link
    html = mail.html_part&.decoded
    return unless html

    doc = Nokogiri::HTML(html)
    anchor = doc.css('a').find { |a| a.text.strip.downcase == 'view it on gitlab' }
    anchor&.[]('href')
  end

  def gitlab_project_path
    mail.header['X-GitLab-Project-Path']&.value
  end
end
