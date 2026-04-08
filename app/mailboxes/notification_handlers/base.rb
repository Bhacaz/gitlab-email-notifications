# frozen_string_literal: true

module NotificationHandlers
  # Abstract base class for GitLab notification email handlers.
  #
  # To add a new notification type:
  #   1. Create a subclass in this directory.
  #   2. Implement `.matches?(mail)` — return true when the mail belongs to this type.
  #   3. Implement `#attributes` — return a hash of Notification fields to set.
  #
  # The mailbox eager-loads this directory and calls each handler via
  # Base.descendants, using the first match.
  class Base
    # Subclasses must implement this.
    # @param mail [Mail::Message]
    # @return [Boolean]
    def self.matches?(_mail)
      raise NotImplementedError, "#{name}.matches? must be implemented"
    end

    # @param mail [Mail::Message]
    def initialize(mail)
      @mail = mail
    end

    # Subclasses must implement this.
    # @return [Hash] attributes suitable for Notification.create!
    def attributes
      raise NotImplementedError, "#{self.class.name}#attributes must be implemented"
    end

    private

    attr_reader :mail

    # Convenience: decoded plain-text body.
    def text_body
      @text_body ||= mail.text_part&.decoded || mail.body.decoded
    end

    # Convenience: value of a GitLab X- header, or nil.
    def gitlab_header(name)
      mail.header["X-GitLab-#{name}"]&.value
    end

    # Convenience: first URL matching pattern in the plain-text body.
    def extract_link(pattern)
      text_body[pattern]
    end

    # Convenience: unsubscribe link from List-Unsubscribe header.
    def unsubscribe_link
      header = mail.header['List-Unsubscribe']&.value
      return unless header

      header.scan(/<(https?:[^>]+)>/)&.flatten&.first
    end
  end
end
