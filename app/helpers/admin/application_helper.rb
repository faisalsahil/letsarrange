module Admin::ApplicationHelper
  def admin_search_form(search_object, url, fields)
    render 'admin/shared/search_form', search_object: search_object, url: url, fields: fields
  end

  def destroy_row(model_name, *models)
    link_to 'delete', send("admin_#{ model_name }_path", *models), method: :delete, data: { confirm: 'Are you sure?' }
  end
end