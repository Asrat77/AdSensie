class TelegramService
  def self.import_channel(username)
    Rails.logger.info "Importing channel: #{username}"
    
    # Execute Python script
    script_path = Rails.root.join('lib', 'telegram', 'fetch_single_channel.py')
    output = `python3 #{script_path} #{username}`
    
    begin
      result = JSON.parse(output)
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse Python script output: #{e.message}"
      return { success: false, error: "Internal error: Failed to fetch data" }
    end
    
    unless result['success']
      return { success: false, error: result['error'] }
    end
    
    channel_data = result['channel']
    posts_data = result['posts']
    
    # Transaction to ensure data consistency
    ActiveRecord::Base.transaction do
      # Create or update channel
      channel = Channel.find_or_initialize_by(telegram_id: channel_data['telegram_id'])
      
      channel.assign_attributes(
        username: channel_data['username'],
        title: channel_data['title'],
        description: channel_data['description'],
        subscriber_count: channel_data['subscriber_count'],
        last_synced_at: Time.current
      )
      
      unless channel.save
        return { success: false, error: channel.errors.full_messages.join(', ') }
      end
      
      # Import posts
      posts_data.each do |post_data|
        post = channel.posts.find_or_initialize_by(
          telegram_message_id: post_data['telegram_message_id']
        )
        
        post.assign_attributes(
          text: post_data['text'],
          views: post_data['views'],
          forwards: post_data['forwards'],
          replies: post_data['replies'],
          posted_at: DateTime.parse(post_data['posted_at'])
        )
        
        post.save!
      end
      
      # Recalculate metrics
      channel.calculate_metrics
      
      # Sync to ClickHouse for dashboard
      ClickhouseSyncService.sync_all
      
      { success: true, channel: channel }
    end
  rescue => e
    Rails.logger.error "Import failed: #{e.message}"
    { success: false, error: e.message }
  end
end
