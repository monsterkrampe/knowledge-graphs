require "../graph/graph"

module Exercises
  extend self
  include Graph
  EXERCISES = ["0", "1_2", "1_3", "2_2", "2_3"]

  def exercise0(graph : AGraph)
    "Nodes with max out degree (#{graph.max_out_degree}): #{graph.nodes_with_max_out_degree}\n" +
      "Nodes with min in degree (#{graph.min_in_degree}): #{graph.nodes_with_min_in_degree}"
  end

  def exercise1_2(graph : AGraph)
    graph.metis_string
  end

  def exercise1_3(graph : AGraph)
    graph.number_of_triangles
  end

  def exercise2_2(graph : AGraph)
    puts "Graph built"
    graph.bipartite?
  end

  def exercise2_3(graph : AGraph)
    raise ArgumentError.new unless graph.is_a? RDF_Graph
    puts "Graph built"
    graph.connected_component_containing("<http://dblp.uni-trier.de/pers/s/Studer:Rudi>").number_of_edges
  end

  def create_graph(filename : String?, gzipped : Bool = false, n_tuples : Bool = false) : AGraph
    raise ArgumentError.new if filename.nil?
    if n_tuples
      RDF_Graph.from_filename(filename, gzipped)
    else
      DefaultGraph.from_filename(filename, gzipped)
    end
  end

  def run(exercise : String?, filename : String?, gzipped : Bool, n_tuples : Bool)
    {% begin %}
      case exercise
      {% for e in EXERCISES %}
        when {{e}}
          puts exercise{{e.id}} create_graph(filename, gzipped, n_tuples)
      {% end %}
      else
        STDERR.puts "ERROR: #{exercise} is not a valid exercise."
        STDERR.puts "Valid exercises are: " + EXERCISES.join(", ")
        exit(1)
      end
    {% end %}
  end
end
