# frozen_string_literal: true

class ApplicationMailbox < ActionMailbox::Base
  routing Regexp.new("@#{Rails.application.credentials.email_domain}", 'i') => :notifications
end
