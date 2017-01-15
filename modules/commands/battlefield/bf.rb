require_relative '../../../bot-feature.rb'
require_relative 'bf1_api.rb'
require_relative 'basic_stats.rb'
require_relative 'detailed_stats.rb'


class BF1TrackerFeature < BotFeature
  def initialize
  end

  def load(bot)
    config = bot.get_config_for_module(__FILE__)
    @config = {
      "bftracker_api_key": "",
      "": ""
    }

    bot.map_config(config, @config)

    @header = {"TRN-Api-Key": @config[:bftracker_api_key]}
    @enabled = (@config[:bftracker_api_key] != "")

    @location_cache = {}
  end

  def register_handlers(bot, scheduler)
    bot.message(contains: /^[!\/]bf1? [A-Za-z0-9]+/) do |event|
      next if not handler_check event

      event.respond "Missing API key" if not @enabled
      message = event.message.to_s.split(/ /)
      message.delete_at 0
      event.respond pretty_basic_statistics(message.join " ")
    end

    bot.message(contains: /^[!\/]bf1? -[A-Za-z]+ [A-Za-z0-9]+/) do |event|
      next if not handler_check event

      event.respond "Missing API key" if not @enabled
      message = event.message.to_s.split(/ /)
      message.delete_at 0
      sub = message[0]
      message.delete_at 0

      if sub =~ /kits?/
        event.respond pretty_kit_statistics(message.join " ")
      end
    end
  end

  private
  include BF1BasicStats 
  include BF1DetailedStats 
end
