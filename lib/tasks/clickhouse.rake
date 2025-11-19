namespace :clickhouse do
  desc "Sync all data from PostgreSQL to ClickHouse"
  task sync: :environment do
    puts "Starting ClickHouse sync..."
    
    # Sync channels
    puts "Syncing channels..."
    channel_count = 0
    Channel.find_in_batches(batch_size: 1000) do |batch|
      csv_data = batch.map do |c|
        "#{c.id},\"#{c.telegram_id}\",\"#{c.username}\",\"#{c.title}\",#{c.subscriber_count || 0},#{c.avg_views || 0},#{c.avg_engagement_rate || 0},#{c.growth_rate || 0},#{c.post_frequency || 0},\"#{c.created_at.strftime('%Y-%m-%d %H:%M:%S')}\",\"#{c.updated_at.strftime('%Y-%m-%d %H:%M:%S')}\""
      end.join("\n")
      
      IO.popen("docker exec -i clickhouse-server clickhouse-client --query='INSERT INTO adsensie_analytics.channels_analytics FORMAT CSV'", "w") do |pipe|
        pipe.puts csv_data
      end
      
      channel_count += batch.size
      puts "  Synced #{channel_count} channels..."
    end
    
    # Sync posts
    puts "Syncing posts..."
    post_count = 0
    Post.find_in_batches(batch_size: 5000) do |batch|
      csv_data = batch.map do |p|
        "#{p.id},#{p.channel_id},\"#{p.telegram_message_id}\",#{p.views || 0},#{p.forwards || 0},#{p.replies || 0},\"#{p.posted_at.strftime('%Y-%m-%d %H:%M:%S')}\",\"#{p.created_at.strftime('%Y-%m-%d %H:%M:%S')}\""
      end.join("\n")
      
      IO.popen("docker exec -i clickhouse-server clickhouse-client --query='INSERT INTO adsensie_analytics.posts_analytics FORMAT CSV'", "w") do |pipe|
        pipe.puts csv_data
      end
      
      post_count += batch.size
      puts "  Synced #{post_count} posts..."
    end
    
    puts "\n✅ Sync complete!"
    puts "  Channels: #{channel_count}"
    puts "  Posts: #{post_count}"
  end
  
  desc "Show ClickHouse stats"
  task stats: :environment do
    puts "\n📊 ClickHouse Statistics:"
    
    channels = `docker exec clickhouse-server clickhouse-client --query="SELECT COUNT(*) FROM adsensie_analytics.channels_analytics"`.strip
    posts = `docker exec clickhouse-server clickhouse-client --query="SELECT COUNT(*) FROM adsensie_analytics.posts_analytics"`.strip
    
    puts "  Channels: #{channels}"
    puts "  Posts: #{posts}"
  end
end
