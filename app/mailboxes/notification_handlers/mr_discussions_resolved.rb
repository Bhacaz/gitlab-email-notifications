# frozen_string_literal: true

module NotificationHandlers
  # Handles GitLab MR "all discussions resolved" notification emails.
  #
  # Detection: X-GitLab-MergeRequest-IID header is present AND the plain-text
  # body first line matches "All discussions .* were resolved by".
  #
  # Extracted fields:
  #   reason   => :discussions_resolved
  #   title    => "All discussions resolved – !{iid}"
  #   repo     => project path from X-GitLab-Project-Path header
  #   summary  => "All discussions on MR !{iid} resolved by {actor} ({project})"
  #   link     => merge request URL from the plain-text body
  class MrDiscussionsResolved < Base
    def self.matches?(mail)
      body = mail.text_part&.decoded || mail.body.decoded
      mail.header['X-GitLab-MergeRequest-IID']&.value.present? &&
        body.lstrip.lines.first.to_s.match?(/All discussions .* were resolved by/i)
    end

    def attributes
      mr_iid = gitlab_header('MergeRequest-IID')
      repo   = gitlab_header('Project-Path')
      actor  = extract_actor || 'Someone'
      proj   = project_name

      {
        reason: :discussions_resolved,
        title: "All discussions resolved \u2013 !#{mr_iid}",
        repo: repo,
        summary: "All discussions on MR !#{mr_iid} resolved by #{actor}#{" (#{proj})" if proj}",
        link: mr_link
      }
    end

    private

    def mr_link
      extract_link(%r{https?://\S+/-/merge_requests/\d+})
    end
  end
end
