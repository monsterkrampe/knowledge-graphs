require "./spec_helper"

module Exercise0Helper
  extend self
  def expected_output_string(max_out_degree, max_out_array, min_in_degree, min_in_array)
    "Nodes with max out degree (#{max_out_degree}): #{max_out_array}\nNodes with min in degree (#{min_in_degree}): #{min_in_array}"
  end
end


describe Exercises do
  describe "exercise0" do
    it "works for testfile 01" do
      graph = Exercises.create_graph("./test-data/01-triangle.txt")
      Exercises.exercise0(graph).should \
        eq Exercise0Helper.expected_output_string(1, [0, 1, 2], 1, [0, 1, 2])
    end
    it "works for testfile 02" do
      graph = Exercises.create_graph("./test-data/02-empty.txt")
      Exercises.exercise0(graph).should \
        eq Exercise0Helper.expected_output_string(0, [0, 1, 2], 0, [0, 1, 2])
    end
    it "works for testfile 03" do
      graph = Exercises.create_graph("./test-data/03-k5.txt")
      Exercises.exercise0(graph).should \
        eq Exercise0Helper.expected_output_string(4, [0, 1, 2, 3, 4], 4, [0, 1, 2, 3, 4])
    end
    it "works for testfile 04" do
      graph = Exercises.create_graph("./test-data/04-s5.txt")
      Exercises.exercise0(graph).should \
        eq Exercise0Helper.expected_output_string(4, [0], 0, [0])
    end
    it "works for testfile 05" do
      graph = Exercises.create_graph("./test-data/05-random-small.txt")
      Exercises.exercise0(graph).should \
        eq Exercise0Helper.expected_output_string(4, [9], 1, [0, 2, 4, 7, 9])
    end
    it "works for testfile 06" do
      graph = Exercises.create_graph("./test-data/06-random-medium.txt")
      Exercises.exercise0(graph).should \
        eq Exercise0Helper.expected_output_string(15, [770], 0, [129, 157, 531, 912, 951])
    end
    it "works for testfile 07" do
      graph = Exercises.create_graph("./test-data/07-random-big.txt")
      Exercises.exercise0(graph).should \
        eq Exercise0Helper.expected_output_string(20, [6338], 0, [527, 2087, 3203, 3503, 3564, 7191, 8200, 8958])
    end
  end

  describe "exercise1_2" do
    it "works for testfile 01" do
      graph = Exercises.create_graph("./test-data/01-triangle.txt")
      Exercises.exercise1_2(graph).should eq File.read "./spec/test-data/01-metis.txt"
    end
    it "works for testfile 02" do
      graph = Exercises.create_graph("./test-data/02-empty.txt")
      Exercises.exercise1_2(graph).should eq File.read "./spec/test-data/02-metis.txt"
    end
    it "works for testfile 03" do
      graph = Exercises.create_graph("./test-data/03-k5.txt")
      Exercises.exercise1_2(graph).should eq File.read "./spec/test-data/03-metis.txt"
    end
    it "works for testfile 04" do
      graph = Exercises.create_graph("./test-data/04-s5.txt")
      Exercises.exercise1_2(graph).should eq File.read "./spec/test-data/04-metis.txt"
    end
    it "works for testfile 05" do
      graph = Exercises.create_graph("./test-data/05-random-small.txt")
      Exercises.exercise1_2(graph).should eq File.read "./spec/test-data/05-metis.txt"
    end
    it "works for testfile 06" do
      graph = Exercises.create_graph("./test-data/06-random-medium.txt")
      Exercises.exercise1_2(graph).should eq File.read "./spec/test-data/06-metis.txt"
    end
    it "works for testfile 07" do
      graph = Exercises.create_graph("./test-data/07-random-big.txt")
      Exercises.exercise1_2(graph).should eq File.read "./spec/test-data/07-metis.txt"
    end
  end

  describe "exercise1_3" do
    it "works for testfile 01" do
      graph = Exercises.create_graph("./test-data/01-triangle.txt")
      Exercises.exercise1_3(graph).should eq 3
    end
    it "works for testfile 02" do
      graph = Exercises.create_graph("./test-data/02-empty.txt")
      Exercises.exercise1_3(graph).should eq 0
    end
    it "works for testfile 03" do
      graph = Exercises.create_graph("./test-data/03-k5.txt")
      Exercises.exercise1_3(graph).should eq 60
    end
    it "works for testfile 04" do
      graph = Exercises.create_graph("./test-data/04-s5.txt")
      Exercises.exercise1_3(graph).should eq 0
    end
    it "works for testfile 05" do
      graph = Exercises.create_graph("./test-data/05-random-small.txt")
      Exercises.exercise1_3(graph).should eq 9
    end
    it "works for testfile 06" do
      graph = Exercises.create_graph("./test-data/06-random-medium.txt")
      Exercises.exercise1_3(graph).should eq 90
    end
    it "works for testfile 07" do
      graph = Exercises.create_graph("./test-data/07-random-big.txt")
      Exercises.exercise1_3(graph).should eq 426
    end
  end

  describe "exercise2_2" do
    it "works for testfile 01" do
      graph = Exercises.create_graph("./test-data/01-triangle.txt")
      Exercises.exercise2_2(graph).should eq false
    end
    it "works for testfile 02" do
      graph = Exercises.create_graph("./test-data/02-empty.txt")
      Exercises.exercise2_2(graph).should eq true
    end
    it "works for testfile 03" do
      graph = Exercises.create_graph("./test-data/03-k5.txt")
      Exercises.exercise2_2(graph).should eq false
    end
    it "works for testfile 04" do
      graph = Exercises.create_graph("./test-data/04-s5.txt")
      Exercises.exercise2_2(graph).should eq true
    end
    it "works for testfile 05" do
      graph = Exercises.create_graph("./test-data/05-random-small.txt")
      Exercises.exercise2_2(graph).should eq false
    end
    it "works for testfile 06" do
      graph = Exercises.create_graph("./test-data/06-random-medium.txt")
      Exercises.exercise2_2(graph).should eq false
    end
    it "works for testfile 07" do
      graph = Exercises.create_graph("./test-data/07-random-big.txt")
      Exercises.exercise2_2(graph).should eq false
    end
    it "works for authors (snippet)" do
      graph = Exercises.create_graph("./test-data/dblp/authorship-snippet.nt.gz", true, true)
      Exercises.exercise2_2(graph).should eq true
    end
    it "works for authors" do
      graph = Exercises.create_graph("./test-data/dblp/authorship.nt.gz", true, true)
      Exercises.exercise2_2(graph).should eq true
    end
    it "works for coauthors" do
      graph = Exercises.create_graph("./test-data/dblp/coauthors.nt.gz", true, true)
      Exercises.exercise2_2(graph).should eq false
    end
  end

  describe "exercise2_3" do
    it "works for authors (snippet)" do
      graph = Exercises.create_graph("./test-data/dblp/authorship-snippet.nt.gz", true, true)
      # number of edges in subgraph
      Exercises.exercise2_3(graph).should eq 414
    end
    it "works for coauthors" do
      graph = Exercises.create_graph("./test-data/dblp/coauthors.nt.gz", true, true)
      # number of edges in subgraph
      Exercises.exercise2_3(graph).should eq 20810017
    end
  end
end
