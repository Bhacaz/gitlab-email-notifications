# frozen_string_literal: true

# Fixtures in spec/fixtures/files/ were exported from the development database
# using script/export_inbound_mail_fixtures.rb and then anonymised. They cover:
#
#   confirmation.eml         – GitLab "Confirmation instructions" email
#   confirmation_second.eml  – A second confirmation email (duplicate token)
#   pipeline_failed.eml      – GitLab CI "Failed pipeline" notification
#   pipeline_fixed.eml       – GitLab CI "Fixed pipeline" notification
#   unknown_sender.eml       – Plain email from an external sender (no handler)
#
# All fixtures are addressed to abc123def456abc1@gitlab.example.com which
# matches the test-credential email_domain ("gitlab.example.com") and the
# user created by the `let(:user)` below.

RSpec.describe NotificationsMailbox, type: :mailbox do
  include ActionMailbox::TestHelper

  # ------------------------------------------------------------------
  # Shared setup
  # ------------------------------------------------------------------

  # The user whose notification address is embedded in every fixture.
  # email_prefix is set explicitly; init_email_prefix only fills it when blank.
  let(:user) do
    User.create!(
      uid: 'test-uid-1',
      name: 'Test User',
      username: 'testuser',
      email: 'user@example.com',
      email_prefix: 'abc123def456abc1'
    )
  end

  # Suppress Turbo broadcasts – they require an ActionCable connection that
  # isn't available in unit tests.
  before do
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
  end

  # ------------------------------------------------------------------
  # Routing
  # ------------------------------------------------------------------

  describe 'routing' do
    it 'routes emails addressed to the notifications domain to NotificationsMailbox' do
      expect(described_class).to receive_inbound_email(
        to: "abc123def456abc1@#{Rails.application.credentials.email_domain}",
        from: 'gitlab@mg.gitlab.example.com',
        subject: 'Hello'
      )
    end
  end

  # ------------------------------------------------------------------
  # Confirmation email
  # ------------------------------------------------------------------

  describe 'confirmation email' do
    subject(:inbound_email) { receive_inbound_email_from_fixture('confirmation.eml') }

    context 'when a matching user exists' do
      before { user } # ensure user is persisted

      it 'delivers the inbound email successfully' do
        expect(inbound_email).to have_been_delivered
      end

      it 'creates an Onboarding record for the user' do
        expect { inbound_email }.to change { user.reload.onboarding }.from(nil)
      end

      it 'sets the onboarding state to awaiting_confirmation' do
        inbound_email
        expect(user.reload.onboarding.state).to eq('awaiting_confirmation')
      end

      it 'stores the confirmation link on the onboarding' do
        inbound_email
        link = user.reload.onboarding.confirmation_link
        expect(link).to include('/-/profile/emails/confirmation')
        expect(link).to include('confirmation_token=')
      end

      it 'stores the message_id on the onboarding' do
        inbound_email
        expect(user.reload.onboarding.message_id).to be_present
      end

      it 'broadcasts an onboarding status update over Turbo' do
        expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
          "onboarding_#{user.id}",
          hash_including(target: 'onboarding-status')
        )
        inbound_email
      end

      context 'when the user already has an onboarding record' do
        before do
          user.create_onboarding!(state: :pending)
        end

        it 'updates the existing onboarding instead of creating a second one' do
          expect { inbound_email }.not_to change(Onboarding, :count)
          expect(user.reload.onboarding.state).to eq('awaiting_confirmation')
        end
      end
    end

    context 'when no matching user exists' do
      it 'delivers the inbound email (mailbox returns early without side-effects)' do
        # No user created – process returns early. ActionMailbox still marks it
        # as delivered because no exception was raised; the mailbox simply did
        # nothing for an unknown recipient.
        expect(inbound_email).to have_been_delivered
      end

      it 'does not create any Onboarding records' do
        expect { inbound_email }.not_to change(Onboarding, :count)
      end
    end
  end

  # ------------------------------------------------------------------
  # Pipeline failed
  # ------------------------------------------------------------------

  describe 'pipeline failed email' do
    subject(:inbound_email) { receive_inbound_email_from_fixture('pipeline_failed.eml') }

    before { user }

    it 'delivers the inbound email successfully' do
      expect(inbound_email).to have_been_delivered
    end

    it 'creates a Notification for the user' do
      expect { inbound_email }.to change { user.notifications.count }.by(1)
    end

    it 'sets reason to pipeline_failed' do
      inbound_email
      notification = user.notifications.last
      expect(notification.reason).to eq('pipeline_failed')
    end

    it 'captures the pipeline link' do
      inbound_email
      notification = user.notifications.last
      expect(notification.link).to include('/-/pipelines/')
    end

    it 'captures the repository path' do
      inbound_email
      notification = user.notifications.last
      expect(notification.repo).to eq('my-group/my-project')
    end

    it 'builds a human-readable summary' do
      inbound_email
      notification = user.notifications.last
      expect(notification.summary).to match(/Pipeline #\d+ failed/)
    end

    it 'stores the unsubscribe link when present in the List-Unsubscribe header' do
      # The pipeline_failed fixture does not include a List-Unsubscribe header,
      # so unsubscribe_link is nil. The handler gracefully handles its absence.
      inbound_email
      notification = user.notifications.last
      expect(notification.unsubscribe_link).to be_nil
    end

    it 'stores the message_id on the notification' do
      inbound_email
      notification = user.notifications.last
      expect(notification.message_id).to be_present
    end
  end

  # ------------------------------------------------------------------
  # Pipeline fixed
  # ------------------------------------------------------------------

  describe 'pipeline fixed email' do
    subject(:inbound_email) { receive_inbound_email_from_fixture('pipeline_fixed.eml') }

    before { user }

    it 'delivers the inbound email successfully' do
      expect(inbound_email).to have_been_delivered
    end

    it 'creates a Notification for the user' do
      expect { inbound_email }.to change { user.notifications.count }.by(1)
    end

    it 'sets reason to pipeline_fixed' do
      inbound_email
      notification = user.notifications.last
      expect(notification.reason).to eq('pipeline_fixed')
    end

    it 'captures the pipeline link' do
      inbound_email
      notification = user.notifications.last
      expect(notification.link).to include('/-/pipelines/')
    end

    it 'captures the repository path' do
      inbound_email
      notification = user.notifications.last
      expect(notification.repo).to eq('my-group/my-project')
    end

    it 'builds a human-readable summary' do
      inbound_email
      notification = user.notifications.last
      expect(notification.summary).to match(/Pipeline #\d+ fixed/)
    end

    it 'stores the unsubscribe link when present in the List-Unsubscribe header' do
      # The pipeline_fixed fixture does not include a List-Unsubscribe header,
      # so unsubscribe_link is nil. The handler gracefully handles its absence.
      inbound_email
      notification = user.notifications.last
      expect(notification.unsubscribe_link).to be_nil
    end
  end

  # ------------------------------------------------------------------
  # Unknown sender (no matching handler)
  # ------------------------------------------------------------------

  describe 'unknown sender email' do
    subject(:inbound_email) { receive_inbound_email_from_fixture('unknown_sender.eml') }

    before { user }

    it 'delivers the inbound email successfully' do
      expect(inbound_email).to have_been_delivered
    end

    it 'creates a Notification with reason other' do
      expect { inbound_email }.to change { user.notifications.count }.by(1)
      expect(user.notifications.last.reason).to eq('other')
    end

    it 'uses the mail subject as the notification title' do
      inbound_email
      expect(user.notifications.last.title).to eq('Test1')
    end
  end
end
