Rails.application.routes.draw do
  namespace :v1 do
    resources :connections do
      post 'chatwoot_webhook'
      post 'wpp_connect_webhook'
    end
  end
  namespace :admin do
      resources :connections

      root to: "connections#index"
    end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
