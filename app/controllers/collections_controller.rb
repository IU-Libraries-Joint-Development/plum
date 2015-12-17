class CollectionsController < ApplicationController
  include CurationConcerns::CollectionsControllerBehavior

  def form_class
    CollectionEditForm
  end

  def presenter_class
    CollectionShowPresenter
  end

  def manifest
    respond_to do |f|
      f.json do
        render json: manifest_builder
      end
    end
  end

  private

    def manifest_builder
      ManifestBuilder.new(presenter, ssl: request.ssl?, services: AuthManifestBuilder.auth_services(login_url, logout_url))
    end

    def login_url
      main_app.user_omniauth_authorize_url(:cas)
    end

    def logout_url
      current_user.nil? ? nil : main_app.destroy_user_session_url
    end
end
