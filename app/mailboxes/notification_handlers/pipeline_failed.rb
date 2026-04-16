# frozen_string_literal: true

module NotificationHandlers
  # Handles GitLab "pipeline failed" notification emails.
  #
  # Detection: X-GitLab-Pipeline-Status header equals "failed".
  # Falls back to subject-line pattern for emails without the header.
  #
  # Extracted fields:
  #   reason   => :pipeline_failed
  #   title    => "Pipeline failed – {project} ({branch})"
  #   repo     => project path from X-GitLab-Project-Path header
  #   summary  => "Pipeline #{id} failed on {branch} – {stage}: {job}"
  #   link     => pipeline URL from the plain-text body
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
      proj        = project_name

      title_parts = ['Pipeline failed']
      title_parts << proj if proj.present?
      title_parts << "(#{branch})" if branch.present?

      {
        reason: :pipeline_failed,
        title: title_parts.join(" \u2013 "),
        repo: repo,
        summary: build_summary(pipeline_id, branch),
        link: pipeline_link(pipeline_id)
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
      return nil if ref.blank?

      case ref
      when %r{\Arefs/heads/(.+)\z}         then Regexp.last_match(1)
      when %r{\Arefs/merge-requests/(\d+)} then "MR !#{Regexp.last_match(1)}"
      else ref
      end
    end

    def build_summary(pipeline_id, branch)
      parts = ["Pipeline ##{pipeline_id} failed"]
      parts << branch if branch.present?
      parts << extract_failed_job_info if extract_failed_job_info.present?
      parts.join(" \u2013 ")
    end

    # Extracts "Stage: lint / Name: job-name" from the body.
    def extract_failed_job_info
      @extract_failed_job_info ||= begin
        stage = text_body[/^Stage:\s*(.+)$/, 1]&.strip
        job   = text_body[/^Name:\s*(.+)$/, 1]&.strip
        if stage.present? && job.present?
          "#{stage}: #{job}"
        elsif stage.present?
          stage
        end
      end
    end

    def pipeline_link(pipeline_id)
      return extract_link(%r{https?://\S+/-/pipelines/#{pipeline_id}\b}) if pipeline_id

      extract_link(%r{https?://\S+/-/pipelines/\d+})
    end
  end
end
