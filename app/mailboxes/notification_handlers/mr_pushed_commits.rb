# frozen_string_literal: true

module NotificationHandlers
  # Handles GitLab MR "pushed new commits" notification emails.
  #
  # Detection: X-GitLab-MergeRequest-IID header is present AND the plain-text
  # body first line matches "{actor} pushed new commits to merge request".
  #
  # Extracted fields:
  #   reason   => :pushed_commits
  #   title    => "{actor} pushed to !{iid}"
  #   repo     => project path from X-GitLab-Project-Path header
  #   summary  => "New commits pushed to MR !{iid} ({project})"
  #   link     => merge request URL from the plain-text body
  class MrPushedCommits < Base
    def self.matches?(mail)
      body = mail.text_part&.decoded || mail.body.decoded
      mail.header['X-GitLab-MergeRequest-IID']&.value.present? &&
        body.lstrip.lines.first.to_s.match?(/pushed new commits to merge request/i)
    end

    def attributes
      mr_iid = gitlab_header('MergeRequest-IID')
      repo   = gitlab_header('Project-Path')
      actor  = extract_actor || 'Someone'
      proj   = project_name

      {
        reason: :pushed_commits,
        title: "#{actor} pushed to !#{mr_iid}",
        repo: repo,
        summary: "New commits pushed to MR !#{mr_iid}#{" (#{proj})" if proj}",
        link: mr_link
      }
    end

    private

    def mr_link
      extract_link(%r{https?://\S+/-/merge_requests/\d+})
    end
  end
end
