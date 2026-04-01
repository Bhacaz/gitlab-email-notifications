# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'home#index'

  resource :onboarding, only: %i[show update]

  # OmniAuth GitLab OAuth routes
  get '/sign_in', to: 'sessions#new', as: :sign_in
  get '/oauth/gitlab/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  delete '/sign_out', to: 'sessions#destroy', as: :sign_out

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get 'manifest' => 'rails/pwa#manifest', as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  mount ActiveStorageDB::Engine => '/active_storage_db'
  scope '/admin' do
    mount SolidQueueDashboard::Engine, at: '/jobs'
    mount SolidApm::Engine, at: '/apm'
  end
end
