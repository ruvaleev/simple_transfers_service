Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  resource :session, only: [], controller: 'sessions' do
    post :switch
  end

  resources :orders, only: %i[index new create show] do
    member do
      post :confirm
      post :cancel
    end
  end

  root 'orders#index'
end
