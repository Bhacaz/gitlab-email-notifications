# frozen_string_literal: true

module NotificationHandlers
  # Handles GitLab "pipeline fixed" notification emails.
  #
  # Detection: X-GitLab-Pipeline-Status header equals "success" and the
  # subject matches "Fixed pipeline". Falls back to subject-line pattern
  # alone for emails without the header.
  #
  # Extracted fields:
  #   reason   => :pipeline_fixed
  #   title    => "Pipeline fixed – {project} ({branch})"
  #   repo     => project path from X-GitLab-Project-Path header
  #   summary  => "Pipeline #{id} fixed – {branch or MR}"
  #   link     => pipeline URL from the plain-text body
  class PipelineFixed < Base
    SUBJECT_PATTERN = /Fixed pipeline for/i

    def self.matches?(mail)
      mail.subject.to_s.match?(SUBJECT_PATTERN) &&
        (gitlab_pipeline_status(mail) == 'success' || gitlab_pipeline_status(mail).nil?)
    end

    def attributes
      pipeline_id = gitlab_header('Pipeline-Id')
      branch      = extract_branch(gitlab_header('Pipeline-Ref'))
      repo        = gitlab_header('Project-Path')
      proj        = project_name

      title_parts = ['Pipeline fixed']
      title_parts << proj if proj.present?
      title_parts << "(#{branch})" if branch.present?

      {
        reason: :pipeline_fixed,
        title: title_parts.join(' \u2013 '),
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
      parts = ["Pipeline ##{pipeline_id} fixed"]
      parts << branch if branch.present?
      parts.join(' \u2013 ')
    end

    def pipeline_link(pipeline_id)
      return extract_link(%r{https?://\S+/-/pipelines/#{pipeline_id}\b}) if pipeline_id

      extract_link(%r{https?://\S+/-/pipelines/\d+})
    end
  end
end
