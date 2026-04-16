# frozen_string_literal: true

# Specs for NotificationHandlers::MrDiscussionsResolved
#
# Fixture:
#   mr_discussions_resolved.eml  – "All discussions were resolved by" notification on MR !199

RSpec.describe NotificationHandlers::MrDiscussionsResolved do
  include ActionMailbox::TestHelper

  let(:user) do
    User.create!(
      uid: 'test-uid-1',
      name: 'Test User',
      username: 'testuser',
      email: 'user@example.com',
      email_prefix: 'abc123def456abc1'
    )
  end

  before do
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
  end

  # ------------------------------------------------------------------
  # .matches?
  # ------------------------------------------------------------------

  describe '.matches?' do
    context 'with a discussions_resolved fixture' do
      let(:mail) { receive_inbound_email_from_fixture('mr_discussions_resolved.eml').mail }

      it 'returns true' do
        expect(described_class.matches?(mail)).to be true
      end
    end

    context 'with a discussion fixture' do
      let(:mail) { receive_inbound_email_from_fixture('mr_discussion_1.eml').mail }

      it 'returns false' do
        expect(described_class.matches?(mail)).to be false
      end
    end

    context 'with a pipeline failed fixture' do
      let(:mail) { receive_inbound_email_from_fixture('pipeline_failed.eml').mail }

      it 'returns false' do
        expect(described_class.matches?(mail)).to be false
      end
    end
  end

  # ------------------------------------------------------------------
  # Fixture: mr_discussions_resolved.eml
  # ------------------------------------------------------------------

  describe 'mr_discussions_resolved.eml' do
    subject(:inbound_email) { receive_inbound_email_from_fixture('mr_discussions_resolved.eml') }

    before { user }

    it 'delivers the inbound email successfully' do
      expect(inbound_email).to have_been_delivered
    end

    it 'creates a Notification for the user' do
      expect { inbound_email }.to change { user.notifications.count }.by(1)
    end

    it 'sets reason to discussions_resolved' do
      inbound_email
      expect(user.notifications.last.reason).to eq('discussions_resolved')
    end

    it 'captures the merge request link' do
      inbound_email
      expect(user.notifications.last.link).to match(%r{/-/merge_requests/199})
    end

    it 'captures the repository path' do
      inbound_email
      expect(user.notifications.last.repo).to eq('my-group/my-project')
    end

    it 'builds a summary with the MR IID' do
      inbound_email
      expect(user.notifications.last.summary).to include('MR !199')
    end

    it 'includes the actor in the summary' do
      inbound_email
      expect(user.notifications.last.summary).to include('A Reviewer')
    end

    it 'builds a title referencing the IID' do
      inbound_email
      expect(user.notifications.last.title).to include('!199')
    end

    it 'stores the unsubscribe link from the List-Unsubscribe header' do
      inbound_email
      expect(user.notifications.last.unsubscribe_link).to include('gitlab.example.com/-/sent_notifications/')
    end

    it 'stores the message_id on the notification' do
      inbound_email
      expect(user.notifications.last.message_id).to be_present
    end
  end
end
