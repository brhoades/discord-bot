require 'json'
require 'rest_client'

require 'bot-feature.rb'


class OverwatchFeature < BotFeature
  def load(bot)
    load_concerns(__FILE__)

    config = bot.get_config_for_module(__FILE__)
    @config = {
      "channel_for_announce": ["general"], # channels to announce patchnotes in
      "announce_tags": ["@everyone"]  # full tag names to tag on announcements
    }

    @@api_urls = {
      "profile": "profile",
      "achievements": "achievements",
      "heros": "$MODE/allHeros",
      "hero": "$MODE/hero/$HERO",
      "allheros": "$MODE/heros"
    }

    @@option_aliases = {
      "plat": "platform",
      "platform": "platform",
      "r": "region",
      "m": "mode",
      "region": "region",
      "mode": "mode"
    }

    @@arg_aliases = {
      "q": "quickplay",
      "qp": "quickplay",
      "quick": "quickplay",
      "quickplay": "quickplay",
      "c": "competitive",
      "cp": "competitive",
      "comp": "competitive",
      "competitive": "competitive",
      "pc": "pc",
      "psn": "psn",
      "xbl": "xbl",
      "xb": "xbl",
      "ps": "psn"
    }

    @update_frequency = 60*60

    # Indicies to each graph type, by name
    @graph_types = {
      "playtime": {
        "index": lambda { |data|
          stats = data["us"]["stats"]
          get_common_stats_from_data(stats)["time_played"]
        },
        "description": "Playtime in hours.",
        "label": "playtime (hours)",
        "title": "{}'s Playtime in Hours",
      },
      "level": {
        "index": lambda { |data|
           comp = data["us"]["stats"]["competitive"]["overall_stats"]
           comp["level"].to_i + comp["prestige"].to_i * 100
          },
        "description": "Level (+ prestiege) for this player.",
        "label": "level",
        "title": "{}'s Effective Level",
      },
      "kpd": {
        "index": lambda { |data|
          # Todo: average weighted by # games
          stats = data["us"]["stats"]
          get_common_stats_from_data(stats)["kpd"]
        },
        "description": "Kills per death for this player.",
        "label": "KPD (avg)",
        "title": "{}'s Kills/Death",
      },
      "rank": {
        "index": lambda { |data|
          # Todo: average weighted by # games
          comp = data["us"]["stats"]["competitive"]["overall_stats"]
          comp["comprank"]
        },
        "description": "Competitive rank for a player.",
        "label": "Competitive Rank",
        "title": "{}'s Competitive Rank",
      },
      "heroplaytime": {
        "index": lambda { |data|
          # Todo: average weighted by # games
          combine_heroes(data["us"])["playtime"].sort.map { |_, v| v }
        },
        "description": "Playtime per hero over time",
        "label": lambda { |data|
          combine_heroes(data["us"])["playtime"].sort.map { |k, _| k }
        },
        "title": "{}'s Hero Playtime (hours)",
        "width": 800,
        "multi_series": true,
      },
      "{class}_playtime": {
        "index": lambda { |data, hero_class|
          # Todo: average weighted by # games
          combine_heroes(data["us"])["playtime"]
            .select { |k, v| class_to_hero[hero_class].include?(k) }
            .map { |_, v| v }
        },
        "description": "Playtime per hero over time",
        "label": lambda { |_, hero_class|
          class_to_hero[hero_class]
        },
        "title": "{}'s Hero Playtime (hours)",
        "width": 800,
        "multi_series": true,
      }
    }

    bot.map_config(config, @config)
  end

  def register_handlers(bot, scheduler)
    bot.add_help({
      command: ["ow", "overwatch"],
      short_help: %{!ow/!overwatch: Overwatch details},
      long_help: %{\
Overwatch User Lookup:
All commands default to us / pc / quickplay. You can change this with any command by providing:
  -plat(form) pc/xbl/psn
  -r(egion) us/eu/kr/cn/global
  -m(ode) q/qp/quick/quickplay/c/cp/comp/competitive

Examples
  !ow player#159
  !ow -r eu -plat pc -m qp

---

Patch notes are also available:
  !ow -patchnotes/-pn/-patch (ptr or normal/ow)

For example:
  !ow -patchnotes  # Gives regular overwatch patchnotes
  !ow -pn ptr      # PTR Patch Notes
}
    })

    register_tracker_handlers(bot, scheduler)

    bot.message(contains: /^\!(ow|overwatch)\s/) do |event|
      parts = event.message.to_s.split(/\s+/)
      parts.delete_at 0

      if parts.size >= 1 and parts[0] =~ /-(patch|p|patchnotes|pn)/
        pns = ""
        if parts.size == 2 and parts[1] == "ptr"
          pns = get_ptr_pns
        else
          pns = get_ow_pns
        end

        # Split up response
        message = bot.paginate_response(pns, takeoff=16)
        message.each do |msg|
          event.respond "```Markdown\n#{msg}```"
        end

        next
      end

      options = consume_options parts
      event.respond(run_command(bot, "profile", parts.first, options))
    end
  end

  private
  include Overwatch::API
  include Overwatch::General
  include Overwatch::PatchNotes
  include Overwatch::Tracker
  # include Overwatch::CommonData

  # Consumes anything with -this arg and returns a dict.
  # Replaces parts with just the user query.
  def consume_options(parts)
    options = {}

    parts.each_slice(2) do |arg|
      if arg.size == 2 and arg[0].size > 1
        arg[0] = arg[0][1..-1].to_sym
        arg[1] = arg[1].to_sym
        if @@option_aliases.has_key?(arg[0]) and @@arg_aliases.has_key?(arg[1])
          options[@@option_aliases[arg[0]]] = @@arg_aliases[arg[1]]
        end
      end
    end

    query = parts.last
    parts.clear
    parts << query

    options
  end

  # Run a standard profile query for a specific player
  def run_command(bot, type, query, options)
    query.gsub! /#/, "-"
    query.gsub! /[^A-Za-z0-9\-]/, ""
    options["tag"] = query

    if type == "profile"
      user = get_username(query)
      if user == nil
        return "Unknown user #{user}"
      end

      %{#{user[:message]}
#{get_user_details user[:long]}}
    end
  end

  # send a message out to the appropriate channels
  def dispatch_message(bot, pns)
    message = bot.paginate_response(pns, takeoff=16)

    @config[:channel_for_announce].each do |channel|
      channels = bot.find_channel(channel)
      puts "CHANNELS: #{channels}"

      channels.each do |channel|
        if config[:announce_tags].length > 0
          channel.send_message config[:announce_tags].join(" ")
        end

        message.map { |m| channel.send_message "```Markdown\n#{m}```" }
      end
    end
  end
end
