require "gzip"

module Graph
  abstract class AGraph
    getter edges

    abstract def clone

    def initialize
      @edges = {} of Int32 => Array(Int32)
    end

    def metis_string : String
      lines = ["#{number_of_nodes} #{number_of_edges}"]
      @edges.each do |source, targets|
        lines << (targets.size > 0 ? "#{source} #{targets.sort.join(' ')}" : source.to_s)
      end
      (lines.join '\n') + '\n'
    end

    def shortest_paths(s : Int32)
      num_nodes = nodes.size
      # paths = Hash(Int32, Array(Array(Int32))?).new { nil }
      paths = Array(Array(Array(Int32))?).new(num_nodes) {nil}

      newly_added = Set(Int32).new

      paths[s] = [[s]]

      @edges[s].each do |t|
        paths[t] = [[s, t]]
        newly_added << t
      end

      while newly_added.size > 0
        added_before = newly_added
        newly_added = Set(Int32).new(num_nodes)

        added_before.each do |t|
          next unless @edges.has_key?(t)

          @edges[t].each do |real_target|
            if paths[real_target].nil?
              paths[real_target] = paths[t].as(Array(Array(Int32))).map(&.+ [real_target])
              newly_added << real_target
            elsif newly_added.includes? (real_target)

              paths[real_target].as(Array(Array(Int32))).concat(paths[t].as(Array(Array(Int32))).map(&.+ [real_target]))
            end
          end
        end
      end

      paths
    end

    def node_betweenness : Array(Float64)
      betweenness(false).as(Array(Float64))
    end

    def edge_betweenness : Hash(Tuple(Int32, Int32), Float64)
      betweenness(true).as(Hash(Tuple(Int32, Int32), Float64))
    end

    private def betweenness(for_edges? : Bool) : Array(Float64) | Hash(Tuple(Int32, Int32), Float64)
      betweenness = for_edges? ?
        Hash(Tuple(Int32, Int32), Float64).new(0) :
        Array(Float64).new(number_of_nodes, 0)

      number_of_nodes.times do |s|
        all_shortest_paths = shortest_paths(s)

        number_of_nodes.times do |t|
          next if s == t && !for_edges?

          next if all_shortest_paths[t].nil?

          all_shortest_paths_for_t = all_shortest_paths[t].as(Array(Array(Int32)))

          total_number_of_paths = all_shortest_paths_for_t.size

          node_before = nil
          all_shortest_paths_for_t.each do |shortest|
            shortest.each do |node|
              if for_edges?
                unless node == s || node_before.nil?
                  betweenness.as(Hash(Tuple(Int32, Int32), Float64))[{node_before, node}] += 1_f64 / total_number_of_paths
                end
                node_before = node
              else
                next if node == s || node == t
                betweenness.as(Array(Float64))[node] += 1_f64 / total_number_of_paths
              end
            end
          end
        end
      end

      betweenness
    end

    def communities : Array(Array(Int32))
      coms = [] of Array(Int32)

      nodes_left = nodes
      while nodes_left.size > 0
        next_node = nodes_left.shift
        neighbors = [next_node]

        neighbor_size_before = 0

        while neighbor_size_before < neighbors.size
          neighbor_size_before = neighbors.size
          i_point_at = [] of Int32
          point_at_me = [] of Int32

          neighbors.each do |neighbor|
            i_point_at.concat(edges[neighbor])
            point_at_me.concat(nodes_left.select { |n| edges[n].includes? neighbor })
          end

          neighbors.concat(i_point_at).concat(point_at_me).uniq!
          nodes_left -= neighbors
        end

        coms << neighbors
      end

      coms
    end

    def girvan_newman(level : Int32) : Array(Array(Int32))
      cloned = clone

      current_coms = cloned.communities
      puts current_coms.size

      size_at_beginning = current_coms.size

      while (current_coms.size - size_at_beginning < level && cloned.number_of_edges > 0)
        source, target = cloned.edge_betweenness.max_by(&.last).first
        cloned.@edges[source].delete(target)

        current_coms = cloned.communities
      end

      puts current_coms.size

      current_coms
    end

    def nodes
      @edges.keys
    end

    def number_of_nodes
      nodes.size
    end

    def number_of_edges
      @edges.values.map(&.size).sum
    end

    def add_node(node : Int32)
      @edges[node] = Array(Int32).new unless @edges.has_key? node
    end

    def add_edge(node1, node2)
      @edges[node1] << node2
    end

    def out_degree(node : Int32) : Int
      @edges[node].size
    end

    def in_degree(node : Int32) : Int
      @edges.values.sum { |value| (value.includes? node) ? 1 : 0}
    end

    def get_neighbors(node : Int32) : Array(Int32)
      @edges[node]
    end

    def max_out_degree : Int
      nodes.map { |node| out_degree(node) } .max
    end

    def min_in_degree : Int
      nodes.map { |node| in_degree(node) } .min
    end

    def nodes_with_max_out_degree : Array(Int32)
      max_out_degree = self.max_out_degree
      nodes.select { |node| out_degree(node) == max_out_degree }
    end

    def nodes_with_min_in_degree : Array(Int32)
      min_in_degree = self.min_in_degree
      nodes.select { |node| in_degree(node) == min_in_degree }
    end

    def number_of_triangles(edges) : Int
      number_of_triangles = 0
      nodes.each do |node|
        edges[node].each do |second_node|
          edges[second_node].each do |third_node|
            number_of_triangles += 1 if edges[third_node].includes? node
          end
        end
      end
      number_of_triangles
    end

    def number_of_triangles : Int
      number_of_triangles(@edges)
    end

    def bipartite? : Bool
      node_taken = Array.new(self.nodes.size, false)
      colors = {} of Int32 => Bool
      node = node_taken.index(false)
      node_taken[node] = true unless node.nil?
      while !node.nil?
        puts "Node"
        puts node
        neighbors = get_neighbors(node)

        partition = neighbors.partition { |n| colors.has_key? n }
        uncolored_neighbors = partition.last
        colored_neighbors = partition.first

        if colored_neighbors.size > 0
          next_color = !colors[colored_neighbors.first]
        else
          next_color = false
        end
        colors[node] = next_color
        next_color = !next_color

        while uncolored_neighbors.size > 0
          puts "uncolored_neighbors"
          puts uncolored_neighbors.size
          neighbors = Array(Int32).new

          return false if colored_neighbors.any? { |cn| colors[cn] != next_color }

          uncolored_neighbors.each do |un|
            node_taken[un] = true
            neighbors.concat(get_neighbors un)
            colors[un] = next_color
          end

          next_color = !next_color

          partition = neighbors.uniq.partition { |n| colors.has_key? n }
          uncolored_neighbors = partition.last
          colored_neighbors = partition.first
        end

        return false if colored_neighbors.any? { |cn| colors[cn] != next_color }

        node = node_taken.index(false, node + 1)
        node_taken[node] = true unless node.nil?
      end

      return true
    end

    def connected_component_containing(node : Int32) : AGraph
      target_graph = self.class.new
      node_taken = Array.new(self.nodes.size, false)
      neighbors = [node]
      while neighbors.size > 0
        new_neighbors = [] of Int32
        neighbors.each do |n|
          node_taken[n] = true
          target_graph.add_node n
          @edges[n].each do |e|
            target_graph.add_edge n, e
          end
          new_neighbors.concat(get_neighbors n)
        end
        neighbors = new_neighbors.uniq.select { |node| !node_taken[node]}
      end

      target_graph
    end
  end

  class DefaultGraph < AGraph
    def_clone

    def self.from_filename(filename : String, gzipped : Bool) : DefaultGraph
      if gzipped
        content = Gzip::Reader.open(filename) { |gzip_file| gzip_file.gets_to_end }
      else
        content = File.read(filename)
      end
      lines = content.strip.split '\n'
      number_of_nodes = lines.first.to_i

      graph = DefaultGraph.new
      number_of_nodes.times do |index|
        graph.add_node index
      end

      lines[1..-1].each do |line|
        graph.add_edge(*Tuple(Int32, Int32).from(line.split(' ').map(&.to_i)))
      end

      graph
    end

    def self.from_metis_file(filename : String, starts_index_from_1 : Bool = false) : DefaultGraph
      content = File.read(filename)
      lines = content.strip.split '\n'

      graph = DefaultGraph.new

      lines[0].split(' ')[0].to_i.times { |i| graph.add_node(i) }

      lines[1..-1].each do |line|
        numbers = line.split(' ')
        source = numbers.first.to_i

        numbers[1..-1].each do |target|
          if (starts_index_from_1)
            graph.add_edge(source - 1, target.to_i - 1)
          else
            graph.add_edge(source, target.to_i)
          end
        end
      end

      graph
    end
  end

  class RDF_Graph < AGraph
    def_clone

    def initialize
      super
      @next_number = 0
      @map_name_to_number = {} of String => Int32
      @map_label_to_edges = {} of String => Array(Tuple(Int32, Int32))
    end

    def self.from_filename(filename : String, gzipped : Bool) : RDF_Graph
      if gzipped
        file = Gzip::Reader.new(filename)
      else
        file = File.new(filename)
      end

      graph = self.from_io file

      file.close

      graph
    end

    def self.from_io(io : IO)
      self.from_io_or_contents io
    end

    def self.from_contents(contents : String)
      self.from_io_or_contents contents.strip
    end

    private def self.from_io_or_contents(io_or_contents : IO | String)
      graph = self.new

      io_or_contents.each_line do |line|
        line_data = line.split ' '

        node1 = graph.add_node_using_label(line_data[0])
        node2 = graph.add_node_using_label(line_data[2])
        graph.add_edge_with_label(node1, node2, line_data[1])
      end

      graph
    end

    def get_label_for_node(node : Int32)
      @map_name_to_number.key_for node
    end

    # Form:
    # node, "label"
    def node_label_string
      String.build do |str|
        nodes.each do |node|
          str << "#{node}, \"#{get_label_for_node(node)}\"\n"
        end
      end
    end

    def get_labels_for_edge(edge : Tuple(Int32, Int32)) : Array(String)
      labels = [] of String
      @map_label_to_edges.each do |key, val|
        labels << key if val.includes? edge
      end
      labels
    end

    def get_node_labels
      @map_name_to_number.keys
    end

    def to_triples : Array(Tuple(String, String, String))
      triples = [] of Tuple(String, String, String)
      @map_label_to_edges.each do |edge_label, edges|
        edges.each do |edge|
          triples << {get_label_for_node(edge.first), edge_label, get_label_for_node(edge.last)}
        end
      end
      triples
    end

    def add_node_using_label(label : String)
      if @map_name_to_number.has_key? label
        node = @map_name_to_number[label]
      else
        node = @next_number
        @map_name_to_number[label] = node
        @next_number += 1
      end

      add_node node
      node
    end

    def add_edge_with_label(node1 : Int32, node2 : Int32, label : String)
      add_edge(node1, node2)

      @map_label_to_edges[label] = [] of Tuple(Int32, Int32) unless @map_label_to_edges.has_key?(label)
      @map_label_to_edges[label] << {node1, node2}
    end

    def connected_component_containing(node : String) : AGraph
      super(@map_name_to_number[node])
    end

    def merge(other : RDF_Graph)
      other.to_triples.each do |triple|
        node1 = add_node_using_label(triple[0])
        node2 = add_node_using_label(triple[2])
        add_edge_with_label(node1, node2, triple[1])
      end
    end

    def number_of_triangles_with_edge_label(label : String)
      puts "filtering edges"
      filtered_edges = {} of Int32 => Array(Int32)
      nodes.each { |i| filtered_edges[i] = [] of Int32 }
      @map_label_to_edges[label].each do |a, b|
        filtered_edges[a] << b
      end
      puts "edges_filtered"
      number_of_triangles(filtered_edges)
    end
  end

  class DBLP_Graph < RDF_Graph
    def authors
      get_node_labels.select { |label| label.includes? "/pers" }
    end

    def publications
      get_node_labels.select { |label| label.includes? "/rec" }
    end

    def publications_with_only_author(author : String)
      author_id = @map_name_to_number[author]

      publications.select do |pub|
        pub_id = @map_name_to_number[pub]
        authors : Array(Int32) = edges[pub_id]

        authors.includes?(author_id) && authors.flat_map{ |a| get_labels_for_edge({pub_id, a}) }.count(&.includes? "authoredBy") == 1
      end
    end
  end
end
