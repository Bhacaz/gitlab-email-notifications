# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create
  skip_before_action :require_login, only: %i[new create failure]
  rate_limit to: 10, within: 3.minutes, only: :create

  def new
    redirect_to root_path if user_signed_in?
  end

  def create
    user = User.from_omniauth(request.env['omniauth.auth'])
    session[:user_id] = user.id
    if user.onboarding&.completed?
      redirect_to root_path
    else
      redirect_to onboarding_path
    end
  rescue StandardError => e
    redirect_to sign_in_path, alert: "Authentication failed: #{e.message}"
  end

  def destroy
    session[:user_id] = nil
    redirect_to sign_in_path, notice: 'Signed out successfully'
  end

  def failure
    redirect_to sign_in_path, alert: "Authentication failed: #{params[:message]}"
  end
end
