require 'bot-feature'

require_relative 'bf1_api.rb'
require_relative 'basic_stats.rb'
require_relative 'detailed_stats.rb'
require_relative 'weapon_stats.rb'
require_relative 'medal_stats.rb'
require_relative 'vehicle_stats.rb'


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
  end

  def register_handlers(bot, scheduler)
    bot.add_help({
      command: ["bf", "bf1"],
      short_help: %{!bf/!bf1: battlefield user statistics},
      long_help: %{Battlefield User Statstics
Usage:
  !bf <user>: show basic user information.
  !bf -kit/kits <user>: show information about a user's kits including time used.
  !bf -star/stars <user>: show weapons and their number of stars for a user (if any).
  !bf -medal/medals <user>: show medals for a user, including in progress.
  !bf -vehicle/vehicles <user>: show vehicle statistics by type.
}
    })

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

      response = nil
      if sub =~ /kits?/
        response = pretty_kit_statistics(message.join " ")
      elsif sub =~ /stars?/
        response = get_stars_statistics(message.join " ")
      elsif sub =~ /medals?/
        response = pretty_medal_statistics(message.join " ")
      elsif sub =~ /vehicles?/
        response = pretty_vehicle_statistics(bot, message.join(" "))
      end

      if response.is_a? Array
        response.map { |m| event.respond m }
      else
        event.respond response
      end
    end
  end

  private
  include BF1BasicStats
  include BF1DetailedStats
  include BF1WeaponStats
  include BF1MedalStats
  include BF1VehicleStats
end
