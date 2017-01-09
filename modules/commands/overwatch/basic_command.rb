require 'chronic_duration'

require_relative 'overwatch_api.rb'


module BasicOverwatchCommand
  include OverwatchAPI

  # Return a string to give with basic user information
  def get_user_details(user)
    data = get_data(user)

    %{__**#{user}**__

#{get_general_stats(data)}
}
  end

  def get_general_stats(data)
    stats = data["us"]["stats"]
    comp = stats["competitive"]["overall_stats"]

    common_game_stats = {}

    # Accumulate some common values
    ["competitive", "quickplay"].each do |type|
      stats[type]["game_stats"].each do |k, v|
        if common_game_stats.has_key?(k)
          common_game_stats[k] += v.to_f
        else
          common_game_stats[k] = v.to_f
        end
      end
    end
    level = comp["level"].to_i + (comp["prestige"].to_i * 100)

    %{__General__
*Rank (competitive)*: #{level} (#{comp["tier"]} #{comp["comprank"]})
*Time played*: #{ChronicDuration.output(common_game_stats["time_played"]*60*60, :format => :long, :units => 3)}

}
  end
end
