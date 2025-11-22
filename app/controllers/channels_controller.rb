class ChannelsController < ApplicationController
  before_action :authenticate_user!

  def index
    @channels = Channel.all
    
    # Search
    if params[:query].present?
      @channels = @channels.search(params[:query])
    end
    
    # Filters
    if params[:min_subscribers].present? && params[:max_subscribers].present?
      @channels = @channels.by_subscribers(params[:min_subscribers].to_i, params[:max_subscribers].to_i)
    end
    
    if params[:min_engagement].present?
      @channels = @channels.by_engagement(params[:min_engagement].to_f)
    end
    
    if params[:growth_filter] == "trending"
      @channels = @channels.fast_growing
    end
    
    # Sorting
    case params[:sort]
    when "engagement"
      @channels = @channels.by_engagement_rate
    when "subscribers"
      @channels = @channels.by_subscribers
    when "growth"
      @channels = @channels.by_growth
    when "activity"
      @channels = @channels.by_activity
    else
      @channels = @channels.by_engagement_rate
    end
    
    # Simple pagination (20 per page)
    @channels = @channels.page(params[:page]).per(20)
  end

  def show
    @channel = Channel.find(params[:id])
    @recent_posts = @channel.posts.recent.limit(10)
    @collections = current_user.collections
  end

  def new
  end

  def create
    username = params[:username]
    
    if username.blank?
      flash.now[:alert] = "Please enter a Telegram username"
      render :new, status: :unprocessable_entity
      return
    end
    
    # Ensure username starts with @
    username = "@#{username}" unless username.start_with?('@')
    
    result = TelegramService.import_channel(username)
    
    if result[:success]
      redirect_to channel_path(result[:channel]), notice: "Channel successfully added!"
    else
      flash.now[:alert] = "Failed to add channel: #{result[:error]}"
      render :new, status: :unprocessable_entity
    end
  end

  def add_to_collection
    @channel = Channel.find(params[:id])
    
    unless params[:collection_id].present?
      redirect_to @channel, alert: "Please select a collection"
      return
    end
    
    collection = current_user.collections.find(params[:collection_id])
    
    if collection.channels.include?(@channel)
      redirect_to @channel, alert: "Channel is already in #{collection.name}"
    else
      collection.collection_channels.create(channel: @channel)
      redirect_to @channel, notice: "Channel added to #{collection.name}"
    end
  end

  def compare
    if params[:channel_ids].present?
      @channels = Channel.where(id: params[:channel_ids])
    else
      @channels = []
    end
  end
end
