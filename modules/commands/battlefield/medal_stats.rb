require_relative 'bf1_api.rb'


module BF1MedalStats
  private
  include BF1BasicAPI

  # Does a rest query to bf1tracker to get medal stats for a provided username
  def get_medal_statistics(name)
    if name =~ /^\s*$/
      return {"error" => "No username provided."}
    end

    get_data("https://battlefieldtracker.com/bf1/api/Progression/GetMedals?platform=3&displayName=#{name}")
  end

  # Get medal information about  person and return a stringifed detail list.
  def pretty_medal_statistics(name)
    response = get_medal_statistics(name)
    return response if not response.is_a? Hash

    total = response.dig("result").map { |type| type.dig("awards").size }.reduce(0, :+)
    unlocked = response.dig("result").map { |type| type.dig("awards").map { |award| award if award.dig("progression", "unlocked") }.compact.size }.compact.reduce(0, :+)

    res = ["**#{name}** (#{unlocked}/#{total})", ""]

    response.dig("result").each do |type|
      type.dig("awards").each do |medal|
        if medal.dig("progression", "unlocked")
          res << "**#{medal.dig("name")}**"
        else
          res << render_incomplete_medal(medal)
        end
      end
    end

    res.join("\n")
  end

  # Render an incomplete medal with details about what's left
  def render_incomplete_medal(medal)
    stages = medal.dig("stages")
    stages_complete = stages.map { |s| s if s.dig("progression", "unlocked") }.compact.size

    next_stage_name = stages[stages_complete].dig("name")

    # Look at the latest criteria that's not done
    criteria = stages[stages_complete].dig("criterias")
    complete_criterias = criteria.map { |c| c if c.dig("progression", "unlocked") }.compact.size

    next_criteria = criteria[complete_criterias]
    next_stage_pro = next_criteria.dig("progression", "valueAcquired").to_i
    next_stage_max = next_criteria.dig("progression", "valueNeeded").to_i
    if next_stage_pro == 0
      return "#{medal.dig("name")} (#{stages_complete+1}/#{stages.size})"
    end

    %{#{medal.dig("name")} - stage: #{stages_complete+1}/#{stages.size} - next stage: #{next_stage_name} (#{next_stage_pro}/#{next_stage_max})}
  end

end
