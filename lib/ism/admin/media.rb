if defined?(ActiveAdmin)
  ActiveAdmin.register Ism::Media do
    filter :author_username_contains, :as => :string
    filter :author_name_contains, :as => :string
    filter :tag_list_contains, :as => :string
    filter :type, :as => :check_boxes, :collection => proc { Media.select("type").group("type").all.collect(&:type) }

    # config.batch_actions = false

    actions :index, :show, :update, :destroy


    config.sort_order = "posted_at_desc"
    index :as => :grid, :columns => 5 do |media|
      div :for => media do
        resource_selection_cell media
        div link_to(image_tag("#{media.content_url}", :width => 200), admin_medium_path(:id => media), :target => '_blank')
      end
    end

    show do
      render "form"
    end

    controller do
      with_role :admin

      def update
        params[:media] ||= {}
        params[:media].merge!(params.delete(:instagram_media)) if params[:instagram_media]
        super update
      end
    end
  end
end