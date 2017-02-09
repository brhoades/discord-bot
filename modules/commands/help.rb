require_relative '../../bot-feature.rb'


class HelpFeature < BotFeature
  def initialize
  end

  def load(bot)
    help = @help = {}
    bot.register_method(:add_help) do |options|
      options[:command].map { |c| help[c] = options }
    end
  end

  def register_handlers(bot, scheduler)
    bot.message(contains: /^[!\/]help( [A-Za-z0-9]+)?/) do |event|
      msg = event.message.to_s.split(/\s+/)
      puts msg
      msg.delete_at 0

      if msg.size == 0  # all commands
        event.respond("**Commands**\n" + (@help.values.uniq.map { |v| "#{v[:short_help]}" }.join("\n")) + "\n\nSee **!help** <command> for more details.")
      else  # command detail
        if msg[0] =~ /\!/
          msg[0].gsub /\!/, ''
        end

        if @help.has_key?(msg[0])
          event.respond(@help[msg[0]][:long_help])
        else
          event.respond("Unknown command.")
        end
      end
    end
  end
end
