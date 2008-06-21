require 'addressable/uri'

class URIRef
  attr_accessor :uri
  def initialize (string)
    self.test_string(string)
    if Addressable.nil?
      @uri = URI.parse(string)
    else
      @uri = Addressable::URI.parse(string)
    end
    if @uri.relative?
      raise "URI must not be relative <" + @uri.to_s + ">"
    end
    if !@uri.to_s.match(/^javascript/).nil?
      raise "Javascript pseudo-URIs are not acceptable"
    end
  end
  
  def to_s
    @uri.to_s
  end
  
  def to_ntriples
    "<" + @uri.to_s + ">"
  end
  
  def test_string (string)
    string.each_byte do |b|
      if b >= 0 and b <= 31
        raise "URI must not contain control characters"
      end
    end
  end
end