require "http/client"
require "json"

require "../graph/graph"
require "../dblp_crawler/dblp_crawler"

module Exercises
  extend self
  include Graph
  EXERCISES_USING_LOCAL_FILE = ["0", "1_2", "1_3", "2_2", "2_3", "4_5"]
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
    query = "SELECT ?pLabel ?wLabel WHERE {
      ?t ^wdt:P1344 ?p ;
        ^wdt:P2522 ?w .

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
      {% for e in EXERCISES_USING_LOCAL_FILE %}
        when {{e}}
          puts exercise{{e.id}} create_graph(filename, gzipped, n_tuples)
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
