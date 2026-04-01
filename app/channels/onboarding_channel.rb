# frozen_string_literal: true

class OnboardingChannel < ApplicationCable::Channel
  def subscribed
    stream_from "onboarding_#{current_user.id}"
  end

  def unsubscribed; end
end
