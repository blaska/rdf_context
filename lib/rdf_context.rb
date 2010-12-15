$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

begin
  require 'nokogiri'
  require 'addressable/uri'
  require 'builder'
  require 'treetop'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'nokogiri'
  gem 'addressable'
  gem 'treetop'
  require 'nokogiri'
  require 'addressable/uri'
  require 'builder'
  require 'treetop'
end

Dir.glob(File.join(File.dirname(__FILE__), 'rdf_context/*.rb')).sort.each { |f| require f }

# Include Storage types, but be tollerant of failure to load as dependencies might not be available
Dir.glob(File.join(File.dirname(__FILE__), "rdf_context/store/*.rb")).each do |f|
  begin
    require f
  rescue LoadError
    puts "Error loading #{f}: #{$!}"
  end
end

# Include Serializer types, but be tollerant of failure to load as dependencies might not be available
Dir.glob(File.join(File.dirname(__FILE__), "rdf_context/serializer/*.rb")).each do |f|
  begin
    require f
  rescue LoadError
    puts "Error loading #{f}: #{$!}"
  end
end

module RdfContext
  VERSION = File.read(File.join(File.dirname(__FILE__), "..", "VERSION")).chop  # Version in parent directory
  
  LINK_TYPES = %w(
    alternate appendix bookmark cite chapter contents copyright first glossary
    help icon index last license meta next p3pv1 prev role section stylesheet subsection
    start top up
  )

  NC_REGEXP = Regexp.new(
    %{^
      (?!\\\\u0301)             # &#x301; is a non-spacing acute accent.
                                # It is legal within an XML Name, but not as the first character.
      (  [a-zA-Z_]
       | \\\\u[0-9a-fA-F]
      )
      (  [0-9a-zA-Z_\.-]
       | \\\\u([0-9a-fA-F]{4})
      )*
    $},
    Regexp::EXTENDED)

  LITERAL_PLAIN         = /^"((?:\\"|[^"])*)"/.freeze
  LITERAL_WITH_LANGUAGE = /^"((?:\\"|[^"])*)"@([a-z]+[\-A-Za-z0-9]*)/.freeze
  LITERAL_WITH_DATATYPE = /^"((?:\\"|[^"])*)"\^\^<([^>]+)>/.freeze

  RDF_TYPE    = URIRef.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
  XML_LITERAL = Literal::Encoding.xmlliteral

  DC_NS       = Namespace.new("http://purl.org/dc/terms/", "dc")
  OWL_NS      = Namespace.new("http://www.w3.org/2002/07/owl#", "owl")
  LOG_NS      = Namespace.new("http://www.w3.org/2000/10/swap/log#", "log")
  PTR_NS      = Namespace.new("http://www.w3.org/2009/pointers#", "ptr")
  RDF_NS      = Namespace.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf")
  RDFA_NS     = Namespace.new("http://www.w3.org/ns/rdfa#", "rdfa")
  RDFS_NS     = Namespace.new("http://www.w3.org/2000/01/rdf-schema#", "rdfs")
  XHV_NS      = Namespace.new("http://www.w3.org/1999/xhtml/vocab#", "xhv")
  XML_NS      = Namespace.new("http://www.w3.org/XML/1998/namespace", "xml")
  XSD_NS      = Namespace.new("http://www.w3.org/2001/XMLSchema#", "xsd")
  XSI_NS      = Namespace.new("http://www.w3.org/2001/XMLSchema-instance", "xsi")
  WELLKNOWN_NAMESPACES = [DC_NS, OWL_NS, LOG_NS, RDF_NS, RDFA_NS, RDFS_NS, XHV_NS, XML_NS, XSD_NS, XSI_NS]

  XH_MAPPING  = {"" => Namespace.new("http://www.w3.org/1999/xhtml/vocab\#", nil)}


  # Control debug output.
  def self.debug?; @debug; end
  def self.debug=(value); @debug = value; end
end
