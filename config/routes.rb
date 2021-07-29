Rails.application.routes.draw do
  resources :counters, only: [:update, :destroy]
end
