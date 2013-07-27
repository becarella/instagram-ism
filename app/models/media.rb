# == Schema Information
#
# Table name: media
#
#  id              :integer          not null, primary key
#  author_username :string(255)
#  author_name     :string(255)
#  type            :string(255)
#  source_id       :string(255)
#  content_url     :string(255)
#  page_url        :string(255)
#  content_width   :integer
#  content_height  :integer
#  posted_at       :datetime
#  caption         :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Media < ActiveRecord::Base
 
  acts_as_paranoid
  acts_as_taggable_on :tags, :original_tags
  
  belongs_to :location
  
  scope :tag_list_contains, lambda {|tags| Media.tagged_with(tags, :on => :tags) }
  search_methods :tag_list_contains
  
  scope :featured, where("featured_at is not null")
  
  attr_accessible :tag_list
  
  before_create :init_tag_list
  
  def init_tag_list
    self.tag_list = self.original_tag_list
  end
 
  class << self
    
    def populate
      raise "TODO: implement in subclass of media"
    end
  end
end
