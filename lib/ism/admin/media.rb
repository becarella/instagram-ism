if defined?(ActiveAdmin)
  ActiveAdmin.register Ism::Media do
    filter :author_username_contains, :as => :string
    filter :author_name_contains, :as => :string
    filter :tag_list_contains, :as => :string
    filter :type, :as => :check_boxes, :collection => proc { Media.select("type").group("type").all.collect(&:type) }

    config.batch_actions = false

    actions :index, :show, :update, :destroy


    config.sort_order = "posted_at_desc"
    index :as => :grid, :columns => 3 do |media|
      div :for => media do
        div :class => 'item' do 
          div link_to(image_tag("#{media.content_url}", :width => 200), admin_medium_path(:id => media), :target => '_blank'), :class => 'image'
        end
      end
    end

    show do
      render "form"
    end

    member_action :feature, :method => :put do
      @media = Media.find(params[:id])
      if !params[:featured].blank?
        @media.featured_at = params[:featured] == 'true' ? Time.now : nil
        @media.save
      end
      respond_to do |format|
        format.html { redirect_to admin_medium_path(@media) }
        format.json { render :json => @media.as_json }
      end
    end

    controller do
      with_role :admin
      
      def update
        @media = Media.find(params[:id])
        if params[:media][:featured]
          @media.featured_at = Time.now
        else
          @media.featured_at = nil
        end
        @media.tag_list = params[:media][:tag_list]
        @media.save
        super
      end
    end
  end
end