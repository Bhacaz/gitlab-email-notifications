# frozen_string_literal: true

module NotificationHandlers
  class MrMerged < Base
    def self.matches?(mail)
      body = mail.text_part&.decoded || mail.body.decoded
      mail.header['X-GitLab-MergeRequest-IID']&.value.present? &&
        body.lstrip.lines.first.to_s.match?(/Merge request .* was merged/i)
    end

    def attributes
      mr_iid = gitlab_header('MergeRequest-IID')
      repo   = gitlab_header('Project-Path')
      author = extract_author || 'Someone'
      proj   = project_name

      {
        reason: :merged,
        title: "!#{mr_iid} merged",
        repo: repo,
        summary: "MR !#{mr_iid} merged by #{author}#{" (#{proj})" if proj}",
        link: mr_link
      }
    end

    private

    def extract_author
      m = text_body.match(/^Author:\s+(.+)$/)
      m&.[](1)&.strip
    end

    def mr_link
      extract_link(%r{https?://\S+/-/merge_requests/\d+})
    end
  end
end
