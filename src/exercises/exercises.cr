require "../graph/graph"

module Exercises
  extend self
  EXERCISES = ["1_1", "1_2"]

  def exercise1_1(filename : String?, gzipped : Bool)
    puts "1.1"
  end

  def exercise1_2(filename : String?, gzipped : Bool)
    puts "1.2"
  end

  def run(exercise : String?, filename : String?, gzipped : Bool)
    {% begin %}
      case exercise
      {% for e in EXERCISES %}
        when {{e}}
          exercise{{e.id}} filename, gzipped
      {% end %}
      else
        STDERR.puts "ERROR: #{exercise} is not a valid exercise."
        STDERR.puts "Valid exercises are: " + EXERCISES.join(", ")
        exit(1)
      end
    {% end %}
  end
end
