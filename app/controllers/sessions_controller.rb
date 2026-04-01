# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create
  skip_before_action :require_login, except: :destroy

  def create
    user = User.from_omniauth(request.env['omniauth.auth'])
    session[:user_id] = user.id
    if user.onboarding&.completed?
      redirect_to root_path, notice: "Signed in as #{user.name}"
    else
      redirect_to onboarding_path, notice: "Signed in as #{user.name}"
    end
  rescue StandardError => e
    redirect_to root_path, alert: "Authentication failed: #{e.message}"
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'Signed out successfully'
  end

  def failure
    redirect_to root_path, alert: "Authentication failed: #{params[:message]}"
  end
end
