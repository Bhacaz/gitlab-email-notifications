# frozen_string_literal: true

class OnboardingsController < ApplicationController
  def show
    redirect_to root_path if current_user.onboarding&.completed?

    @onboarding = current_user.onboarding || current_user.build_onboarding
  end

  def update
    current_user.onboarding&.completed!
    respond_to do |format|
      format.json { head :ok }
      format.html { redirect_to root_path, notice: "You're all set! Notifications are now active." }
    end
  end
end
