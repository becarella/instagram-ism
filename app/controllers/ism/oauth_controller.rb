module Ism
  class OauthController < ApplicationController
  
    def connect_instagram
      redirect_to Instagram.authorize_url(:redirect_uri => instagram_callback_url)
    end
  
    def callback_instagram
      response = Instagram.get_access_token(params[:code], :redirect_uri => instagram_callback_url)
      client = Instagram.client(:access_token => response.access_token)
      instagram_user = client.user
      ms = MediaSetting.find_or_create_by_source_and_key('Instagram', "#{instagram_user.username}_access_token")
      ms.update_attributes(:value => response.access_token)
      redirect_to admin_media_url
    end
  end
end
