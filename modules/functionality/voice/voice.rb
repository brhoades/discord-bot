require 'digest'
require 'tempfile'
require 'open-uri'

require_relative '../../../bot-feature.rb'
require_relative 'voice_processing.rb'


# Announce users joining and leaving channels.
class VoiceFeatures < BotFeature
  def load(bot)
    config = bot.get_config_for_module(__FILE__)
    @config = {
      cache: true,
      cache_directory: "/tmp/",
      authorized_play_users: [],
      default_play_volume: 0.1,
      default_volume: 1.0
    }

    @voice = {}
    @voice_queue = {}
    @QUEUE_SIZE = 2
    bot.map_config(config, @config)
  end

  def register_handlers(bot, scheduler)
    bot.voice_state_update do |event|
      process_voice_state(bot, event.server, event.channel, event.user)
    end

    bot.message(contains: /^\!play .+/) do |event|
      next "!giphy unauthorized" unless authorized_user(event.author.username)

      play_file event
    end

    bot.message(contains: /^\!stop/) do |event|
      next "!giphy unauthorized" unless authorized_user(event.author.username)

      server = event.server.id
      if bot.voices.has_key? server
        bot.voices[server].stop_playing true
      end
    end

    bot.message(contains: /^\!empty/) do |event|
      next "!giphy unauthorized" unless authorized_user(event.author.username)

      server = event.server.id

      # Stop
      if bot.voices.has_key? server
        bot.voices[server].stop_playing true
      end

      # Clear
      if @voice_queue.has_key? event.server
        @voice_queue[event.server].clear
      end
    end

    scheduler.every '1s' do
      begin
        process_voice_queue bot
      rescue Exception => e
        puts "Error in process voice queue #{e.to_s}"
      end
    end
  end

  private
  include VoiceProcessing

  def authorized_user(user)
    authed = false
    @config[:authorized_play_users].each do |name|
      if user.to_s =~ /^#{name}/i
        authed = true
        break
      end
    end

    authed
  end

  def play_file(event)
    msg = event.message.to_s.split(/\s+/)
    file = msg[1]

    # Default volume is fairly quiet
    volume = @config[:default_play_volume]
    if msg.size == 3
      volume = msg[2].to_f
    end

    filename = Tempfile.new('input')
    filename.write(open(file) { |f| f.read })
    filename.close
    tempfile = `tempfile -s .wav`.gsub(/\n/, "")

    system("ffmpeg -y -loglevel panic -i #{filename.path} #{tempfile}")
    if $? != 0
      puts "Error when transcoding #{msg[1]}"
      filename.delete
      `rm -f #{tempfile}`
      return
    end
    filename.delete

    if not @voice_queue.has_key? event.server
      @voice_queue[event.server] = []
    end

    @voice_queue[event.server] << {
      file: tempfile,
      channel: event.author.voice_channel,
      volume: volume,
      delete: true,
      owner: event.author
    }
  end

  # Actually send a message. Cache the mp3 in tmp.
  # TODO: make cache optional and give it a sub directory.
  def send_message(bot, server, channel, user, message)
    name = Digest::SHA256.hexdigest message
    if !Dir.exists?(@config[:cache_directory])
      `mkdir -p #{@config[:cache_directory]}`
    end

    file = File.join(@config[:cache_directory], "#{name}")

    if !File.exists?("#{file}.mp3")
      File.write "#{file}.txt", message
      `perl simple-google-tts/speak.pl ja "#{file}.txt" "#{file}.mp3"`
      `rm #{file}.txt`
    end

    if !@voice_queue.has_key?(server)
      @voice_queue[server] = []
    end

    if @voice_queue[server].select { |v| v[:owner] == user }.size >= @QUEUE_SIZE
      puts "Limit reached for \"#{user.username}\" on \"#{channel}\""
      return
    end

    @voice_queue[server] << {
      file: "#{file}.mp3",
      channel: channel,
      owner: user
    }
  end

  # Called on a voice event. If it's not us, we internally
  # update our voice session tracking.
  # TODO: do this on bot start.
  # TODO: decouple from sending messages
  def process_voice_state(bot, server, channel, user)
    return if user.current_bot?

    if !@voice.has_key? server
      @voice[server] = {}
    end

    if channel and !@voice[server].has_key? channel
      @voice[server][channel] = []
    end

    name = (user.username.gsub /[0-9]+$/, "").downcase

    @voice[server].each do |k,v|
      if v.include? user and k != channel
        v.delete user
        if v.size >= 1
          # notify users, this isn't just an initial load.
          send_message bot, server, k, user, "#{name} left"
        end
      end
    end

    if channel and !@voice[server][channel].include? user
      @voice[server][channel] << user
      total_server = @voice[server].map { |l| l.size }.reduce(0, :+)
      if total_server == 1 and @voice[server][channel].size == 1
        send_message bot, server, channel, user, "You look nice today, #{name}"
      elsif @voice[server][channel].length >= 2
        send_message bot, server, channel, user, "#{name} joined"
      end
     end
  end
end
