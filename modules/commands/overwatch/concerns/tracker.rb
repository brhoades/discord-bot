require 'text-table'
require 'tempfile'

require 'graph'
require 'history_tracker'
# https://gist.github.com/henrik/146844
class Hash
  def deep_diff(b)
    a = self
    (a.keys | b.keys).inject({}) do |diff, k|
      if a[k] != b[k]
        if a[k].respond_to?(:deep_diff) && b[k].respond_to?(:deep_diff)
          diff[k] = a[k].deep_diff(b[k])
        else
          diff[k] = [a[k], b[k]]
        end
      end
      diff
    end
  end
end


module Overwatch
  module Tracker
    include Common::Graph
    include Common::HistoryTracker
    def register_tracker_handlers(bot, scheduler)
      # TODO: Help
      # TODO: Admin
      # TODO: Customizeable frequency

      bot.message(contains: /^\!(owt|owtracker)\s/) do |event|
        tracker_commands(event)
      end

      scheduler.cron '0 * * * *' do
        begin
          tracker_schedule
        rescue Exception => e
          puts %{Error: #{e.to_s}\n\n#{e.backtrace.join("\n")}}
        end
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
      elsif options[:args].has_key?("graph")
        args = options[:target].split(/\s+/)
        if args.size != 2
          event.respond "At least two arguments expected (graph type and argument)"
          return
        end
        
        target = get_username(args[1])
        if target.has_key? "error"
          event.respond target[:error]
          return
        end

        target = target[:long]
        graph = HistoryTrackerGraphing.new(OverwatchHistory)

        file = Tempfile.new ['graph', '.png']
        file.close
        attr = args[0]

        if not @graph_types.has_key?(attr.to_sym)
          event.respond "Unknown option '#{attr}'"
        end

        begin
          type = @graph_types[attr.to_sym]

          graph.graph_data_from_attr(target, type, file)

          file.open
          event.channel.send_file(file)
        ensure
          file.close
          file.unlink
        end
      else
        event.respond("!help ow")
      end
    end
  end
end
