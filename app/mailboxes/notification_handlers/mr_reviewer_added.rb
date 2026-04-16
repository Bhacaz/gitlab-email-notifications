# frozen_string_literal: true

module NotificationHandlers
  # Handles GitLab MR "reviewer added" notification emails.
  #
  # Detection: X-GitLab-MergeRequest-IID header is present AND the plain-text
  # body first line matches "{Name} was added as a reviewer".
  #
  # Extracted fields:
  #   reason   => :reviewer_added
  #   title    => "{person} added as reviewer – !{iid}"
  #   repo     => project path from X-GitLab-Project-Path header
  #   summary  => "Reviewer {person} added to MR !{iid} ({project})"
  #   link     => merge request URL from the plain-text body
  class MrReviewerAdded < Base
    def self.matches?(mail)
      body = mail.text_part&.decoded || mail.body.decoded
      mail.header['X-GitLab-MergeRequest-IID']&.value.present? &&
        body.lstrip.lines.first.to_s.match?(/was added as a reviewer/i)
    end

    def attributes
      mr_iid = gitlab_header('MergeRequest-IID')
      repo   = gitlab_header('Project-Path')
      person = extract_reviewer_name || 'Someone'
      proj   = project_name

      {
        reason: :reviewer_added,
        title: "#{person} added as reviewer \u2013 !#{mr_iid}",
        repo: repo,
        summary: "Reviewer #{person} added to MR !#{mr_iid}#{" (#{proj})" if proj}",
        link: mr_link
      }
    end

    private

    # Body line: "Alice Smith was added as a reviewer."
    def extract_reviewer_name
      first_body_line[/\A(.+?) was added as a reviewer/i, 1]
    end

    def mr_link
      extract_link(%r{https?://\S+/-/merge_requests/\d+})
    end
  end
end
