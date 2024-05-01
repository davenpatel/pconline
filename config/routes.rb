# frozen_string_literal: true

require 'karafka/web'

Rails.application.routes.draw do
  root 'main#show'

  resources :visitors, only: %i[index show]
  resources :attendances, only: %i[index]

  mount Karafka::Web::App, at: '/karafka'
end
