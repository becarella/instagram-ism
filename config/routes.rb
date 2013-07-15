Ism::Engine.routes.draw do

  match '/oauth/instagram/connect' => 'oauth#connect_instagram', :as => 'instagram_connect'
  match '/oauth/instagram/callback' => 'oauth#callback_instagram', :as => 'instagram_callback'

end
