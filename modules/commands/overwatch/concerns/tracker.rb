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
        file = Tempfile.new ['graph', '.png']
        file.close
        puts args

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

        # IF
        old = OverwatchHistory.where(tag: u.name).order("created_at DESC")
        same = false

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

        puts " DONE"
        sleep 5
      end
    end

    # Returns a filename
    # attr is an array of indicies to get in data.
    def graph_playtime(user, file, attr)
      if not @graph_types.has_key? attr.to_sym
        puts @graph_types
        return "Unknown option '#{attr}'"
      end
      type = @graph_types[attr.to_sym]

      history = OverwatchHistory.where(tag: user)
      graph = Gruff::Line.new
      graph.title = "Playtime for #{user}"
      labels = {}
      values = []
      label_count = 10 - 1

      if history.size == 0
        return "User has no history."
      end

      last = {}
      history.each do |hist, i|
        this = nil
        labels[i] = "test"

        if hist.data == {}
          this = last
        else
          this = hist.data
          last = this
        end

        data = nil
        if type[:index].is_a? Proc
          data = type[:index].call this["us"]["stats"]
        else
          data = this["us"]["stats"].dig(*type[:index])
        end 
        puts "DATA: #{data}"
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
