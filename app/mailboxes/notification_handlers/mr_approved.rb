# frozen_string_literal: true

module NotificationHandlers
  # Handles GitLab MR "approved" notification emails.
  #
  # Detection: X-GitLab-MergeRequest-IID header is present AND the plain-text
  # body first line matches "Merge request .* was approved".
  #
  # Extracted fields:
  #   reason   => :mr_approved
  #   title    => "{approver} approved – !{iid}"
  #   repo     => project path from X-GitLab-Project-Path header
  #   summary  => "MR !{iid} approved by {approver} ({project})"
  #   link     => merge request URL from the plain-text body
  class MrApproved < Base
    def self.matches?(mail)
      body = mail.text_part&.decoded || mail.body.decoded
      mail.header['X-GitLab-MergeRequest-IID']&.value.present? &&
        body.lstrip.lines.first.to_s.match?(/Merge request .* was approved/i)
    end

    def attributes
      mr_iid   = gitlab_header('MergeRequest-IID')
      repo     = gitlab_header('Project-Path')
      approver = extract_actor || 'Someone'
      proj     = project_name

      {
        reason: :mr_approved,
        title: "#{approver} approved \u2013 !#{mr_iid}",
        repo: repo,
        summary: "MR !#{mr_iid} approved by #{approver}#{" (#{proj})" if proj}",
        link: mr_link
      }
    end

    private

    def mr_link
      extract_link(%r{https?://\S+/-/merge_requests/\d+})
    end
  end
end
