# frozen_string_literal: true

class MuteRulesController < ApplicationController
  before_action :set_mute_rules, only: :index
  before_action :set_notification, only: :create
  before_action :set_mute_rule, only: :destroy

  def index; end

  def create
    rule_type = params.require(:rule_type)
    value = @notification.mute_rule_value(rule_type)

    if value.blank? || !MuteRule.rule_types.key?(rule_type)
      redirect_to root_path, alert: 'Mute rule is not available for this notification.'
      return
    end

    current_user.mute_rules.find_or_create_by!(rule_type: rule_type, value: value) do |mute_rule|
      mute_rule.display_name = @notification.mute_rule_display_name(rule_type)
    end
    @notification.status_done!

    respond_to do |format|
      format.turbo_stream { render turbo_stream: notification_turbo_streams }
      format.html { redirect_to root_path, notice: 'Mute rule added.' }
    end
  end

  def destroy
    @mute_rule.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'mute-rules-list',
          partial: 'mute_rules/list',
          locals: { mute_rules: current_user.mute_rules.ordered }
        )
      end
      format.html { redirect_to mute_rules_path, notice: 'Mute rule removed.' }
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:notification_id])
  end

  def set_mute_rule
    @mute_rule = current_user.mute_rules.find(params[:id])
  end

  def set_mute_rules
    @mute_rules = current_user.mute_rules.ordered
  end

  def notification_turbo_streams
    remaining = current_user.notifications.visible_filters(**notification_filters)

    [
      turbo_stream.replace(
        'notifications-sidebar',
        partial: 'home/sidebar_filters',
        locals: Notification.sidebar_locals_for(current_user, **active_filter_locals)
      ),
      notification_list_stream(remaining)
    ]
  end

  def notification_filters
    { reason: params[:reason], repo: params[:repo], status: params[:status] }
  end

  def active_filter_locals
    { active_reason: params[:reason], active_repo: params[:repo], active_status: params[:status] }
  end

  def notification_list_stream(remaining)
    return turbo_stream.remove("notification_#{@notification.id}") if remaining.any?

    turbo_stream.replace(
      'notification-list',
      partial: 'home/notification_list',
      locals: { notifications: remaining }.merge(active_filter_locals)
    )
  end
end
