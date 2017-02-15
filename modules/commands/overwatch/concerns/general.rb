require 'chronic_duration'


# Requires Overwatch::API in included scope.
module Overwatch
  module General
    # Return a string to give with basic user information
    def get_user_details(user)
      data = get_data(user)

      %{__**#{user.sub(/\-/, "#")}**__

#{get_general_stats(data)}
}
    end


    # Combines hero rankings in competitive and quickplay. expects ["us"] hash
    def combine_heroes(stats)
      gen_stats = stats["heroes"]["stats"]
      playtime = stats["heroes"]["playtime"]

      merged = {
        "stats" => deep_merge_hashes(gen_stats["competitive"], gen_stats["quickplay"]),
        "playtime" => deep_merge_hashes(playtime["competitive"], playtime["quickplay"])
      }

      merged
    end

    # Expects a hash of hero names with subkeys of general_stats
    # Returns an array of hero details, with name popped in the hash.
    def sort_hero_stats(stats)
      ret = stats.map { |k, v| v["name"] = k; v }
      ret.sort do |left, right|
        if left == nil
          -1
        elsif right == nil
          1
        else
          left["general_stats"]["time_played"].to_f <=> right["general_stats"]["time_played"].to_f
        end
      end.reverse
    end
    
    def get_common_stats_from_data(stats)
      common_game_stats = {}

      # Accumulate some common values
      ["competitive", "quickplay"].each do |type|
        stats[type]["game_stats"].each do |k, v|
          if common_game_stats.has_key?(k)
            if v.is_a? Float
              common_game_stats[k] = (v + common_game_stats[k])/2
            else
              common_game_stats[k] += v
            end
          else
            common_game_stats[k] = v
          end
        end
      end

      return common_game_stats
    end

    def get_general_stats(data)
      return data["error"] if data.has_key?("error")
      stats = data["us"]["stats"]
      comp = stats["competitive"]["overall_stats"]

      common_game_stats = get_common_stats_from_data(stats)
      level = comp["level"].to_i + (comp["prestige"].to_i * 100)

      merged_hero_stats = combine_heroes(data["us"])
      summary = get_gameplay_stats(merged_hero_stats)
      sorted_stats = sort_hero_stats(merged_hero_stats["stats"])

      #Games played (W/L): #{total} (#{won}/#{total-won})

      %{__General (Competitive + Quickplay)__
*Rank (competitive)*: #{level} (#{comp["tier"]} #{comp["comprank"]})
*Time played*: #{ChronicDuration.output(common_game_stats["time_played"]*60*60, :format => :long, :units => 3)}

__Top 3 Heros by Play Time__

#{render_hero sorted_stats[0]["name"], sorted_stats[0]}

#{render_hero sorted_stats[1]["name"], sorted_stats[1]}

#{render_hero sorted_stats[2]["name"], sorted_stats[2]}
}
    end

    # Gets gameplay stats from a us/heros/ hash
    def get_gameplay_stats(stats)
      summary = {}

      ["games_played", "games_won", "games_tied", "games_lost"].each do |type|
        summary[type] = stats["stats"]
          .map {|hero, details| details["general_stats"][type].to_f}.reduce(0, :+)
      end

      summary
    end

    # Renders some light statistcs about a hero.
    def render_hero(name, stats)
      gen = stats["general_stats"]
      hero = stats["hero_stats"]

      ret = %{**#{name.capitalize}**
#{ChronicDuration.output(gen["time_played"]*60*60, :format => :long, :units => 3)}
*Eliminations/Deaths (k/d)*: #{gen["eliminations"]}/#{gen["deaths"]} (#{(gen["eliminations"].to_f/gen["deaths"]).round(2)})
*Medals (G/S/B):* #{(gen["medals_gold"]+gen["medals_silver"]+gen["medals_bronze"]).to_i} (#{gen["medals_gold"]}/#{gen["medals_silver"]}/#{gen["medals_bronze"]})

}

      hero.each do |k, v|
        k = k.gsub(/_/, " ").capitalize
        if k =~ /accuracy/
          v = "#{(v*100).round(0)}%"
        end
        v = v.to_s.reverse.gsub(/[0-9]{3}(?=[0-9])/,'\&,').reverse
        ret += "*#{k}*: #{v}\n"
      end

      ret
    end
  end
end
