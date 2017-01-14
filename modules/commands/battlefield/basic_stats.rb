require_relative 'bf1_api.rb'

module BF1BasicStats
  include BF1BasicAPI
  # Does a rest query to bf1tracker for basic stats for a provided username.
  def get_basic_statistics(name)
        get_rest_api("https://battlefieldtracker.com/bf1/api/Stats/BasicStats?platform=3&displayName=#{name}")
  end

  # Grabs basic bf1tracker stats and returns a string summarizing them.
  def pretty_basic_statistics(name)
    response = get_basic_statistics(name)
    return response if not response.is_a? Hash

    result = response["result"]
    total = "#{get_total_experience(result["rank"]["number"], result["rankProgress"]["current"].round(0))}"
    %{**#{response["profile"]["displayName"]}**
*K/D*: #{result["kills"]}/#{result["deaths"]}\t*W/L*: #{result["wins"]}/#{result["losses"]}\t\
*KPM*: #{result["kpm"]}
*Time played*: #{ChronicDuration.output(result["timePlayed"], :format => :long, :units => 3)}
#{result["rank"]["name"]} (#{(result["rankProgress"]["current"]/result["rankProgress"]["total"]*100).round(1)}% to next rank)\t\
#{total} XP (#{(total.to_f/@ranks[100]*100).round(2)}% to rank 100)}
  end
end
