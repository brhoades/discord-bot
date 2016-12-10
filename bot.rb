require 'discordrb'
require 'rufus-scheduler'
require_relative 'bot-feature.rb'
require_relative 'bot-overrides.rb'

# https://discordapp.com/oauth2/authorize?client_id=251052745790849026&scope=bot&permissions=70282304
$features = []

current_path = File.expand_path(".")
Dir["#{File.expand_path(".")}/modules/*.rb"].map { |f| require f }

BotFeature.descendants.each do |feature_class|
  feature = feature_class.new
  $features << feature

  puts "Loaded Feature \"#{feature_class}\""
end

bot = Discordrb::Bot.new token: ENV["BOT_TOKEN"], client_id: 251052745790849027, parse_self: true
scheduler = Rufus::Scheduler.new

$features.map { |f| f.load bot }

# Load modules

$features.map { |f| f.register_handlers(bot, scheduler) }

$features.map { |f| f.before_run }

bot.run

puts "hello"

#TODO: Add hooks for each command module. before_run after_run, etc.
#TODO: store user stats... number of words, number of lines, images, links, most popular phrases, etc. STore it all.
#TODO: Fix global madness.
