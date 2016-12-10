class BotFeature
  def register_schedules(scheduler)
    puts "PARENT METHOD."
  end

  def register_bot_handlers(bot)
    puts "PARENT METHOD."
  end

  def self.descendants
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
end
