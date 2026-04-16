# frozen_string_literal: true

module NotificationHandlers
  # Handles GitLab MR "commented" notification emails.
  #
  # Detection: X-GitLab-MergeRequest-IID header is present AND the plain-text
  # body first line contains "commented" (either a top-level review comment or
  # a reply to an existing discussion thread).
  #
  # Body patterns handled:
  #   "Alice commented: https://…"
  #   "Alice commented on a discussion on path/to/file.yaml: https://…"
  #   "Alice commented on the merge request\n\nhttps://…"
  #
  # Extracted fields:
  #   reason   => :mr_comment
  #   title    => "{actor} commented – !{iid}"
  #   repo     => project path from X-GitLab-Project-Path header
  #   summary  => "{actor} commented on MR !{iid} [{on file}] ({project})"
  #   link     => note anchor URL from the plain-text body
  class MrComment < Base
    def self.matches?(mail)
      body = mail.text_part&.decoded || mail.body.decoded
      mail.header['X-GitLab-MergeRequest-IID']&.value.present? &&
        body.lstrip.lines.first.to_s.match?(/\bcommented\b/i)
    end

    def attributes
      mr_iid = gitlab_header('MergeRequest-IID')
      repo   = gitlab_header('Project-Path')
      actor  = extract_actor || 'Someone'
      file   = extract_file_from_body
      proj   = project_name

      {
        reason: :mr_comment,
        title: "#{actor} commented \u2013 !#{mr_iid}",
        repo: repo,
        summary: build_summary(actor, mr_iid, file, proj),
        link: mr_note_link
      }
    end

    private

    def build_summary(actor, mr_iid, file, proj)
      parts = ["#{actor} commented on MR !#{mr_iid}"]
      parts << "on #{file}" if file.present?
      parts << "(#{proj})" if proj.present?
      parts.join(' ')
    end

    def mr_note_link
      extract_link(%r{https?://\S+/-/merge_requests/\d+#note_\d+})
    end
  end
end
