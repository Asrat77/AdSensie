class ClickhouseSyncService
  def self.sync_all
    Rails.logger.info "Starting ClickHouse sync..."
    sync_channels
    sync_posts
    Rails.logger.info "ClickHouse sync completed"
  end
  
  def self.sync_channels
    Rails.logger.info "Syncing channels to ClickHouse..."
    
    Channel.find_in_batches(batch_size: 1000) do |batch|
      values = batch.map do |channel|
        created_at = channel.created_at.strftime('%Y-%m-%d %H:%M:%S')
        updated_at = channel.updated_at.strftime('%Y-%m-%d %H:%M:%S')
        
        "(#{channel.id}, '#{escape_sql(channel.telegram_id)}', '#{escape_sql(channel.username)}', " \
        "'#{escape_sql(channel.title)}', #{channel.subscriber_count || 0}, #{channel.avg_views || 0}, " \
        "#{channel.avg_engagement_rate || 0}, #{channel.growth_rate || 0}, #{channel.post_frequency || 0}, " \
        "'#{created_at}', '#{updated_at}')"
      end.join(',')
      
      sql = <<~SQL
        INSERT INTO adsensie_analytics.channels_analytics 
        (id, telegram_id, username, title, subscriber_count, avg_views, avg_engagement_rate, 
         growth_rate, post_frequency, created_at, updated_at)
        VALUES #{values}
      SQL
      
      execute_clickhouse(sql)
    end
    
    Rails.logger.info "Synced #{Channel.count} channels"
  end
  
  def self.sync_posts
    Rails.logger.info "Syncing posts to ClickHouse..."
    
    Post.find_in_batches(batch_size: 5000) do |batch|
      values = batch.map do |post|
        posted_at = post.posted_at.strftime('%Y-%m-%d %H:%M:%S')
        created_at = post.created_at.strftime('%Y-%m-%d %H:%M:%S')
        
        "(#{post.id}, #{post.channel_id}, '#{escape_sql(post.telegram_message_id)}', " \
        "#{post.views || 0}, #{post.forwards || 0}, #{post.replies || 0}, " \
        "'#{posted_at}', '#{created_at}')"
      end.join(',')
      
      sql = <<~SQL
        INSERT INTO adsensie_analytics.posts_analytics 
        (id, channel_id, telegram_message_id, views, forwards, replies, posted_at, created_at)
        VALUES #{values}
      SQL
      
      execute_clickhouse(sql)
    end
    
    Rails.logger.info "Synced #{Post.count} posts"
  end
  
  private
  
  def self.escape_sql(string)
    return '' if string.nil?
    string.to_s.gsub("'", "''").gsub('"', '\"')
  end

  def self.execute_clickhouse(query)
    # Use docker exec to run clickhouse-client
    # We use the adsensie user we created
    command = "docker exec clickhouse-server clickhouse-client --user adsensie --query \"#{query.gsub('"', '\"')}\""
    
    output = `#{command}`
    
    unless $?.success?
      Rails.logger.error "ClickHouse query failed: #{output}"
      raise "ClickHouse query failed"
    end
  end
end
