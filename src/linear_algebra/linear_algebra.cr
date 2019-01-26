module Linear_Algebra
  class Vector(T)
    def initialize(@array : Array(T))
    end

    def +(other : T)
      @array.each_index { |i| @array[i] += other }
      self
    end

    def *(other : T)
      @array.each_index { |i| @array[i] *= other }
      self
    end

    def map(&block : T -> _)
      @array.map(&block)
    end

    def sort_by!(&block : T -> _)
      @array.sort_by!(&block)
    end

    delegate to_s, to: @array
    forward_missing_to @array
  end

  abstract class Matrix
    abstract def *(other : Vector)
  end

  class SparseMatrix < Matrix
    def initialize(graph : Graph::AGraph)
      @transposed = false
      @graph = graph
    end

    def [](r, c)
      c, r = r, c if @transposed
      @graph.edges[r].includes?(c) ? (1_f64 / @graph.edges[r].size.to_f64) : 0_f64
    end

    def *(v : Vector)
      raise ArgumentError.new if @graph.number_of_nodes != v.size

      result = Array(Float64).new
      @graph.number_of_nodes.times do |i|
        sum = 0_f64
        @graph.number_of_nodes.times do |j|
          sum += self[i, j] * v[j]
        end
        result << sum
      end

      Vector.new(result)
    end

    def transpose
      @transposed = !@transposed
      self
    end

    def to_s(io : IO)
      @graph.number_of_nodes.times do |i|
        io << '['
        @graph.number_of_nodes.times do |j|
          io << self[i, j]
          io << ", "
        end
        io << ']'
        io << '\n'
      end
    end
  end
end
