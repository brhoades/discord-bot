module BF1
  module WeaponStats
    private

    # Does a rest query to bf1tracker for detailed stats for a provided username.
    def get_weapons_statistics(name)
      if name =~ /^\s*$/
        return {"error" => "No username provided."}
      end

      get_data("https://battlefieldtracker.com/bf1/api/Progression/GetWeapons?platform=3&displayName=#{name}")
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

    # Get stars information about a person and return a stringifed detail list.
    def get_stars_statistics(name)
      response = get_weapons_statistics(name)
      return response if not response.is_a? Hash

      res = ["**#{response.dig("profile", "displayName")}**", "", "```markdown"]
      maxsize = response.dig("result")
                  .map {|type| type.dig("weapons")
                          .map {|weapon| weapon.dig("name").length if weapon.dig("star", "timesAquired") != nil}
                          .compact.flatten }
                  .flatten.compact.max

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

  end
end
