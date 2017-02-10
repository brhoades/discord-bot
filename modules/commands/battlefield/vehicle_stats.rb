require 'chronic_duration'

require_relative 'bf1_api.rb'


module BF1VehicleStats
  private
  include BF1BasicAPI

  # Does a rest query to bf1tracker to get vehicle stats for a provided username
  def get_vehicle_statistics(name)
    if name =~ /^\s*$/
      return {"error" => "No username provided."}
    end

    get_data("https://battlefieldtracker.com/bf1/api/Progression/GetVehicles?platform=3&displayName=#{name}")
  end

  # Get medal information about a person and return a stringifed detail list.
  def pretty_vehicle_statistics(bot, name)
    response = get_vehicle_statistics(name)
    return response if not response.is_a? Hash

    res = ["**#{name}**", ""]

    # Longest vehicle name
    name_pad = response.dig("result").map do |vehicles|
      # Get the vehicle type that has the largest name for this type.
      # Return the size back to max so we can just do max.
      vehicles["vehicles"].max { |a, b| a.dig("name").size <=> b.dig("name").size }
        .dig("name").size
    end.max - 1

    kills_pad = response.dig("result").map do |vehicles|
      vehicles["vehicles"]
        .max { |a, b| a.dig("stats", "values", "kills").to_i.to_s.size <=> b.dig("stats", "values", "kills").to_i.to_s.size }
        .dig("stats", "values", "kills").to_i.to_s.size
    end.max + 8

    response.dig("result").each do |vehicle_type|
      res << vehicle_type.dig("name")
      vehicle_type.dig("vehicles").each do |vehicle|
        res << "  #{render_incomplete_vehicle(vehicle, name_pad)}"
      end

      res << ""
    end

    bot.paginate_response(res.join("\n"), 20).map do |m|
      "```markdown\n#{m}```"
    end
  end

  def pretty_vehicle_stars(bot, name)
    response = get_vehicle_statistics(name)
    return response if not response.is_a? Hash
    return response["error"] if response.has_key? "error"

    # Calculate stars
    response["result"].map { |type| type["vehicles"]
      .map { |v| v["star"] = v["stats"]["values"]["kills"].to_i/100 } }
    name_pad = response["result"]
      .map { |type| type["vehicles"]
        .select { |v| v["star"] != nil and v["star"] >= 1 }
        .map { |v| v["name"].size }.max }
      .select { |t| t != nil }.max

    res = ["**#{name}**", ""]

    num_stars = response.dig("result").select { |type| type.dig("vehicles")
      .select { |v| v.dig("star") != 0 }.size > 0 }.size

    if num_stars == 0
      res << "No vehicle stars"
      return "```markdown\n#{res.join("\n")}```"
    end

    response["result"].each do |vehicle_type|
      stars = vehicle_type.dig("vehicles").select { |v| v.dig("star") != 0 }
      num_with_stars = stars.size
      num = vehicle_type.dig("vehicles").size

      res << "**#{vehicle_type.dig("name")} (#{num_with_stars}/#{num})**"
      vehicle_type.dig("vehicles").each do |vehicle|
        next if vehicle.dig("star") == 0

        res << "#{render_incomplete_vehicle_stars(vehicle, name_pad)}"
      end

      res << ""
    end

    bot.paginate_response(res.join("\n"), 20).map do |m|
      "```markdown\n#{m}```"
    end
  end

  # Render (incomplete) information about a vehicle.
  def render_incomplete_vehicle(vehicle, name_pad=0, kills_pad=0)
    time = ChronicDuration.output(vehicle.dig("stats", "values", "seconds")&.to_i,
                                  format: :long, units: 2)
    %{#{vehicle.dig("name")&.ljust(name_pad, ' ')}     \
#{(vehicle.dig("stats", "values", "kills")&.to_i&.to_s + " kills").ljust(kills_pad, ' ')}     #{time}}
  end

  def render_incomplete_vehicle_stars(vehicle, name_pad=0)
    %{#{(vehicle.dig("name") + "\t")&.ljust(name_pad, ' ')}\
#{(vehicle.dig("star")&.to_i&.to_s + " stars")}}
  end
end
