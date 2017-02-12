require 'digest'
require 'tempfile'
require 'open-uri'

require_relative '../../../bot-feature.rb'
require_relative 'voice_processing.rb'
require_relative 'voice_state.rb'
require_relative 'voice_helpers.rb'
require_relative 'voice_entry_points.rb'


# Announce users joining and leaving channels.
class VoiceFeatures < BotFeature
  def load(bot)
    config = bot.get_config_for_module(__FILE__)
    @config = {
      cache: true,
      cache_directory: "/tmp/",
      authorized_play_users: [],
      default_play_volume: 0.1,
      default_volume: 1.0,
      lang: 'en',
      max_yt_filesize: "100m",
      custom_greetings: {}
    }

    @voice = {}
    @voice_queue = {}
    @QUEUE_SIZE = 2
    bot.map_config(config, @config)
  end

  def ready(bot, scheduler)
    get_voice_state bot
  end

  def register_handlers(bot, scheduler)
    bot.add_help({
      command: ["play", "stop", "empty"],
      short_help: %{!stop/!play/!empty: voice channel announcements and voice sound playing.},
      long_help: %{Discord Voice Features
By default, this module will announce when someone enters and leaves a channel using Google's TTS engine to generate a message. This module also provides commands to empty the queue that is used to play these messages as well as add custom files to the queue.

Usage:
  **!play** <YouTube URL or direct link to sound file>: plays the media provided in the voice channel you are currently in.
  **!stop**: stops playback if the bot is speaking and plays the next media entry in the queue (if there is one).
  **!empty**: empties the media queue completely and halts playback.
}
    })

    bot.voice_state_update do |event|
      process_voice_state(bot, event.server, event.channel, event.user)
    end

    bot.message(contains: /^\!play .+/) do |event|
      next "!giphy unauthorized" unless authorized_user(event.author.username)

      play_web_address event
    end

    bot.message(contains: /^\!stop$/) do |event|
      next "!giphy unauthorized" unless authorized_user(event.author.username)

      server = event.server.id
      if bot.voices.has_key? server
        bot.voices[server].stop_playing true
      end
    end

    bot.message(contains: /^\!empty$/) do |event|
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
        puts "Error in process voice queue:\n#{e.to_s}"
      end
    end
  end

  private
  include VoiceProcessing
  include VoiceState
  include VoiceHelpers
  include VoiceEntryPoints
end
