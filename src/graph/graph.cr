module Graph
  abstract class AGraph(NodeType)
    def initialize
      @nodes = Set(NodeType).new
      @edges = {} of NodeType => Set(NodeType)
    end
  end
end
