# frozen_string_literal: true

module NotificationHandlers
  # Handles GitLab "pipeline failed" notification emails.
  #
  # Detection: X-GitLab-Pipeline-Status header equals "failed".
  # Falls back to subject-line pattern for emails without the header.
  #
  # Extracted fields:
  #   reason             => :pipeline_failed
  #   title              => mail subject
  #   repo               => project path from X-GitLab-Project-Path header
  #   summary            => "Pipeline #<id> failed – <branch>"
  #   link               => pipeline URL from the plain-text body
  #   unsubscribe_link   => List-Unsubscribe URL
  class PipelineFailed < Base
    SUBJECT_PATTERN = /Failed pipeline for/i

    def self.matches?(mail)
      gitlab_pipeline_status(mail) == 'failed' || mail.subject.to_s.match?(SUBJECT_PATTERN)
    end

    def attributes
      pipeline_id = gitlab_header('Pipeline-Id')
      raw_ref     = gitlab_header('Pipeline-Ref')
      branch      = extract_branch(raw_ref)
      repo        = gitlab_header('Project-Path')

      {
        reason: :pipeline_failed,
        title: mail.subject,
        repo: repo,
        summary: build_summary(pipeline_id, branch),
        link: pipeline_link(pipeline_id),
        unsubscribe_link: unsubscribe_link
      }
    end

    private

    def self.gitlab_pipeline_status(mail)
      mail.header['X-GitLab-Pipeline-Status']&.value
    end
    private_class_method :gitlab_pipeline_status

    # Normalise GitLab pipeline ref to a human-readable label.
    # refs/heads/<branch>              → <branch>
    # refs/merge-requests/<id>/head    → MR !<id>
    # anything else                    → raw value
    def extract_branch(ref)
      return nil unless ref.present?

      case ref
      when %r{\Arefs/heads/(.+)\z}         then Regexp.last_match(1)
      when %r{\Arefs/merge-requests/(\d+)} then "MR !#{Regexp.last_match(1)}"
      else ref
      end
    end

    def build_summary(pipeline_id, branch)
      parts = ["Pipeline ##{pipeline_id} failed"]
      parts << branch if branch.present?
      parts.join(' – ')
    end

    def pipeline_link(pipeline_id)
      return extract_link(%r{https?://\S+/-/pipelines/#{pipeline_id}\b}) if pipeline_id

      extract_link(%r{https?://\S+/-/pipelines/\d+})
    end
  end
end
