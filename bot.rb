require 'discordrb'
require 'rufus-scheduler'
require_relative 'bot-feature.rb'

# https://discordapp.com/oauth2/authorize?client_id=251052745790849026&scope=bot&permissions=70282304
$QUEUE_SIZE = 3

bot = Discordrb::Bot.new token: ENV["BOT_TOKEN"], client_id: 251052745790849027, parse_self: true
scheduler = Rufus::Scheduler.new

# Load modules
current_path = File.expand_path(".")
Dir["#{current_path}/modules/*.rb"].each do |file|
  require file
end

BotFeature.descendants.each do |feature_class|
  feature = feature_class.new
  feature.register_schedules(bot, scheduler)
  feature.register_bot_handlers(bot)
  puts "Registered Feature \"#{feature_class}\""
end
bot.run

#TODO: Add hooks for each command module. before_run after_run, etc.
#TODO: store user stats... number of words, number of lines, images, links, most popular phrases, etc. STore it all.
