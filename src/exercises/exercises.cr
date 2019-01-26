require "http/client"
require "json"

require "../graph/graph"
require "../dblp_crawler/dblp_crawler"
require "../linear_algebra/linear_algebra"

module Exercises
  extend self
  include Graph
  include Linear_Algebra
  EXERCISES_USING_LOCAL_FILE = ["0", "1_2", "1_3", "2_2", "2_3", "4_5", "12_3", "12_4"]
  EXERCISES_CRAWLING_WEB = ["3_4", "11_4"]

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

  def exercise3_4
    # publications that have Rudi Studer as their only author
    desired_author = "<https://dblp.org/pers/s/Studer:Rudi>"
    graph = DBLP_Graph.new
    graph.add_node_using_label desired_author

    graph.authors.each do |author|
      graph.merge DBLP_Crawler.get_publication_graph_for_author(author)
    end

    graph.publications.each do |pub|
      graph.merge DBLP_Crawler.get_author_graph_for_publication(pub)
    end

    graph.publications_with_only_author desired_author
  end

  def exercise4_5(graph : AGraph)
    raise ArgumentError.new unless graph.is_a? RDF_Graph
    graph.number_of_triangles_with_edge_label("<http://www.wikidata.org/prop/direct/P47>")
  end

  def exercise11_4
    # query participants of any tournaments and corresponding winners
    query = "SELECT ?p ?pLabel ?w ?wLabel WHERE {
      ?t ^wdt:P1344 ?p ;
        ^wdt:P2522 ?w ;
        wdt:P361*/wdt:P31 wd:Q19317 .

      FILTER(?p != ?w)

      SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". }
    }"

    puts query

    request_url = "https://query.wikidata.org/sparql?" + HTTP::Params.encode({query: query, format: "json"})

    puts request_url

    response = HTTP::Client.get request_url
    json_response = JSON.parse(response.body)

    graph = RDF_Graph.new

    number_of_pairs = json_response["results"]["bindings"].as_a.size

    puts "Number of pairs: #{json_response["results"]["bindings"].as_a.size}"

    json_response["results"]["bindings"].as_a.each do |binding|
      participant_label = binding["pLabel"]["value"].as_s
      winner_label = binding["wLabel"]["value"].as_s

      participant = graph.add_node_using_label participant_label
      winner = graph.add_node_using_label winner_label
      graph.add_edge winner, participant
    end

    File.write("./output/11_4_metis", graph.metis_string)

    File.write("./output/11_4_labels", graph.node_label_string)

    "Success"
  end

  def exercise12_3(graph : AGraph)
    matrix = SparseMatrix.new(graph).transpose
    vector = Vector.new(Array.new(graph.number_of_nodes, 1_f64 / graph.number_of_nodes))

    puts graph.number_of_nodes

    beta = 0.85_f64
    number_of_nodes = graph.number_of_nodes

    # use pagerank for some iterations
    1000.times do
      puts (matrix * vector * beta)[18]
      puts (1 - beta) / number_of_nodes

      vector = matrix * vector * beta + (1 - beta) / number_of_nodes

      puts vector[18]
    end

    puts vector.size

    # map indices to labels
    mapped_to_labels = Vector.new(Array(Tuple(Float64, String)).new(number_of_nodes))
    File.each_line("./output/11_4_labels") do |line|
      whole_string, index, label = line.match(/(\d+), "(.*)"/).as(Regex::MatchData)

      mapped_to_labels << {vector[index.to_i], label}
    end

    mapped_to_labels.sort_by!(&.first).reverse!

    puts mapped_to_labels

    mapped_to_labels.map_with_index { |tuple, index| "#{index + 1}. #{tuple.last}" } .join '\n'
  end

  def exercise12_4(graph : AGraph)
    # TODO
  end

  def create_graph(filename : String?, gzipped : Bool = false, n_tuples : Bool = false, metis : Bool = false) : AGraph
    raise ArgumentError.new if filename.nil?
    if n_tuples
      RDF_Graph.from_filename(filename, gzipped)
    elsif metis
      DefaultGraph.from_metis_file(filename)
    else
      DefaultGraph.from_filename(filename, gzipped)
    end
  end

  def run(exercise : String?, filename : String?, gzipped : Bool, n_tuples : Bool, metis : Bool)
    {% begin %}
      case exercise
      {% for e in EXERCISES_USING_LOCAL_FILE %}
        when {{e}}
          puts exercise{{e.id}} create_graph(filename, gzipped, n_tuples, metis)
      {% end %}
      {% for e in EXERCISES_CRAWLING_WEB %}
        when {{e}}
          puts exercise{{e.id}}
      {% end %}
      else
        STDERR.puts "ERROR: #{exercise} is not a valid exercise."
        STDERR.puts "Valid exercises are: " + EXERCISES_USING_LOCAL_FILE.join(", ") + EXERCISES_CRAWLING_WEB.join(", ")
        exit(1)
      end
    {% end %}
  end
end
