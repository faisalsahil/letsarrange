LetsArrange::Application.routes.draw do
  match '*a', to: redirect('/mailnet/index.html'), via: [:get, :post], constraints: { host: ENV['MAILNET_APP_DOMAIN'] }

  ActiveAdmin.routes(self)
  devise_for :users, controllers: {
    registrations: :registrations,
    passwords: :passwords,
    sessions: :sessions
  }

  devise_scope :user do
    get 'voice_password/:token', to: 'passwords#after_voice_reset', as: :voice_password
  end

  resources :users, except: :show

  resources :organizations, except: :show do
    resources :users, except: [:show], controller: 'organizations/users' do
      member do
        patch :set_default
        patch :trust
      end
    end
    resources :resources, except: [:show], controller: 'organizations/resources' do
      member do
        patch :set_default
        patch :link_org
      end
    end
    collection do
      get :by_id
      get :by_contact_point
      get :trusted
      get "/organization_resources", to: "organization_resources#index"
      get "/organization_users", to: "organization_users#index"
      post "/organization_resources/find_or_create", to: "organization_resources#find_or_create"
    end
    patch :unlink
    :visibility.tap { |url| patch "#{ url }/:private", to: url, as: url }
  end

  resources :recipients, only: [:create]
  resources :resources, only: [:index]

  resources :requests do
    resources :line_items
    patch :close
  end

  resources :inbound_numbers, only: [] do
    patch :merge
  end

  devise_for :contact_points, class_name: 'ContactPoint::Email', controllers: { confirmations: :email_verifications }
  resources :contact_points, only: [:index, :create, :destroy] do
    collection do
      get :for_privacy_options
      post :create_both
    end
    patch :enable
    patch :disable
    patch :enable_notifications
    patch :destination
    get :refresh
    resource :sms_verification, only: [:new, :create]
    resource :voice_verification, only: [:new, :create, :destroy] do
      get :show_modal
    end
  end

  resources :contact_point_voices, only: :create

  scope '/line_items', controller: :line_items do
    get :received, as: :received_line_items
  end

  root to: 'requests#index'

  get '/help',    to: 'static#help'
  get '/about',   to: 'static#about'
  get '/terms',   to: 'static#terms'
  get '/contact', to: 'static#contact'

  namespace :communication do
    post "/sms/inbound", to: "sms#inbound"
    post '/voice/inbound', to: 'voice#inbound'
    post '/voice/reset_password', to: 'voice#reset_password'
    post '/voice/cancel_call', to: 'voice#cancel_call'
    post '/email/inbound', to: 'email#inbound'

    resource :voice_broadcast, only: [] do
      post :announce
      post :opening_call
      post :opening_call_actions
    end
  end

  # Concerns and 'admin' namespace hack routes to activeadmin support of 'polymorphic' models
  concern :line_itemeable do
    resources :line_items, controller: 'line_items'
  end
  concern :url_mappeable do
    resources :url_mappings, controller: 'url_mappings'
  end
  concern :requesteable do
    resources :requests, controller: 'requests'
  end
  namespace :admin do
    resources :requests, concerns: :line_itemeable do
      resources :inbound_numbers, only: :index
    end
    resources :resources, concerns: :line_itemeable
    resources :organization_resources, concerns: :line_itemeable
    resources :users, concerns: [:url_mappeable, :requesteable]
    resources :contact_points, concerns: :url_mappeable
    resources :twilio_numbers, only: [] do
      resources :phone_mappings, only: :index
    end
  end

  get '/:phone', to: 'requests#new_with_contact', constraints: { phone: /\+\d{11}/ }
  get '/:email', to: 'requests#new_with_contact', constraints: { email: /\+[^@\s]+@([^@\s]+\.)+[^@\s]+/ }
  get '/:ouid', to: 'requests#new_with_organization', constraints: { ouid: /\+[a-zA-Z0-9\-]+/ }
  get '/:code', to: 'url_mappings#show', as: :url_mapping, constraints: { code: /\S{#{ UrlMapping::CODE_LENGTH }}/ }
end
