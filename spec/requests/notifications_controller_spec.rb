# frozen_string_literal: true

RSpec.describe 'Notifications' do
  let!(:user) { User.create!(uid: 'u1', email: 'u1@example.com') }

  let!(:failed_a) do
    Notification.create!(user: user, message_id: SecureRandom.hex, reason: :pipeline_failed, repo: 'foo/bar',
                         title: 'a', status: :new)
  end
  let!(:failed_b) do
    Notification.create!(user: user, message_id: SecureRandom.hex, reason: :pipeline_failed, repo: 'foo/bar',
                         title: 'b', status: :seen)
  end
  let!(:fixed) do
    Notification.create!(user: user, message_id: SecureRandom.hex, reason: :pipeline_fixed, repo: 'foo/bar',
                          title: 'c', status: :new)
  end
  before { sign_in_as(user) }

  describe 'PATCH /notifications/mark_all_done' do
    context 'with no filter' do
      it 'marks all visible notifications as done' do
        patch mark_all_done_notifications_path

        expect(response).to have_http_status(:found)
        expect(failed_a.reload).to be_status_done
        expect(failed_b.reload).to be_status_done
        expect(fixed.reload).to be_status_done
      end
    end

    context 'with a reason filter' do
      it 'only marks notifications matching the filter' do
        patch mark_all_done_notifications_path(reason: 'pipeline_failed')

        expect(failed_a.reload).to be_status_done
        expect(failed_b.reload).to be_status_done
        expect(fixed.reload).to be_status_new
      end
    end

    context 'with a repo filter' do
      let!(:other) do
        Notification.create!(user: user, message_id: SecureRandom.hex, reason: :pipeline_failed, repo: 'other/repo',
                             title: 'd', status: :new)
      end

      it 'only marks notifications matching the repo' do
        patch mark_all_done_notifications_path(repo: 'foo/bar')

        expect(failed_a.reload).to be_status_done
        expect(other.reload).not_to be_status_done
      end
    end

    context 'with a status filter' do
      it 'only marks notifications matching the status' do
        patch mark_all_done_notifications_path(status: 'seen')

        expect(failed_b.reload).to be_status_done
        expect(failed_a.reload).to be_status_new
      end
    end

    it 'never marks already-done notifications' do
      failed_a.update!(status: :done)
      patch mark_all_done_notifications_path

      expect(failed_a.reload).to be_status_done
    end
  end
end
