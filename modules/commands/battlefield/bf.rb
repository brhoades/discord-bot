require_relative '../../../bot-feature.rb'
require_relative 'bf1_api.rb'
require_relative 'basic_stats.rb'
require_relative 'detailed_stats.rb'


class BF1TrackerFeature < BotFeature
  def initialize
    # The experience required to get to a rank.
    @ranks = [0, 1000, 5000, 15000, 25000, 40000, 55000, 75000, 95000, 120000, 145000, 175000, 205000, 235000, 265000, 295000, 325000, 355000, 395000, 435000, 475000, 515000, 555000, 595000, 635000, 675000, 715000, 755000, 795000, 845000, 895000, 945000, 995000, 1045000, 1095000, 1145000, 1195000, 1245000, 1295000, 1345000, 1405000, 1465000, 1525000, 1585000, 1645000, 1705000, 1765000, 1825000, 1885000, 1945000, 2015000, 2085000, 2155000, 2225000, 2295000, 2365000, 2435000, 2505000, 2575000, 2645000, 2745000, 2845000, 2945000, 3045000, 3145000, 3245000, 3345000, 3445000, 3545000, 3645000, 3750000, 3870000, 4000000, 4140000, 4290000, 4450000, 4630000, 4830000, 5040000, 5260000, 5510000, 5780000, 6070000, 6390000, 6730000, 7110000, 7510000, 7960000, 8430000, 8960000, 9520000, 10130000, 10800000, 11530000, 12310000, 13170000, 14090000, 15100000, 16190000, 17380000, 20000000]
  end

  def load(bot)
    config = bot.get_config_for_module(__FILE__)
    @config = {
      "bftracker_api_key": "",
      "": ""
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
  include BF1BasicStats 
  include BF1DetailedStats 
end
