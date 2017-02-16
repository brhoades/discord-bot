require 'gruff'
require 'text-table'
require 'tempfile'

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
    def register_tracker_handlers(bot, scheduler)
      # TODO: Help
      # TODO: Admin
      # TODO: Customizeable frequency
      bot.message(contains: /^\!(bft|bftracker)\s/) do |event|
        tracker_commands(event)
      end

      scheduler.cron '5 * * * *' do
        tracker_schedule
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
        
        target = args[1]

        file = Tempfile.new ['graph', '.png']
        file.close

        begin
          err = graph_playtime(target, file, args[0])
          if err != nil
            event.respond err
            return
          end
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
      puts "Updating tracked battlefield users..."
      BattlefieldTrackedUser.all.each do |u|
        puts "  #{u.name}:"

        # Cycle through our 5 types...
        BattlefieldHistory::TYPE_NAMES.each_with_index do |type, type_i|
          print "    #{type}:"
          same = false
          old = BattlefieldHistory.where(tag: u.name, data_type: type_i).order("created_at DESC")

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
            puts " SAME"
          else
            BattlefieldHistory.new(tag: u.name, data: data, data_type: type_i).save!
            puts " DONE"
          end
        end

        puts "-> DONE"
        sleep 5
      end
    end

    # Returns a filename
    # attr is an array of indicies to get in data.
    def graph_playtime(user, file, attr)
      if not @graph_types.has_key? attr.to_sym
        return "Unknown option '#{attr}'"
      end
      type = @graph_types[attr.to_sym]

      history = BattlefieldHistory.where(tag: user, data_type: type[:data_type])
      graph = Gruff::Line.new
      graph.title = type[:description].gsub(/(a )?player\.?|\.$/, user)
      labels = {}
      values = []
      label_count = 3

      if history.size == 0
        return "User has no history."
      end
      label_spacing = (history.size / label_count).floor
      if label_spacing == 0
        label_spacing = 1
      end

      last = {}
      history.each_with_index do |hist, i|
        this = nil

        if i % label_spacing == 0 or i + 1 == history.size
          labels[i] = hist.created_at.getlocal
        end

        if hist.data == {}
          this = last
        else
          this = hist.data
          last = this
        end

        data = nil
        if type[:index].is_a? Proc
          data = type[:index].call this
        else
          data = this.dig(*type[:index])
        end 
        values << data
      end
      if values.size == 0
        return "No data for #{attr}"
      end

      graph.labels = labels
      graph.data type[:label], values
      graph.write(file.path)
      return nil
    end
  end
end
