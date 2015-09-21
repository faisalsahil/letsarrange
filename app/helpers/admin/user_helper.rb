module Admin
  module UserHelper
    def user_last_login_info(user)
      if user.last_sign_in_at
        DateHelper.format(user.last_sign_in_at,'UTC') + " from IP: " + user.last_sign_in_ip
      end
    end

    def set_admin_link_to(user)
      if user.admin?
        link_to('Revoke admin rights', set_admin_admin_user_path(user), method: :patch)
      else
        link_to('Grant admin rights', set_admin_admin_user_path(user, enable: true), method: :patch)
      end
    end
  end
end