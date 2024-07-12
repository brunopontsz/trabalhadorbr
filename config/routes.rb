Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "job_rescissions#index"

  get "9f5299631ffb17ae1cf1ca0bf4f29261", to: "qr_codes#index"

  resource :leads, only: [ :create ]
  resource :whatsapp_messages, only: [ :create ]
end
