require "option_parser"
require "./exercises/exercises"

module KnowledgeGraphs
  extend self
  VERSION = "0.1.0"

  def run
    filename = nil
    exercise = nil
    gzipped = false
    n_tuples = false
    metis = false
    OptionParser.parse! do |parser|
      parser.banner = "Usage: knowledge_graphs [arguments]"
      parser.on("-e EXERCISE", "--exercise=EXERCISE", "Exercise") { |e| exercise = e }
      parser.on("-f FILENAME", "--filename=FILENAME", "Filename for Test Data") { |f| filename = f }
      parser.on("-g", "--gzipped", "FILENAME is gzipped") { gzipped = true }
      parser.on("-n", "--n-tuples") { n_tuples = true }
      parser.on("-m", "--metis") { metis = true }
      parser.on("-h", "--help", "Show this help") { puts parser }
      parser.invalid_option do |flag|
        STDERR.puts "ERROR: #{flag} is not a valid option."
        STDERR.puts parser
        exit(1)
      end
    end

    Exercises.run exercise, filename, gzipped, n_tuples, metis
  end
end

KnowledgeGraphs.run
