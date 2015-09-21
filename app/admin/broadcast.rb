ActiveAdmin.register Broadcast do

  controller do
    def destroy
      destroy! { admin_request_line_item_path(@broadcast.line_item.request, @broadcast.line_item) }
    end
  end

end
