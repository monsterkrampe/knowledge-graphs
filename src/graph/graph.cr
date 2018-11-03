require "gzip"

module Graph
  abstract class AGraph(NodeType)
    def initialize
      @nodes = Set(NodeType).new
      @edges = {} of NodeType => Set(NodeType)
    end

    def metis_string : String
      lines = ["#{number_of_nodes} #{number_of_edges}"]
      @edges.each do |source, targets|
        lines << (targets.size > 0 ? "#{source} #{targets.to_a.sort.join(' ')}" : source.to_s)
      end
      (lines.join '\n') + '\n'
    end

    def number_of_nodes
      @nodes.size
    end

    def number_of_edges
      @edges.values.map(&.size).sum
    end

    def add_node(node : NodeType)
      @nodes << node
      @edges[node] = Set(NodeType).new unless @edges.has_key? node
    end

    def add_edge(node1, node2)
      @edges[node1] << node2
    end

    def out_degree(node : NodeType) : Int
      @edges[node].size
    end

    def in_degree(node : NodeType) : Int
      @edges.values.sum { |value| (value.includes? node) ? 1 : 0}
    end

    def get_neighbors(node : NodeType) : Set(NodeType)
      @edges[node]
    end

    def max_out_degree : Int
      @nodes.map { |node| out_degree(node) } .max
    end

    def min_in_degree : Int
      @nodes.map { |node| in_degree(node) } .min
    end

    def nodes_with_max_out_degree : Set(NodeType)
      max_out_degree = self.max_out_degree
      @nodes.select { |node| out_degree(node) == max_out_degree } .to_set
    end

    def nodes_with_min_in_degree : Set(NodeType)
      min_in_degree = self.min_in_degree
      @nodes.select { |node| in_degree(node) == min_in_degree } .to_set
    end

    def number_of_triangles : Int
      number_of_triangles = 0
      @nodes.each do |node|
        @edges[node].each do |second_node|
          @edges[second_node].each do |third_node|
            number_of_triangles += 1 if @edges[third_node].includes? node
          end
        end
      end
      number_of_triangles
    end

    def is_bipartite : Bool
      nodes = @nodes.dup
      colors = {} of NodeType => Bool
      while nodes.size > 0
        node = nodes.first
        nodes.delete node
        neighbors = get_neighbors node

        colored_neighbors = neighbors.keys.select { |neighbor| colors.keys.includes? neighbor } .to_set
        uncolored_neighbors = neighbors - colored_neighbors

        if colored_neighbors.size > 0
          next_color = !colors[colored_neighbors.first]
        else
          next_color = 0
        end
        colors[node] = next_color
        next_color = !next_color

        while uncolored_neighbors.size > 0
          neighbors = Set(NodeType).new

          return false if colored_neighbors.any? { |cn| colors[cn] != next_color }

          uncolored_neighbors.each do |un|
            node.delete un
            neighbors |= get_neighbors un
            colors[un] = next_color
          end

          next_color = !next_color

          colored_neighbors = neighbors.keys.select { |neighbor| colors.keys.includes? neighbor } .to_set
          uncolored_neighbors = neighbors - colored_neighbors
        end

        return false if colored_neighbors.any? { |cn| colors[cn] != next_color }
      end

      return true
    end
  end

  class DefaultGraph < AGraph(Int32)
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

  class RDF_Graph < AGraph(String)
    def self.from_filename(filename : String, gzipped : Bool) : RDF_Graph
      if gzipped
        file = Gzip::Reader.new(filename)
      else
        file = File.new(filename)
      end

      graph = RDF_Graph.new

      file.each_line do |line|
        line_data = line.split ' '
        node1 = line_data[0]
        node2 = line_data[2]
        graph.add_node(node1)
        graph.add_node(node2)
        graph.add_edge(node1, node2)
      end

      graph
    end
  end
end
