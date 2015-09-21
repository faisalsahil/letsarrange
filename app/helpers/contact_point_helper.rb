module ContactPointHelper
  def destroy_link(contact_point)
    link_to 'remove', contact_point_path(contact_point), method: :delete, remote: true
  end

  def verify_actions(contact_point, &verify_block)
    if contact_point.disabled?
      "#{ action_link(contact_point, 'enable', :enable) }\n".html_safe
    elsif contact_point.verified?
      "#{ notifications_link(contact_point) }\n<span class='divider'>|</span>
       #{ action_link(contact_point, 'disable', :disable) }\n".html_safe
    else
      capture(&verify_block)
    end
  end

  def notifications_link(contact_point)
    if contact_point.notifiable?
      action_link(contact_point, contact_point.notification_captions(:disable), :enable_notifications, disabled: 1)
    else
      action_link(contact_point, contact_point.notification_captions(:enable), :enable_notifications)
    end
  end

  def action_link(contact_point, caption, action, url_params = {})
    link_to(caption, send("contact_point_#{ action }_path", contact_point, url_params), method: :patch, remote: true)
  end
end