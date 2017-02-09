class BotFeature
  def register_handlers(bot, scheduler)
  end

  def load(bot)
  end

  def before_run
  end

  # Ran when the bot becomes ready
  def ready(bot, scheduler)
  end

  def self.descendants
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end

  # Parses a command with arg (-arg) and value pairs (-arg value)
  # Returns a hash:
  #
  # { command: --, args: [{key: value, ...}, {}], target: --}
  # args can have nil values, target can be nil
  def parse_args(message, has_target=true)
    ret = {
      command: nil,
      args: {},
      target: nil
    }
    raw_args = message.split(/\s+/)
    return ret if raw_args.size == 0

    ret[:command] = raw_args[0].sub /^\W/, ""
    raw_args.delete_at 0

    return ret if raw_args.size == 0

    args = raw_args.join " "
    # Scrape out a target on tail of a command, as long as it's not part of a -arg=(...) or !(...).
    target_regex = /(?:\W?\s+|^)([\s\w]+)$/

    if has_target and args =~ target_regex
      ret[:target] = $1
    end

    return ret if raw_args.size == 0

    args.scan(/-(\w+)(\=\w+)?/) do |key, value|
      if value
        value.sub! /\=/, ""
      end

      ret[:args][key] = value
    end

    ret
  end
end
