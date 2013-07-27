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

class InstagramMedia < Media
  class << self
    
    def banned_tags ban_filename
      @banned_tags ||= File.read(ban_filename).split(/$/).map{|bt| bt.gsub(/[#\s]/, '').strip }
    end
    
    
    # Get tagged media in reverse chronological order
    # http://instagram.com/developer/endpoints/tags/#get_tags_media_recent
    # Options:
    #   direction: 
    #     before - Return media after/newer than the saved max_id
    #     after -  Return media before/older than the saved min_id
    #   ban_filename -- name of file with banned tags
    def populate_from_tag tag, options={}
      tag = tag.gsub(/[#\s]/, '')
      Rails.logger.info "[populate_from_tag][##{tag}][#{options[:direction]}] ==========================="
      
      access_token_setting = MediaSetting.where(:source => 'Instagram').where("key like '%access_token'").order("updated_at asc").first
      access_token_setting.touch
      client = Instagram.client(:access_token => access_token_setting.value)

      Rails.logger.info "[populate_from_tag][##{tag}][#{options[:direction]}] IMPORTING TAG: #{tag} with #{access_token_setting.key}"
      
      # Get images newer than the most recent saved photo
      next_key = 'next_max_tag_id'
      options[:direction] ||= 'after'
      if options[:direction].to_s == 'after'
        start_value = MediaSetting.find_or_create_by_source_and_key('Instagram', "#{tag}_max_tag_id")
        args = start_value.nil? ? {} : {:min_id => start_value.value}
        
      # Get images older than the oldest saved photo
      else # direction == 'before'
        start_value = MediaSetting.find_or_create_by_source_and_key('Instagram', "#{tag}_min_tag_id")
        args = start_value.nil? ? {} : {:max_id => start_value.value}
      end
      args.merge!(:count => 100)
      
      import_max = nil
      import_min = nil
      
      min = MediaSetting.find_or_create_by_source_and_key('Instagram', "#{tag}_min_tag_id")
      max = MediaSetting.find_or_create_by_source_and_key('Instagram', "#{tag}_max_tag_id")
      Rails.logger.info "[populate_from_tag][##{tag}] IMPORT RANGE BEFORE: #{min.value.inspect} - #{max.value.inspect}"
      
      (options[:pages].to_i || 10).times do |count|
        data = client.tag_recent_media(tag, args)
        Rails.logger.info "[populate_from_tag][##{tag}][#{count}] #{args.inspect} RX count: #{data.count}"
        
        data.each do |d|
          photo = create_from_instagram_response d, options
        end

        if import_min.nil? || import_min.to_i > data.pagination['next_max_tag_id'].to_i
          import_min = data.pagination['next_max_tag_id']
        end
        if import_max.nil? || import_max.to_i < data.pagination['min_tag_id'].to_i
          import_max = data.pagination['min_tag_id']
        end
        next_value = data.pagination['next_max_tag_id']
        if next_value.nil? 
          break
        elsif options[:direction].to_s == 'after' && (max.value && max.value.to_i > import_min.to_i)
          break
        end
        args[:max_id] = next_value
      end
      
      # Update keys after batch update is successful. If it failes, we'll end up requesting duplicates, but our
      # keys won't have gaps in them
      min.value = import_min if min.value.nil? || min.value.to_i > import_min.to_i
      min.save
      max.value = import_max if max.value.nil? || max.value.to_i < import_max.to_i
      max.save
      Rails.logger.info "[populate_from_tag][##{tag}] IMPORT RANGE AFTER: #{min.value} - #{max.value}"
    end
  
  
    def populate_from_user username
      client = Instagram.client(:access_token => MediaSetting.where(:source => 'Instagram')
                                                             .where("key like '%access_token'")
                                                             .first.value)
      user = client.user_search(username, {:count => 1})[0]
      args = {}
      100.times do
        data = client.user_recent_media(user.id, args)
        data.each do |d|
          photo = create_from_instagram_response d
          break if !photo.new_record?
        end
        break if data.pagination.to_hash['next_max_id'].nil?
        args = { :max_id => data.pagination.to_hash['next_max_id'] }
      end
    end
  
  
    def create_from_instagram_response data, options
      if options[:ban_filename]
        banned_list = banned_tags(options[:ban_filename])
        return if (data.tags & (banned_list)).length > 0
      end
      
      if data.location
        location = Location.find_or_create_by_latitude_and_longitude(
          :latitude => data.location['latitude'], 
          :longitude => data.location['longitude']) do |loc|
            loc.name = data.location['name']
        end
      end
      
      p = InstagramMedia.with_deleted.find_or_create_by_type_and_source_id(self.name, data.id) do |photo|
        photo.author_username = data.user.username
        photo.author_name = data.user.full_name
        photo.page_url = data.link
        photo.content_url = data.images['standard_resolution']['url']
        photo.content_width = data.images['standard_resolution']['width']
        photo.content_height = data.images['standard_resolution']['height']
        photo.source_id = data.id
        photo.posted_at = DateTime.strptime(data.created_time,'%s')
        photo.caption = data.caption ? data.caption.text : nil
        photo.original_tag_list = data.tags
        photo.location = location
      end
    end
  
  end
end
