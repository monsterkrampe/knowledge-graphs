require "http/client"
require "../graph/graph"

module DBLP_Crawler
  extend self
  include Graph

  def get_nt_contents(url : String) : String?
    puts "Request #{url}"
    response = HTTP::Client.get url
    while response.status_code == 303 || response.status_code == 429
      if response.status_code == 429
        delay = response.headers["Retry-After"].to_i
        puts delay
        puts "go to sleep"
        sleep(delay)
        puts "wake up"
      elsif response.status_code == 303
        url = response.headers["Location"]
      end
      response = HTTP::Client.get url
    end
    puts "Response Status: #{response.status_code}"
    return nil unless response.status_code == 200
    response.body
  end

  def get_publication_graph_for_author(author : String) : DBLP_Graph
    contents = get_nt_contents("#{author.lstrip('<').rstrip('>')}.nt")
    raise Exception.new if contents.nil?
    DBLP_Graph.from_contents contents
  end

  def get_author_graph_for_publication(publication : String) : DBLP_Graph
    contents = get_nt_contents("#{publication.lstrip('<').rstrip('>')}.nt")
    raise Exception.new if contents.nil?
    DBLP_Graph.from_contents contents
  end
end
