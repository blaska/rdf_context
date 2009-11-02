require 'rubygems'
require 'addressable/uri'
require 'net/http'

module Reddy
  class URIRef
    attr_accessor :uri
    def initialize (string)
      self.test_string(string)
      @uri = Addressable::URI.parse(string)
      if @uri.relative?
        raise UriRelativeException, "<" + @uri.to_s + ">"
      end
      if !@uri.to_s.match(/^javascript/).nil?
        raise "Javascript pseudo-URIs are not acceptable"
      end
    end
    
    def + (input)
      if input.class == String
        input_uri = Addressable::URI.parse(input)
      else
        input_uri = Addressable::URI.parse(input.to_s)
      end
      return URIRef.new((@uri + input_uri).to_s)
    end
    
    def short_name
      if @uri.fragment()
        return @uri.fragment()
      elsif @uri.path.split("/").last.class == String and @uri.path.split("/").last.length > 0
        return @uri.path.split("/").last
      else
        return false
      end
    end
  
    def == (other)
      return true if @uri == other.uri
    end
  
    def to_s
      @uri.to_s
    end
  
    def to_ntriples
      "<" + @uri.to_s + ">"
    end
  
    def test_string (string)
      string.to_s.each_byte do |b|
        if b >= 0 and b <= 31
          raise "URI must not contain control characters"
        end
      end
    end

    def load_graph
      get = Net::HTTP.start(@uri.host, @uri.port) {|http| [:xml, http.get(@uri.path)] }
      return Reddy::RdfXmlParser.new(get[1].body, @uri.to_s).graph if get[0] == :xml
    end
  end
end
