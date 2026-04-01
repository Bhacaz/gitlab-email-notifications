# frozen_string_literal: true

module Dev
  class SessionsController < ApplicationController
    skip_before_action :require_login

    def create
      user = User.first
      if user
        session[:user_id] = user.id
        redirect_to root_path, notice: "Auto-logged in as #{user.name}"
      else
        render plain: 'No users found. Sign in with GitLab first to create a user.', status: :not_found
      end
    end
  end
end
