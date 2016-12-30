require 'rest_client'
require 'chronic_duration'
require 'json'
require_relative '../../bot-feature.rb'


class BF1TrackerFeature < BotFeature
  def initialize
    # The experience required to get to a rank.
    @ranks = [0, 1000, 5000, 15000, 25000, 40000, 55000, 75000, 95000, 120000, 145000, 175000, 205000, 235000, 265000, 295000, 325000, 355000, 395000, 435000, 475000, 515000, 555000, 595000, 635000, 675000, 715000, 755000, 795000, 845000, 895000, 945000, 995000, 1045000, 1095000, 1145000, 1195000, 1245000, 1295000, 1345000, 1405000, 1465000, 1525000, 1585000, 1645000, 1705000, 1765000, 1825000, 1885000, 1945000, 2015000, 2085000, 2155000, 2225000, 2295000, 2365000, 2435000, 2505000, 2575000, 2645000, 2745000, 2845000, 2945000, 3045000, 3145000, 3245000, 3345000, 3445000, 3545000, 3645000, 3750000, 3870000, 4000000, 4140000, 4290000, 4450000, 4630000, 4830000, 5040000, 5260000, 5510000, 5780000, 6070000, 6390000, 6730000, 7110000, 7510000, 7960000, 8430000, 8960000, 9520000, 10130000, 10800000, 11530000, 12310000, 13170000, 14090000, 15100000, 16190000, 17380000, 20000000]
  end

  def load(bot)
    config = bot.get_config_for_module(__FILE__)
    @config = {
      "bftracker_api_key": ""
    }

    bot.map_config(config, @config)

    @header = {"TRN-Api-Key": @config[:bftracker_api_key]}
    @enabled = (@config[:bftracker_api_key] != "")

    @location_cache = {}
  end

  def register_handlers(bot, scheduler)
    bot.message(contains: /^[!\/]bf1? [A-Za-z0-9]+/) do |event|
      next if not handler_check event

      event.respond "Missing API key" if not @enabled
      message = event.message.to_s.split(/ /)
      message.delete_at 0
      event.respond pretty_basic_statistics(message.join " ")
    end

    bot.message(contains: /^[!\/]bf1? -[A-Za-z]+ [A-Za-z0-9]+/) do |event|
      next if not handler_check event

      event.respond "Missing API key" if not @enabled
      message = event.message.to_s.split(/ /)
      message.delete_at 0
      sub = message[0]
      message.delete_at 0

      if sub =~ /kits?/
        event.respond pretty_kit_statistics(message.join " ")
      end
    end
  end

  private

  ##### Helper Methods
  # checks to be ran on all events, returns false if event should be skipped
  def handler_check(event)
    if not @enabled
      event.respond "Missing API Key"
      false
    else
      true
    end
  end

  # Returns a JSON hash if a valid result was provided; otherwise returns a string.
  def get_rest_api(path)
    begin
      res = RestClient.get(path, headers=@header)
    rescue RestClient::BadRequest
      return "Unknown user"
    end

    return "Unknown error" if !res or res.code != 200

    JSON.load res.body
  end
  ##### End helper methods

  # Does a rest query to bf1tracker for basic stats for a provided username.
  def get_basic_statistics(name)
        get_rest_api("https://battlefieldtracker.com/bf1/api/Stats/BasicStats?platform=3&displayName=#{name}")
  end

  # Does a rest query to bf1tracker for detailed stats for a provided username.
  def get_detailed_statistics(name)
    get_rest_api("https://battlefieldtracker.com/bf1/api/Stats/DetailedStats?platform=3&displayName=#{name}")
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

  # Given someone's rank and their progress towards the next rank, return their total experience
  def get_total_experience(rank, progress)
    @ranks[rank.to_i] + progress.to_i
  end
end
