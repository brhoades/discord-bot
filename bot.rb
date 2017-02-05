require 'discordrb'
require 'rufus-scheduler'
require_relative 'bot-feature.rb'
require_relative 'bot-overrides.rb'
require_relative 'db-config.rb'


# https://discordapp.com/oauth2/authorize?client_id=251052745790849026&scope=bot&permissions=70282304
features = []

bot = Discordrb::Bot.new
scheduler = Rufus::Scheduler.new

bot.features.map { |f| f.load bot }

# Load modules

bot.features.map { |f| f.register_handlers(bot, scheduler) }

bot.features.map { |f| f.before_run }

bot.ready do |event|
  bot.features.map { |f| f.ready(bot, scheduler) }
end

bot.run

#TODO: store user stats... number of words, number of lines, images, links, most popular phrases, etc. STore it all.
#TODO: Fix global madness.
