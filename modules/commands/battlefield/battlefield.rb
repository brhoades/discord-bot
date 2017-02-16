require 'bot-feature'


class BF1TrackerFeature < BotFeature
  def initialize
  end

  def load(bot)
    load_concerns(__FILE__)

    config = bot.get_config_for_module(__FILE__)
    @config = {
      "bftracker_api_key": "",
      "": ""
    }

    bot.map_config(config, @config)

    @header = {"TRN-Api-Key": @config[:bftracker_api_key]}
    @enabled = (@config[:bftracker_api_key] != "")

    # Indicies to each graph type, by name
    @graph_types = {
      "playtime": {
        "data_type": BattlefieldHistory::TYPE_NAMES.find_index("general"),
        "index": ["result", "timePlayed"],
        "description": "Playtime in hours for a player.",
        "label": "playtime (hours)"
      },
      "kills": {
        "data_type": BattlefieldHistory::TYPE_NAMES.find_index("general"),
        "index": ["result", "kills"],
        "description": "Kills for a player.",
        "label": "kills"
      },
      "deaths": {
        "data_type": BattlefieldHistory::TYPE_NAMES.find_index("general"),
        "index": ["result", "deaths"],
        "description": "Deaths for a player.",
        "label": "deaths"
      },
      "xp": {
        "data_type": BattlefieldHistory::TYPE_NAMES.find_index("general"),
        "index": ["result", "rankProgress", "current"],
        "description": "XP towards a player's next level.",
        "label": "xp"
      },
      "kpm": {
        "data_type": BattlefieldHistory::TYPE_NAMES.find_index("general"),
        "index": ["result", "kpm"],
        "description": "Kills per minute for a player.",
        "label": "xp"
      },
    }
  end

  def register_handlers(bot, scheduler)
    bot.add_help({
      command: ["bf", "bf1"],
      short_help: %{!bf/!bf1: Battlefield 1 user statistics},
      long_help: %{Battlefield 1 User Statistics
Usage:
  !bf <user>: show basic user information.
  !bf -kit/kits <user>: show information about a user's kits including time used.
  !bf -wstar/weaponstars <user>: show weapons and their number of stars for a user (if any).
  !bf -medal/medals <user>: show medals for a user, including in progress.
  !bf -vehicle/vehicles <user>: show vehicle statistics by type.
  !bf -vstars/vehiclestars <user>: show vehicle stars by type.
}
    })

    bot.add_help({
      command: ["bft", "bftracker"],
      short_help: %{!bft/!bftracker: Battlefield 1 tracking},
      long_help: %{Battlefield 1 Tracking
Usage:
  !bft -list: list all users that are tracked.
  !bft -add <user>: add a user to be tracked.
  !bft -graph <attribute> <user>: graph a specific attribute for a user.

Attributes:
  } + @graph_types.map { |name, v| "#{name}: #{v[:description]}" }.join("\n  ")
})

    bot.message(contains: /^[!\/]bf1? [A-Za-z0-9]+/) do |event|
      next "Missing API key" if not @enabled

      message = event.message.to_s.split(/ /)
      message.delete_at 0
      event.respond pretty_basic_statistics(message.join " ")
    end

    bot.message(contains: /^[!\/]bf1? -[A-Za-z]+ [A-Za-z0-9]+/) do |event|
      next "Missing API key" if not @enabled

      args = parse_args(event.message.to_s)

      response = nil
      if args[:args].has_key? "kits" or args[:args].has_key? "kit"
        response = pretty_kit_statistics args[:target]
      elsif args[:args].has_key? "wstars" or args[:args].has_key? "weaponstars"
        response = get_stars_statistics args[:target]
      elsif args[:args].has_key? "medal" or args[:args].has_key? "medals"
        response = pretty_medal_statistics args[:target]
      elsif args[:args].has_key? "vehicle" or args[:args].has_key? "vehicles"
        response = pretty_vehicle_statistics bot, args[:target]
      elsif args[:args].has_key? "vstars" or args[:args].has_key? "vehiclestars"
        response = pretty_vehicle_stars bot, args[:target]
      else
        response = "!help bf"
      end

      if response.is_a? Array
        response.map { |m| event.respond m }
      else
        event.respond response
      end
    end

    bot.message(contains: /^[!\/]bf1?t(racker)?\s+/) do |event|
      tracker_commands event
    end
  end

  private
  include BF1::API
  include BF1::BasicStats
  include BF1::DetailedStats
  include BF1::WeaponStats
  include BF1::MedalStats
  include BF1::VehicleStats
  include BF1::Tracker
end
