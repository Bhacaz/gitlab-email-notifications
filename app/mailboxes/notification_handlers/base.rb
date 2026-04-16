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

    # Convenience: first non-blank line of the plain-text body.
    def first_body_line
      @first_body_line ||= text_body.lstrip.lines.first.to_s.strip
    end

    # Convenience: value of a GitLab X- header, or nil.
    def gitlab_header(name)
      mail.header["X-GitLab-#{name}"]&.value
    end

    # Convenience: first URL matching pattern in the plain-text body.
    def extract_link(pattern)
      text_body[pattern]
    end

    # Extracts the actor name from a body line.
    #
    # GitLab uses consistent patterns:
    #   "Alice Smith started a new discussion on …"
    #   "Alice Smith commented: https://…"
    #   "Alice Smith commented on a discussion on …"
    #   "Merge request … was approved by Alice Smith"
    #   "Merge request … was reviewed by Alice Smith"
    #   "Alice Smith was added as a reviewer."
    #   "Alice Smith pushed new commits …"
    #   "All discussions … were resolved by Alice Smith"
    #
    # @param line [String] defaults to the first body line
    # @return [String, nil]
    def extract_actor(line = first_body_line)
      # "... by Name" — approved/reviewed/resolved patterns
      if (m = line.match(/\bby\s+(\S[^-\n]+?)\s*$/i))
        return m[1].strip
      end

      # "Name verb …" — actor-first patterns (commented, started, pushed, was added)
      # First try title-case names (most common), then fall back to any word(s) before verb.
      if (m = line.match(/\A((?:[A-Z]\S* )+(?:[A-Z]\S*))\s+(commented|started|pushed|was added)/))
        return m[1].strip
      end
      if (m = line.match(/\A(\S+(?:\s+\S+)*?)\s+(commented|started|pushed|was added)\b/))
        return m[1].strip
      end

      nil
    end

    # Extracts the filename after "on <file>:" in a body line.
    #
    # Handles:
    #   "cursor started a new discussion on path/to/file.ts: https://…"
    #   "Victor Nguyen commented on a discussion on path/to/file.yaml: https://…"
    #
    # @param line [String] defaults to the first body line
    # @return [String, nil]
    def extract_file_from_body(line = first_body_line)
      m = line.match(/ on ([^:]+):\s*https?:/i)
      m&.[](1)&.strip
    end

    # Short project name from X-GitLab-Project header (e.g. "core-orchestration").
    # Falls back to the last segment of X-GitLab-Project-Path.
    # @return [String, nil]
    def project_name
      gitlab_header('Project') ||
        gitlab_header('Project-Path')&.split('/')&.last
    end
  end
end
