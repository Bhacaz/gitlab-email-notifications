# frozen_string_literal: true

module NotificationHandlers
  # Handles GitLab MR "reviewed" notification emails.
  #
  # Detection: X-GitLab-MergeRequest-IID header is present AND the plain-text
  # body first non-blank line matches "Merge request <url> was reviewed by".
  #
  # Extracted fields:
  #   reason   => :mr_reviewed
  #   title    => mail subject
  #   repo     => project path from X-GitLab-Project-Path header
  #   summary  => "MR !<iid> – reviewed"
  #   link     => merge request URL from the plain-text body
  class MrReviewed < Base
    def self.matches?(mail)
      body = mail.text_part&.decoded || mail.body.decoded
      mail.header['X-GitLab-MergeRequest-IID']&.value.present? &&
        body.lstrip.lines.first.to_s.match?(/Merge request .* was reviewed by/i)
    end

    def attributes
      mr_iid = gitlab_header('MergeRequest-IID')
      repo   = gitlab_header('Project-Path')

      {
        reason: :mr_reviewed,
        title: mail.subject,
        repo: repo,
        summary: "MR !#{mr_iid} \u2013 reviewed",
        link: mr_link
      }
    end

    private

    def mr_link
      extract_link(%r{https?://\S+/-/merge_requests/\d+})
    end
  end
end
