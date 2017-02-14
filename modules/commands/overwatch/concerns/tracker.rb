require 'text-table'

module Overwatch
  module Tracker
    private
    def register_tracker_handlers(bot, scheduler)
      # TODO: Help
      # TODO: Admin
      # TODO: Customizeable frequency

      bot.message(contains: /^\!(owt|owtracker)\s/) do |event|
        tracker_commands(event)
      end

      scheduler.cron '0 * * * *' do
        tracker_schedule
      end
    end

    # Register !owt -add
    # and !owt -list
    def tracker_commands(event)
      options = parse_args event.message.to_s

      if options[:args].has_key?("add") and options[:target] != nil
        user = get_username(options[:target])
        if user[:message] != "" and (user[:long] == nil or user[:short] == nil)
          event.respond user[:message]
          return
        end
        message = Message.ensure(event.message)

        # OverwatchTrackedUser.where(name: user[:long], added_by: message.user).first_or_initialize do |u|
        OverwatchTrackedUser.where(name: user[:long]).first_or_initialize do |u|
          u.save!
          event.respond("User #{user[:long]} will now have their Overwatch statistics tracked.")
          return
        end
        event.respond("User #{user[:long]} is already being tracked.")
      elsif options[:args].has_key?("list")
        users = OverwatchTrackedUser.all

        table = Text::Table.new
        table.head = ["User", "Added On", "Records (hr)"]
        table.rows = []

        users.each do |u|
          records = OverwatchHistory.where(tag: u.name)

          # TODO: Timezone
          table.rows << [u.name, u.created_at.getlocal.to_formatted_s(:long_ordinal), records.size]
        end

        event.respond("```\n#{table.to_s}```")
      else
        event.respond("!help ow")
      end
    end

    def tracker_schedule
      puts "Updating tracked overwatch users..."
      OverwatchTrackedUser.all.each do |u|
        print "  #{u.name}:"
        data = get_data(u.name)
        if data.has_key? "error"
          puts data["error"]
          next
        end

        OverwatchHistory.new(tag: u.name, data: data).save
        puts " DONE"
      end
    end
  end
end
