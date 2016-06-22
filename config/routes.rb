Rails.application.routes.draw do

  get 'api_permissions' => "api_permissions#index"
  get 'api_permissions/adwords/initiate' => "api_permissions#adwords_initiate", as: :adwords_initiate
  get 'api_permissions/adwords/callback' => "api_permissions#adwords_callback", as: :adwords_callback

  get '/auth/auth0/callback' => "auth0#callback"

  get '/auth/failure' => "auth0#failure"


  get '/dashboard' => "dashboards#netsearch_demo"

  get '/login' => "login#show"
  delete '/logout' => "auth0#logout"

  resources :clients, only: [:new, :create], constraints: lambda { |request|
      User.new(request.session[:userinfo]).is_customer?
  }

  resources :clients, except: [:new, :create]

  resources :customers do
    resources :clients, only: [:new, :create], constraints: lambda { |request|
      User.new(request.session[:userinfo]).is_admin?
    }
  end

  root 'dashboards#netsearch_demo'

end
