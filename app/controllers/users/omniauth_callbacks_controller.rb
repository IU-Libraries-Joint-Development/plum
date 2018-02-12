class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def cas
    # You need to implement the method below in your model (e.g.
    # app/models/user.rb)
    @user = User.from_omniauth(request.env["omniauth.auth"])
    @user.authorized_ldap_member?(:force) unless
      Plum.config[:authorized_ldap_groups].blank?

    # this will throw if @user is not activated
    sign_in_and_redirect @user, event: :authentication

    set_flash_message(:notice, :success, kind: "CAS") if
      is_navigational_format?
  end
end
