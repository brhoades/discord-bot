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


module BF1
  module Tracker
    include Common::Graph
    include Common::HistoryTracker
    def register_tracker_handlers(bot, scheduler)
      # TODO: Help
      # TODO: Admin
      # TODO: Customizeable frequency
      bot.message(contains: /^\!(bft|bftracker)\s/) do |event|
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

    def tracker_commands(event)
      options = parse_args event.message.to_s

      if options[:args].has_key?("add") and options[:target] != nil
        user = options[:target]
        message = Message.ensure(event.message)

        BattlefieldTrackedUser.where(name: user).first_or_initialize do |u|
          u.save!
          event.respond("User #{user} will now have their Battlefield statistics tracked.")
          return
        end
        event.respond("User #{user} is already being tracked.")
      elsif options[:args].has_key?("list")
        users = BattlefieldTrackedUser.all

        table = Text::Table.new
        table.head = ["User", "Added On", "Hours Recorded (total records)"]
        table.rows = []

        users.each do |u|
          records = BattlefieldHistory.where(tag: u.name).size
          records_uniq = BattlefieldHistory.where(tag: u.name).group("data_type").count.values.min

          # TODO: Timezone
          table.rows << [
            u.name,
            u.created_at.getlocal.to_formatted_s(:long_ordinal),
            "#{records_uniq} (#{records})"
          ]
        end

        event.respond("```\n#{table.to_s}```")
      elsif options[:args].has_key?("graph")
        args = options[:target].split(/\s+/)
        if args.size != 2
          event.respond "At least two arguments expected (graph type and argument)"
          return
        end

        attr = args[0]
        target = args[1]

        file = Tempfile.new ['graph', '.png']
        file.close

        begin
          if not @graph_types.has_key?(attr.to_sym)
            event.respond "Unknown option '#{attr}'"
          end
          # Create the graph
          type = @graph_types[attr.to_sym]
          graph = HistoryTrackerGraphing.new(BattlefieldHistory)

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
        event.respond("!help bft")
      end
    end

    def get_data_by_index(index, user)
      # By index in BattlefieldHistory::TYPE
      [
        method(:get_basic_statistics),
        method(:get_detailed_statistics),
        method(:get_weapons_statistics),
        method(:get_medal_statistics),
        method(:get_vehicle_statistics)
      ][index].call(user)
    end

    def tracker_schedule
      # By index in BattlefieldHistory::TYPE
      # puts "Updating tracked battlefield users..."
      BattlefieldTrackedUser.all.each do |u|
        puts "  #{u.name}:"

        # Cycle through our 5 types...
        BattlefieldHistory::TYPE_NAMES.each_with_index do |type, type_i|
          print "    #{type}:"
          same = false
          old = BattlefieldHistory.where(tag: u.name, data_type: type_i).order("created_at DESC")

          if old.size > 0
            # If it hasn't been @update_frequency since our last update, quit.
            if old.first.created_at.to_i + @update_frequency > Time.now.to_i
              puts "#{old.first.created_at.to_i} + #{@update_frequency} > #{Time.now.to_i}"
              puts " RECENT (no update)"
              next
            end
          end
          data = get_data_by_index(type_i, u.name)

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
            BattlefieldHistory.new(tag: u.name, data: {}, data_type: type_i).save!
            # puts " SAME"
          else
            BattlefieldHistory.new(tag: u.name, data: data, data_type: type_i).save!
            # puts " DONE"
          end
          sleep 3
        end

        # puts "-> DONE"
      end
    end
  end
end
