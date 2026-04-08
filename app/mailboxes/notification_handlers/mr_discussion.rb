# frozen_string_literal: true

module NotificationHandlers
  # Handles GitLab MR "started a new discussion" notification emails.
  #
  # Detection: X-GitLab-MergeRequest-IID header is present AND the plain-text
  # body starts with "started a new discussion".
  #
  # GitLab sends this type when a reviewer opens an inline diff discussion
  # on a file in a merge request.
  #
  # Extracted fields:
  #   reason             => :mr_discussion
  #   title              => mail subject
  #   repo               => project path from X-GitLab-Project-Path header
  #   summary            => "MR !<iid> – started a new discussion"
  #   link               => note anchor URL from the plain-text body
  #   unsubscribe_link   => List-Unsubscribe URL
  class MrDiscussion < Base
    def self.matches?(mail)
      body = mail.text_part&.decoded || mail.body.decoded
      mail.header['X-GitLab-MergeRequest-IID']&.value.present? &&
        body.lstrip.lines.first.to_s.match?(/started a new discussion/i)
    end

    def attributes
      mr_iid = gitlab_header('MergeRequest-IID')
      repo   = gitlab_header('Project-Path')

      {
        reason: :mr_discussion,
        title: mail.subject,
        repo: repo,
        summary: "MR !#{mr_iid} \u2013 started a new discussion",
        link: mr_note_link,
        unsubscribe_link: unsubscribe_link
      }
    end

    private

    def mr_note_link
      extract_link(%r{https?://\S+/-/merge_requests/\d+#note_\d+})
    end
  end
end
