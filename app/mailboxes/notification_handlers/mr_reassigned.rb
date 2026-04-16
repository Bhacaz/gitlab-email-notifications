# frozen_string_literal: true

module NotificationHandlers
  # Handles GitLab MR "reassigned" notification emails.
  #
  # Detection: X-GitLab-MergeRequest-IID header is present AND the plain-text
  # body first line matches "Reassigned merge request".
  #
  # Extracted fields:
  #   reason   => :mr_reassigned
  #   title    => "MR !{iid} reassigned"
  #   repo     => project path from X-GitLab-Project-Path header
  #   summary  => "{person} added as assignee on MR !{iid} ({project})"
  #   link     => merge request URL from the plain-text body
  class MrReassigned < Base
    def self.matches?(mail)
      body = mail.text_part&.decoded || mail.body.decoded
      mail.header['X-GitLab-MergeRequest-IID']&.value.present? &&
        body.lstrip.lines.first.to_s.match?(/Reassigned merge request/i)
    end

    def attributes
      mr_iid  = gitlab_header('MergeRequest-IID')
      repo    = gitlab_header('Project-Path')
      person  = extract_added_assignee
      proj    = project_name

      summary_parts = if person.present?
        ["#{person} added as assignee on MR !#{mr_iid}"]
      else
        ["MR !#{mr_iid} reassigned"]
      end
      summary_parts << "(#{proj})" if proj.present?

      {
        reason:  :mr_reassigned,
        title:   "MR !#{mr_iid} reassigned",
        repo:    repo,
        summary: summary_parts.join(' '),
        link:    mr_link
      }
    end

    private

    # Extracts the name of the person added as assignee.
    # Body line: "Alice Smith was added as an assignee."
    def extract_added_assignee
      text_body[/^(.+?) was added as an? assignee/i, 1]
    end

    def mr_link
      extract_link(%r{https?://\S+/-/merge_requests/\d+})
    end
  end
end
