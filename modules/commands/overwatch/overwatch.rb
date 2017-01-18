require 'rest_client'
require 'json'

require_relative '../../../bot-feature.rb'
require_relative 'overwatch_api.rb'
require_relative 'basic_command.rb'
require_relative 'patch_notes.rb'


class OverwatchFeature < BotFeature
  def load(bot)
    config = bot.get_config_for_module(__FILE__)
    @config = {
    }

    @@base_url = "https://api.lootbox.eu/$PLATFORM/$REGION/$TAG/"
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

    bot.map_config(config, @config)
  end

  def register_handlers(bot, scheduler)
    bot.message(contains: /^\!(ow|overwatch)\s/) do |event|
      parts = event.message.to_s.split(/\s+/)
      parts.delete_at 0

      if parts.size == 0
        show_help event
        next
      end

      if parts.size >= 1 and parts[0] =~ /-(patch|p|patchnotes|pn)/
        pns = ""
        if parts.size == 2 and parts[1] == "ptr"
          pns = get_ptr_pns
        else
          pns = get_ow_pns
        end

        # Split up response
        message = bot.paginate_response(pns, takeoff=16)
        puts "Message len: #{message.length}"
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
  include OverwatchAPI
  include BasicOverwatchCommand
  include PatchNotes

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

  def show_help(event)
    event.respond %{\
Overwatch User Lookup (!ow or !overwatch):
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
  end

  # Run a standard profile query for a specific player
  def run_command(bot, type, query, options)
    query.gsub! /#/, "-"
    query.gsub! /[^A-Za-z0-9\-]/, ""
    options["tag"] = query

    if type == "profile"
      user = get_username(bot, query)
      if user == nil
        return "Unknown user #{user}"
      end

      get_user_details user
    end
  end
end
