require "gzip"

module Graph
  abstract class AGraph
    getter edges

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

    def number_of_triangles : Int
      number_of_triangles = 0
      nodes.each do |node|
        @edges[node].each do |second_node|
          @edges[second_node].each do |third_node|
            number_of_triangles += 1 if @edges[third_node].includes? node
          end
        end
      end
      number_of_triangles
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
    def self.from_filename(filename : String, gzipped : Bool) : DefaultGraph
      if gzipped
        content = Gzip::Reader.open(filename) { |gzip_file| gzip_file.gets_to_end }
      else
        content = File.read(filename)
      end
      lines = content.split '\n'
      number_of_nodes = lines.first.to_i

      graph = DefaultGraph.new
      number_of_nodes.times do |index|
        graph.add_node index
      end

      lines[1...-1].each do |line|
        graph.add_edge(*Tuple(Int32, Int32).from(line.split(' ').map(&.to_i)))
      end

      graph
    end
  end

  class RDF_Graph < AGraph
    def initialize
      super
      @next_number = 0
      @map_name_to_number = {} of String => Int32
      @map_edge_to_labels = {} of String => Array(Tuple(Int32, Int32))
    end

    def self.from_filename(filename : String, gzipped : Bool) : RDF_Graph
      if gzipped
        file = Gzip::Reader.new(filename)
      else
        file = File.new(filename)
      end

      graph = RDF_Graph.new

      file.each_line do |line|
        line_data = line.split ' '

        node1 = graph.add_node_using_label(line_data[0])
        node2 = graph.add_node_using_label(line_data[2])
        graph.add_edge_with_label(node1, node2, line_data[1])
      end

      file.close

      graph
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

      @map_edge_to_labels[label] = [] of Tuple(Int32, Int32) unless @map_edge_to_labels.has_key?(label)
      @map_edge_to_labels[label] << {node1, node2}
    end

    def connected_component_containing(node : String) : AGraph
      super(@map_name_to_number[node])
    end
  end
end
