class BotFeature
  def register_schedules(bot, scheduler)
  end

  def register_bot_handlers(bot)
  end

  def self.descendants
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
end
