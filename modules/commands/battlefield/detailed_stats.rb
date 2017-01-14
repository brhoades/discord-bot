require 'chronic_duration'

require_relative 'bf1_api.rb'


module BF1DetailedStats
  private
  include BF1BasicAPI

  # Does a rest query to bf1tracker for detailed stats for a provided username.
  def get_detailed_statistics(name)
    get_rest_api("https://battlefieldtracker.com/bf1/api/Stats/DetailedStats?platform=3&displayName=#{name}")
  end

  # Grabs detailed bf1tracker statistics and returns stringified kit information.
  def pretty_kit_statistics(name)
    response = get_detailed_statistics(name)
    return response if not response.is_a? Hash

    res = ["**#{response["profile"]["displayName"]}**", "", "```markdown"]
    # TODO move vehicles and kit separate then join here.
    response["result"]["vehicleStats"].each do |v|
      # Alias vehicles so they match kits.
      v["kills"] = v["killsAs"]
      v["secondsAs"] = v["timeSpent"]
    end
    kits = response["result"]["kitStats"] + response["result"]["vehicleStats"]
    totalTime = kits.reduce(0) {|sum, kit| sum += kit["secondsAs"].to_i}
    maxNameSize = kits.max { |a, b| a["name"].length <=> b["name"].length }["name"].length
    maxKills = kits.max { |a, b| a["kills"].round(0).to_s.length <=> b["kills"].round(0).to_s.length }["kills"].round(0).to_s.length

    kits.each do |kit|
      res << "#{kit["name"].ljust(maxNameSize, ' ')}\tKills: #{kit["kills"].round(0).to_s.ljust(maxKills, ' ')} - Time as: #{ChronicDuration.output(kit["secondsAs"].to_i, :format => :long, :units => 2)} (#{(kit["secondsAs"].to_f/totalTime*100).round(0)}%)"
    end

    res << "```"

    res.join "\n"
  end
end
