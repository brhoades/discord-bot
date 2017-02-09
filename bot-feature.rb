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

    argregex = /(?:\s+|^)\-{1,2}(\w+)(\=\w+)?/
    args.scan(argregex) do |key, value|
      if value
        value.sub! /\=/, ""
      end

      ret[:args][key] = value
    end

    args.gsub! argregex, ""

    return ret if args.strip == ""

    # Remainder is the target
    ret[:target] = args.strip

    ret
  end
end
