# == Schema Information
#
# Table name: media_settings
#
#  id     :integer          not null, primary key
#  source :string(255)
#  key    :string(255)
#  value  :string(255)
#

class MediaSetting < ActiveRecord::Base
  
  attr_accessible :value
end