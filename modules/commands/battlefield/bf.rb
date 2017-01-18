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

      if sub =~ /kits?/
        event.respond pretty_kit_statistics(message.join " ")
      elsif sub =~ /stars?/
        event.respond get_stars_statistics(message.join " ")
      elsif sub =~ /medals?/
        event.respond pretty_medal_statistics(message.join " ")
      end
    end
  end

  private
  include BF1BasicStats 
  include BF1DetailedStats 
end
