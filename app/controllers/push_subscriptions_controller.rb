# frozen_string_literal: true

class PushSubscriptionsController < ApplicationController
  def create
    endpoint = subscription_params[:endpoint]
    keys     = subscription_params[:keys] || {}

    sub = current_user.push_subscriptions.find_or_initialize_by(endpoint: endpoint)
    sub.assign_attributes(p256dh: keys[:p256dh], auth: keys[:auth])

    if sub.save
      head :created
    else
      render json: { errors: sub.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    endpoint = params[:endpoint]
    current_user.push_subscriptions.find_by(endpoint: endpoint)&.destroy
    head :no_content
  end

  private

  def subscription_params
    params.expect(push_subscription: [:endpoint, { keys: %i[p256dh auth] }])
  end
end
