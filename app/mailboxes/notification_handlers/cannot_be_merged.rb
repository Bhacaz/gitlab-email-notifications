# frozen_string_literal: true

module NotificationHandlers
  # Handles GitLab MR "cannot be merged" (conflict) notification emails.
  #
  # Detection: X-GitLab-MergeRequest-IID header is present AND the plain-text
  # body first non-blank line matches "Merge request .* can no longer be merged".
  #
  # Extracted fields:
  #   reason   => :cannot_be_merged
  #   title    => mail subject
  #   repo     => project path from X-GitLab-Project-Path header
  #   summary  => "MR !<iid> – cannot be merged"
  #   link     => merge request URL from the plain-text body
  class CannotBeMerged < Base
    def self.matches?(mail)
      body = mail.text_part&.decoded || mail.body.decoded
      mail.header['X-GitLab-MergeRequest-IID']&.value.present? &&
        body.lstrip.lines.first.to_s.match?(/Merge request .* can no longer be merged/i)
    end

    def attributes
      mr_iid = gitlab_header('MergeRequest-IID')
      repo   = gitlab_header('Project-Path')

      {
        reason: :cannot_be_merged,
        title: mail.subject,
        repo: repo,
        summary: "MR !#{mr_iid} \u2013 cannot be merged",
        link: mr_link
      }
    end

    private

    def mr_link
      extract_link(%r{https?://\S+/-/merge_requests/\d+})
    end
  end
end
