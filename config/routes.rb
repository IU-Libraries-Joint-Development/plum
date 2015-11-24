Rails.application.routes.draw do
  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)
  mount BrowseEverything::Engine => '/browse'
  blacklight_for :catalog
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }, skip: [:passwords, :registration]
  devise_scope :user do
    get 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end
  mount Hydra::RoleManagement::Engine => '/'

  mount Hydra::Collections::Engine => '/'
  mount CurationConcerns::Engine, at: '/'
  resources :welcome, only: 'index'
  root to: 'welcome#index'
  curation_concerns_collections
  curation_concerns_basic_routes
  curation_concerns_embargo_management

  # Add URL options
  default_url_options Rails.application.config.action_mailer.default_url_options

  get '/concern/scanned_resources/:id/manifest', to: 'curation_concerns/scanned_resources#manifest', as: 'curation_concerns_scanned_resource_manifest', defaults: { format: :json }
  get '/concern/multi_volume_works/:id/manifest', to: 'curation_concerns/multi_volume_works#manifest', as: 'curation_concerns_multi_volume_work_manifest', defaults: { format: :json }
  get '/concern/scanned_resources/:id/pdf', to: 'curation_concerns/scanned_resources#pdf', as: 'curation_concerns_scanned_resource_pdf'
  namespace :curation_concerns, path: :concern do
    resources :scanned_resources, only: [] do
      member do
        get :bulk_label
      end
    end
    get '/scanned_resources/:id/reorder', to: 'scanned_resources#reorder', as: 'scanned_resource_reorder'
    post '/scanned_resources/:id/reorder', to: 'scanned_resources#save_order'
    post '/scanned_resources/:id/browse_everything_files', to: 'scanned_resources#browse_everything_files', as: 'scanned_resource_browse_everything_files'
  end

  namespace :curation_concerns, path: :concern do
    resources :scanned_resources, only: [:new, :create], path: 'container/:parent_id/scanned_resources', as: 'member_scanned_resource'
  end
end
