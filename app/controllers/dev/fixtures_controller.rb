# frozen_string_literal: true

module Dev
  class FixturesController < ApplicationController
    FIXTURE_DIR = Rails.root.join('spec/fixtures/files')

    # Fixtures that don't make sense to "send to yourself" in dev
    EXCLUDED = %w[unknown_sender.eml].freeze

    DESCRIPTIONS = {
      'confirmation.eml' => 'Email confirmation (first)',
      'confirmation_second.eml' => 'Email confirmation (second)',
      'pipeline_failed.eml' => 'Pipeline failed',
      'pipeline_fixed.eml' => 'Pipeline fixed',
      'mr_discussion_1.eml' => 'MR discussion – inline diff on mos-fhir-event.module.ts (MR !199)',
      'mr_discussion_2.eml' => 'MR discussion – inline diff on environment.ts (MR !199)',
      'mr_comment_1.eml' => 'MR comment – top-level review comment (MR !199)'
    }.freeze

    def index
      @fixtures = FIXTURE_DIR
                  .glob('*.eml')
                  .map { |p| p.basename.to_s }
                  .reject { |name| EXCLUDED.include?(name) }
                  .sort
                  .map do |name|
                    {
                      name: name,
                      description: DESCRIPTIONS.fetch(name, name)
                    }
                  end
    end

    def deliver
      name = params.require(:name)
      raise ArgumentError, 'Invalid fixture name' unless name.match?(/\A[\w-]+\.eml\z/)

      path = FIXTURE_DIR.join(name)
      raise ActiveRecord::RecordNotFound, "Fixture not found: #{name}" unless path.exist?

      raw = path.read

      # Rewrite the To: header so ActionMailbox routes to the current user.
      raw = raw.sub(/^To:.*$/i, "To: #{current_user.notification_email}")
      raw = raw.sub(/^Date:.*$/i, "Date: #{Time.current.rfc2822}")

      ActionMailbox::InboundEmail.create_and_extract_message_id!(raw)

      redirect_to dev_fixtures_path, notice: "Fixture \"#{name}\" delivered to #{current_user.notification_email}."
    rescue ArgumentError, ActiveRecord::RecordNotFound => e
      redirect_to dev_fixtures_path, alert: e.message
    end
  end
end
