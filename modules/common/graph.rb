require 'gruff'


module Common
  module Graph
    class Graph
      # Graph a time series to a file. Provide a title to put at the top of the page.
      # The labels hash keys correspond to the indicies in each values array. These are the x axis labels.
      # values and value_labels are both arrays. value_labels contains the value label for each
      #   subarray of values. While values contains an array of arrays of value data.
      #
      # Option arguments:
      #   http://gruff.rubyforge.org/
      #   width: 300, 400, 800
      def self.graph_time_series(file, title, labels, value_labels, values,
                                 width: 400, hide_lines: false, hide_dots: true)
        graph = Gruff::Line.new(width)
        graph.title = title
        graph.labels = labels

        graph.hide_lines = hide_lines
        graph.hide_dots = hide_dots

        value_labels.zip(values) do |label, data|
          graph.data(label, data)
        end

        graph.write(file.path)
      end
    end
  end
end
