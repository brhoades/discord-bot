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

    res = ["**#{response.dig("profile", "displayName")}**", "", "```markdown"]
    # TODO move vehicles and kit separate then join here.
    response.dig("result", "vehicleStats").each do |v|
      # Alias vehicles so they match kits.
      v["kills"] = v.dig("killsAs")
      v["secondsAs"] = v.dig("timeSpent")
    end
    kits = response.dig("result", "kitStats") + response.dig("result", "vehicleStats")
    totalTime = kits.reduce(0) {|sum, kit| sum += kit.dig("secondsAs")&.to_i}
    maxNameSize = kits.max { |a, b| a.dig("name")&.length <=> b.dig("name")&.length }.dig("name")&.length
    maxKills = kits.max { |a, b| a.dig("kills")&.round(0)&.to_s&.length <=> b.dig("kills")&.round(0)&.to_s&.length }["kills"]&.round(0)&.to_s&.length

    kits.each do |kit|
      res << "#{kit.dig("name")&.ljust(maxNameSize, ' ')}\tKills: #{kit.dig("kills")&.round(0)&.to_s&.ljust(maxKills, ' ')} - Time as: #{ChronicDuration.output(kit.dig("secondsAs")&.to_i, :format => :long, :units => 2)} (#{(kit.dig("secondsAs")&.to_f/totalTime*100)&.round(0)}%)"
    end

    res << "```"

    res.join "\n"
  end
end
