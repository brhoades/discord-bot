require 'chronic_duration'

require_relative 'bf1_api.rb'


module BF1DetailedStats
  private
  include BF1BasicAPI

  # Does a rest query to bf1tracker for detailed stats for a provided username.
  def get_detailed_statistics(name)
    if name =~ /^\s*$/
      return {"error" => "No username provided."}
    end

    get_data("https://battlefieldtracker.com/bf1/api/Stats/DetailedStats?platform=3&displayName=#{name}")
  end

  # Does a rest query to bf1tracker for detailed stats for a provided username.
  def get_weapons_statistics(name)
    if name =~ /^\s*$/
      return {"error" => "No username provided."}
    end

    get_data("https://battlefieldtracker.com/bf1/api/Progression/GetWeapons?platform=3&displayName=#{name}")
  end

  # Get stars information about a person and return a stringifed detail list.
  def get_stars_statistics(name)
    response = get_weapons_statistics(name)
    return response if not response.is_a? Hash

    res = ["**#{response.dig("profile", "displayName")}**", "", "```markdown"]
    maxsize = response.dig("result").map {|type| type.dig("weapons").map {|weapon| weapon.dig("name").length if weapon.dig("star", "timesAquired") != nil}.compact.flatten }.flatten.compact.max

    response.dig("result").each do |type|
      res << render_weapon_type_stars(type, pad=maxsize)
    end

    puts maxsize
    if maxsize == 0 or maxsize == nil
      return "**#{name}** has no stars"
    end

    res << "```"

    res.compact.join "\n"
  end

  def render_weapon_type_stars(type, pad=0)
    # Given a hash of {"name" and "weapons"}, where weapons is an array,
    # Go through them and render some nice statistics about stars

    res = []

    weps_with_stars = type["weapons"].map { |weapon| weapon if weapon["star"] != nil }.compact
    res << "**#{type.dig("name")}** (#{weps_with_stars.size}/#{type["weapons"].size})"

    if weps_with_stars.size == 0
      return nil
    end

    weps_with_stars.each do |weapon|
      times = weapon.dig("star", "timesAquired").to_i
      res << "#{weapon.dig("name").ljust(pad, ' ')}  #{weapon.dig("star", "timesAquired").to_i} star#{"s" if times != 1}"
    end

    res << ""

    res.join "\n"
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
    maxKills = kits.max { |a, b| a.dig("kills")&.round(0)&.to_s&.length <=> b.dig("kills")&.round(0)&.to_s&.length }.dig("kills")&.round(0)&.to_s&.length

    kits.each do |kit|
      res << "#{kit.dig("name")&.ljust(maxNameSize, ' ')}\tKills: #{kit.dig("kills")&.round(0)&.to_s&.ljust(maxKills, ' ')} - Time as: #{ChronicDuration.output(kit.dig("secondsAs")&.to_i, :format => :long, :units => 2)} (#{(kit.dig("secondsAs")&.to_f/totalTime*100)&.round(0)}%)"
    end

    res << "```"

    res.join "\n"
  end

end
