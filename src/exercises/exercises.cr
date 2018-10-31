require "../graph/graph"

module Exercises
  extend self
  include Graph
  EXERCISES = ["0", "1_2", "1_3"]

  def exercise0(filename : String?)
    raise ArgumentError.new if filename.nil?
    graph = DefaultGraph.from_filename(filename)
    "Nodes with max out degree (#{graph.max_out_degree}): #{graph.nodes_with_max_out_degree}\n" +
      "Nodes with min in degree (#{graph.min_in_degree}): #{graph.nodes_with_min_in_degree}"
  end

  def exercise1_2(filename : String?)
    raise ArgumentError.new if filename.nil?
    graph = DefaultGraph.from_filename(filename)
    graph.metis_string
  end

  def exercise1_3(filename : String?)
    raise ArgumentError.new if filename.nil?
    graph = DefaultGraph.from_filename(filename)
    graph.number_of_triangles
  end

  def run(exercise : String?, filename : String?)
    {% begin %}
      case exercise
      {% for e in EXERCISES %}
        when {{e}}
          puts exercise{{e.id}} filename
      {% end %}
      else
        STDERR.puts "ERROR: #{exercise} is not a valid exercise."
        STDERR.puts "Valid exercises are: " + EXERCISES.join(", ")
        exit(1)
      end
    {% end %}
  end
end
