module RequestsHelper

  def cp_options_for_select_for_user(user)
    collection = if user
      user.sorted_preferred_contacts.map{|cp| [cp.to_s,cp.id]}.uniq(&:first)
    else
      [ ["Show my phone",'-1'], ["Show my email",'-2'] ]
    end

    collection + [["Don't share contact details",'']]
  end

end