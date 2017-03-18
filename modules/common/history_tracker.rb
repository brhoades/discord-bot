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
        Common::Graph::Graph::graph_time_series(file, title, labels, value_labels, values,
                                                width: attribute.dig(:width))
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

        def inner_filter_data(index, data)
          if index.is_a? Proc
            index.call(data)
          else
            # Multiple indices?
            data.dig(*index)
          end 
        end

        # ADD DATA
        num_labels = 5
        label_count = history.size / num_labels

        history.each_with_index do |hist, h_i|
          if attribute.dig(:multi_series) == nil
            if hist.data == {}
              values[0] << values[0].last
            else
              values[0] << inner_filter_data(attribute[:index], hist.data)
            end
          else
            if hist.data != {}
              inner_filter_data(attribute[:index], hist.data).each_with_index do |output, i|
                if values.size <= i
                  values << []
                end

                values[i] << output
              end
            else
              # data was null, propogate old data
              values.map { |v| v << v.last }
            end
          end

          if h_i % label_count == 0
            labels[h_i] = hist.created_at.getlocal.strftime("%F")
          end
        end

        # Series Labels
        series_labels = ["Unknown Label"]
        if attribute[:label].is_a?(String)
          series_labels = [attribute[:label]]
        elsif attribute[:label].is_a?(Proc)
          series_labels = attribute[:label].call(history.first.data)
        end

        [attribute[:title].gsub(/\{\}/, target), labels, values, series_labels]
      end
    end
  end
end
