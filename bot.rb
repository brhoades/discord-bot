require 'discordrb'

bot = Discordrb::Bot.new token: ENV["BOT_TOKEN"], client_id: 251052745790849027

bot.message(with_text: 'Ping!') do |event|
  event.respond 'Pong!'
end

bot.run
