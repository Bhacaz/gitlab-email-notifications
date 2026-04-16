# frozen_string_literal: true

module NotificationHandlers
  # Handles GitLab MR "cannot be merged" (conflict) notification emails.
  #
  # Detection: X-GitLab-MergeRequest-IID header is present AND the plain-text
  # body first non-blank line matches "Merge request .* can no longer be merged".
  #
  # Extracted fields:
  #   reason   => :cannot_be_merged
  #   title    => "!{iid} cannot be merged"
  #   repo     => project path from X-GitLab-Project-Path header
  #   summary  => "MR !{iid} has a conflict – {branch} ({project})"
  #   link     => merge request URL from the plain-text body
  class CannotBeMerged < Base
    def self.matches?(mail)
      body = mail.text_part&.decoded || mail.body.decoded
      mail.header['X-GitLab-MergeRequest-IID']&.value.present? &&
        body.lstrip.lines.first.to_s.match?(/Merge request .* can no longer be merged/i)
    end

    def attributes
      mr_iid   = gitlab_header('MergeRequest-IID')
      repo     = gitlab_header('Project-Path')
      branches = extract_branches_from_body
      proj     = project_name

      summary_parts = ["MR !#{mr_iid} has a conflict"]
      summary_parts << branches if branches.present?
      summary_parts << "(#{proj})" if proj.present?

      {
        reason: :cannot_be_merged,
        title: "!#{mr_iid} cannot be merged",
        repo: repo,
        summary: summary_parts.join(" \u2013 "),
        link: mr_link
      }
    end

    private

    def extract_branches_from_body
      m = text_body.match(/^Branches:\s+(.+?) to (.+)$/)
      return nil unless m

      "#{m[1].strip} \u2192 #{m[2].strip}"
    end

    def mr_link
      extract_link(%r{https?://\S+/-/merge_requests/\d+})
    end
  end
end
