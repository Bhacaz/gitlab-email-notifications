# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @notifications = current_user.notifications.visible.order(created_at: :desc)
  end
end
