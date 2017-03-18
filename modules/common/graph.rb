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
        graph.legend_box_size = graph.legend_font_size = 10
        graph.colors = ["#ff0000", "#fff700", "#00ffe5", "#0022ff", "#ff00ae", "#8c4400", "#40ff8f", "#6ea629", "#23648c", "#ac80ff", "#994d4d", "#fffdbf", "#f4bfff", "#86b3ae", "#998573", "#ff7b00", "#8cff00", "#009dff", "#d500ff", "#f20000", "#75008c", "#ff4066", "#263699", "#ffbd80", "#a6538c", "#ffbfbf", "#bfe7ff", "#a6d9a3", "#7c82a6"]
        graph.hide_lines = hide_lines
        graph.hide_dots = hide_dots

        value_labels.zip(values).each do |label, data|
          graph.data(label, data)
        end

        graph.write(file.path)
      end
    end
  end
end
