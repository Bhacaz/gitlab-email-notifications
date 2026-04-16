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
  #   reason   => :mr_discussion
  #   title    => "{actor} started a discussion – !{iid}"
  #   repo     => project path from X-GitLab-Project-Path header
  #   summary  => "New discussion on {file} in MR !{iid} ({project})"
  #   link     => note anchor URL from the plain-text body
  class MrDiscussion < Base
    def self.matches?(mail)
      body = mail.text_part&.decoded || mail.body.decoded
      mail.header['X-GitLab-MergeRequest-IID']&.value.present? &&
        body.lstrip.lines.first.to_s.match?(/started a new discussion/i)
    end

    def attributes
      mr_iid = gitlab_header('MergeRequest-IID')
      repo   = gitlab_header('Project-Path')
      actor  = extract_actor || 'Someone'
      file   = extract_file_from_body
      proj   = project_name

      {
        reason: :mr_discussion,
        title: "#{actor} started a discussion \u2013 !#{mr_iid}",
        repo: repo,
        summary: build_summary(mr_iid, file, proj),
        link: mr_note_link
      }
    end

    private

    def build_summary(mr_iid, file, proj)
      parts = ["New discussion on MR !#{mr_iid}"]
      parts << "on #{file}" if file.present?
      parts << "(#{proj})" if proj.present?
      parts.join(' ')
    end

    def mr_note_link
      extract_link(%r{https?://\S+/-/merge_requests/\d+#note_\d+})
    end
  end
end
