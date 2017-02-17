require_relative 'graph.rb'

module Common
  module HistoryTracker
    class HistoryTrackerGraphing
      include Common::Graph
      def initialize(history_class)
        @history_class = history_class
      end

      # Graph some data from a specific attribute in a list.
      # This functiong eneralizes graphin some data from an arbitrary history source
      # such as Battlefield or Overwatch into a single method.
      # Returns a nil unless there was an error. If there's an error, it returns a string.
      #
      # target is the target user name.
      # attribute is the attribute Hash looked up on a standard graph attribute list.
      def graph_data_from_attr(target, attribute, file)
        title, labels, values, value_labels = get_data_and_labels(target, attribute)
        Common::Graph::Graph::graph_time_series(file, title, labels, value_labels, values)
      end

      # Returns a list of [ title, labels{}, values[][], values_labels[] ]
      def get_data_and_labels(target, attribute)
        # GET DATA
        data_type = attribute.dig(:data_type)
        history = nil

        if data_type
          history = @history_class.where(tag: target, data_type: data_type).order("created_at ASC")
        else
          history = @history_class.where(tag: target).order("created_at ASC")
        end

        # FILTER DATA
        values = [[]]
        labels = {}
        value_label = []
        if attribute[:index].first.is_a?(Array)
          values = attribute[:index].size.times.map { [] }
          last_processed = attribute[:index].size.times.map { nil }
        end

        def inner_filter_data(index, data)
          if index.is_a? Proc
            index.call(data)
          else
            data.dig(*index)
          end 
        end

        # ADD DATA
        num_labels = 6
        label_count = history.size / num_labels

        history.each_with_index do |hist, h_i|
          if not attribute[:index].first.is_a?(Array)
            if hist.data == {}
              values[0] << values[0].last
            else
              values[0] << inner_filter_data(attribute[:index], hist.data)
            end
          else
            attribute[:index].each_with_index do |i, index|
              if hist.data == {}
                values[i] << last_processed[i]
              else
                values[i] << inner_filter_data(index, hist.data)
              end
            end

          end
          if h_i % num_labels == 0 or h_i == history.size - 1
            labels[h_i] = hist.created_at.getlocal.strftime("%F")
          end
        end

        [attribute[:title].gsub(/\{\}/, target), labels, values, [attribute[:label]]]
      end
    end
  end
end
