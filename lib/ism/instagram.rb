require 'observer' 
require 'instagram'

module Ism
  class Instagram
    extend Observable 
    
    class << self


      # Get tagged media in reverse chronological order
      # http://instagram.com/developer/endpoints/tags/#get_tags_media_recent
      # Options:
      #   direction: 
      #     before - Return media after/newer than the saved max_id
      #     after -  Return media before/older than the saved min_id
      #   per_page -- number of instagrams to return per page, default = 50, max = 100
      #   pages -- number of pages to fetch from instagram, default = 10
      #   ban_filename -- name of file with banned tags
      def import_from_tag tag, options={}
        tag = tag.gsub(/[#\s]/, '')

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
        args.merge!(:count => (options[:per_page] || 50).to_i)

        import_max = nil
        import_min = nil

        min = MediaSetting.find_or_create_by_source_and_key('Instagram', "#{tag}_min_tag_id")
        max = MediaSetting.find_or_create_by_source_and_key('Instagram', "#{tag}_max_tag_id")

        (options[:pages] || 10).to_i.times do |count|
          data = client.tag_recent_media(tag, args)

          data.each do |d|
            add_instagram(d, options)
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

        # Update keys after batch update is successful. If it fails, we'll end up 
        # requesting duplicates, but our keys won't have gaps in them
        min.value = import_min if min.value.nil? || min.value.to_i > import_min.to_i
        min.save
        max.value = import_max if max.value.nil? || max.value.to_i < import_max.to_i
        max.save
      end


      # def populate_from_user username
      #   user = client.user_search(username, {:count => 1})[0]
      #   args = {}
      #   100.times do
      #     data = client.user_recent_media(user.id, args)
      #     data.each do |d|
      #       add_instagram(d, options)
      #     end
      #     break if data.pagination.to_hash['next_max_id'].nil?
      #     args = { :max_id => data.pagination.to_hash['next_max_id'] }
      #   end
      # end
      
      
      # get single instagram by instagram id
      def find id
        add_instagram(client.media_item(id))
      end
      
      
      def add_instagram data, options={}
        if options[:ban_filename]
          banned_list = banned_tags(options[:ban_filename])
          return if (data.tags & (banned_list)).length > 0
        end
        
        formatted_data = {
          source: 'Instagram',
          source_id: data.id,
          permalink: data.link,
          posted_at: DateTime.strptime(data.created_time,'%s'),
          author: {
            username: data.user.username,
            full_name: data.user.full_name
          },
          media_type: data.media_type,
          media: data.images,
          caption: data.caption ? data.caption.text : nil,
          tags: data.tags,
          location: data.location,   # keys: latitude, longitude, name
          raw_data: data
        }
        changed
        notify_observers(Hashie::Mash.new(formatted_data))
      end
    
      # Pull banned tags from given file name
      # TODO: figure out how we really want to store and pass these around, 
      # probably move out to observer
      def banned_tags ban_filename
        @banned_tags ||= File.read(ban_filename).split(/$/).map{|bt| bt.gsub(/[#\s]/, '').strip }
      end
      
      # Get an authorized Instagram client.
      # Round robin select available tokens unless a specific token key is provided
      def client (access_token_key=nil)
        return @client if @client
        where_token = access_token_key ? ["key = ?", access_token_key] : "key like '%access_token'"
        access_token_setting = MediaSetting.where(:source => 'Instagram').
                                            where(where_token).
                                            order("updated_at asc").
                                            first
        raise "Access token not found for where #{where_token}" if access_token_setting.nil?
        access_token_setting.touch
        @client = ::Instagram.client(:access_token => access_token_setting.value)
      end

      def method_missing(method_sym, *arguments, &block)
        ::Instagram.send(method_sym, *arguments, &block)
      end
    end
  end
end
