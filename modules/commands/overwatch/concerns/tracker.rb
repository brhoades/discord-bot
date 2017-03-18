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

      scheduler.every '5m' do
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
        if not target or target.has_key?("error")
          event.respond target[:error] if target
          return
        end

        target = target[:long]
        graph = HistoryTrackerGraphing.new(OverwatchHistory)

        file = Tempfile.new ['graph', '.png']
        file.close
        attr = args[0]

        if not @graph_types.has_key?(attr.to_sym)
          event.respond "Unknown option '#{attr}'"
          return
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
      elsif options[:args].has_key?("update")
        tracker_schedule
      else
        event.respond("!help ow")
      end
    end

    def tracker_schedule
      puts "Updating tracked overwatch users..."
      OverwatchTrackedUser.all.each do |u|
        # print "  #{u.name}:"

        # IF
        old = OverwatchHistory.where(tag: u.name).order("created_at DESC")
        same = false

        if old.size > 0
          # If it hasn't been @update_frequency since our last update, quit.
          if old.first.created_at.to_i + @update_frequency > Time.now.to_i
            #TODO: LOG
            # puts " RECENT (no update)"
            next
          end
        end
        data = get_data(u.name)

        if data.has_key? "error"
          puts data["error"]
          next
        end

        if old.size > 0
          old.each do |o_hist|
            if o_hist.data == {}
              next
            else
              if o_hist.data.deep_diff(data) == {}
                same = true
              end
              break
            end
          end
        end

        if same
          OverwatchHistory.new(tag: u.name, data: {}).save!
        else
          OverwatchHistory.new(tag: u.name, data: data).save!
        end

        # puts " DONE"
        sleep 5
      end
    end
  end
end
