class BotFeature
  def register_handlers(bot, scheduler)
  end

  def load(bot)
  end

  def before_run
  end

  def self.descendants
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
end
