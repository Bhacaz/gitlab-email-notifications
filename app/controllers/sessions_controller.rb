# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def create
    user = User.from_omniauth(request.env['omniauth.auth'])
    session[:user_id] = user.id
    redirect_to root_path, notice: "Signed in as #{user.name}"
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
