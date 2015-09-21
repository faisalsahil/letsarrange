module ApplicationHelper
  
  # Returns the full title on a per-page basis.
  def full_title page_title
    base_title = "Lets arrange"

    if page_title.empty?
      base_title + " | Your personal appointment assistant - anything, anyone, any way you want"
    else
      "#{base_title} | #{page_title}"
    end
  end

  def bootstrap_class_for flash_type
    case flash_type
      when :alert
        "warning"
      when :notice
        "success"
      when :error
        'danger'
      else
        flash_type.to_s
    end
  end

  def display_text user
    name = user.name || user.uniqueid
    name + " (" + user.uniqueid + ")"
  end

  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def conditional_tag(tag, condition, options = {}, &block)
    if condition
      content_tag(tag.to_sym, options, &block)
    else
      capture(&block)
    end
  end

  def phone_input(form, current_value)
    form.input :phone,
               label: false,
               required: false,
               input_html: { type: 'tel', class: 'form-control', data: { mask: '(999) 999-9999' }, value: current_value },
               placeholder: 'Phone',
               wrapper: false
  end

  def header_content(title, &block)
    content_for(:navbar) { "<h1>#{ title }</h1>#{ capture(&block) if block_given? }".html_safe }
  end

  def render_page(number, form=nil)
    render partial: "requests/pages/page_#{number}", locals: { f: form }
  end

end
