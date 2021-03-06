autoload :YAML, "yaml"
autoload :CGI, 'cgi'

RDFA_DIR = File.join(File.dirname(__FILE__), 'rdfa-test-suite')
RDFA_MANIFEST_URL = "http://rdfa.digitalbazaar.com/test-suite/"
RDFA_TEST_CASE_URL = "#{RDFA_MANIFEST_URL}test-cases/"

module RdfaHelper
  # Class representing test cases in format http://www.w3.org/2006/03/test-description#
  class TestCase
    HTMLRE = Regexp.new('([0-9]{4,4})\.xhtml')
    TCPATHRE = Regexp.compile('\$TCPATH')
    
    include RdfContext
    
    attr_accessor :about
    attr_accessor :name
    attr_accessor :contributor
    attr_accessor :title
    attr_accessor :informationResourceInput
    attr_accessor :informationResourceResults
    attr_accessor :purpose
    attr_accessor :reviewStatus
    attr_accessor :classification
    attr_accessor :suite
    attr_accessor :specificationReference
    attr_accessor :expectedResults
    attr_accessor :parser
    
    @@suite = ""
    
    def initialize(statements, suite)
      self.suite = suite
      self.expectedResults = true
      statements.each do |statement|
        next if statement.subject.is_a?(BNode)
        #next unless statement.subject.uri.to_s.match(/0001/)
        unless self.about
          self.about = statement.subject.uri.to_s
          self.name = statement.subject.short_name || self.about
        end
        
        if statement.predicate.short_name == "expectedResults"
          self.expectedResults = statement.object.contents == "true"
          #puts "expectedResults = #{statement.object.literal.value}"
        elsif self.respond_to?("#{statement.predicate.short_name}=")
          self.send("#{statement.predicate.short_name}=", statement.object.to_s)
          #puts "#{statement.predicate.uri.short_name} = #{s.to_s}"
        end
      end
    end
    
    def inspect
      "[Test Case " + %w(
        about
        name
        contributor
        title
        informationResourceInput
        informationResourceResults
        purpose
        reviewStatus
        classification
        specificationReference
        expectedResults
      ).map {|a| v = self.send(a); "#{a}='#{v}'" if v}.compact.join(", ") +
      "]"
    end
    
    def status
      reviewStatus.to_s.split("#").last
    end
    
    def compare; :graph; end
    
    def information
      %w(purpose specificationReference).map {|a| v = self.send(a); "#{a}: #{v}" if v}.compact.join("\n")
    end
    
    def tcpath
      RDFA_TEST_CASE_URL + (suite == "xhtml" ? "xhtml1" : suite)
    end
    
    # Read in file, and apply modifications to create a properly formatted HTML
    def input
      f = self.inputDocument
      found_head = false
      namespaces = ""
      body = File.readlines(File.join(RDFA_DIR, "tests", f)).map do |line|
        found_head ||= line.match(/<head/)
        if found_head
          line.chop
        else
          found_head ||= line.match(%r(http://www.w3.org/2000/svg))
          namespaces << line
          nil
        end
      end.compact.join("\n")

      namespaces.chop!  # Remove trailing newline
      
      case suite
      when "xhtml"
        head = "" +
        %(<?xml version="1.0" encoding="UTF-8"?>\n) +
        %(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.1//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-2.dtd">\n) +
        %(<html xmlns="http://www.w3.org/1999/xhtml"\n)
        head + "#{namespaces}>\n#{body.gsub(TCPATHRE, tcpath)}\n</html>"
      when "html4"
        head ="" +
        %(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/MarkUp/DTD/html401-rdfa11-1.dtd">\n) +
        %(<html\n)
        head + "#{namespaces}>\n#{body.gsub(TCPATHRE, tcpath).gsub(HTMLRE, '\1.html')}\n</html>"
      when "html5"
        head = "<!DOCTYPE html>\n"
        head += namespaces.empty? ? %(<html>) : "<html\n#{namespaces}>"
        head + "\n#{body.gsub(TCPATHRE, tcpath).gsub(HTMLRE, '\1.html')}\n</html>"
      when "svgtiny"
        head = "" +
        %(<?xml version="1.0" encoding="UTF-8"?>\n)
        head += namespaces.empty? ? %(<svg>) : "<svg\n#{namespaces}>"
        head + "\n#{body.gsub(TCPATHRE, tcpath).gsub(HTMLRE, '\1.svg')}\n</svg>"
      else
        nil
      end
    end
    
    # Read in file, and apply modifications reference either .html or .xhtml
    def results
      f = self.name + ".sparql"
      body = File.read(File.join(RDFA_DIR, "tests", f)).gsub(TCPATHRE, tcpath)
      
      case suite
      when /xhtml/  then body
      when /svg/    then body.gsub(HTMLRE, '\1.svg')
      else               body.gsub(HTMLRE, '\1.html')
      end
    end
    
    def inputDocument; self.name + ".txt"; end
    def outputDocument; self.name + ".sparql"; end

    def version
      :rdfa_1_1
    end
    
    # Run test case, yields input for parser to create triples
    def run_test
      rdfa_string = input
      
      # Run
      @parser = RdfaParser::RdfaParser.new(:graph => Graph.new(:identifier => about))
      yield(rdfa_string, @parser)

      query_string = results

      if $redland_enabled
        # Run SPARQL query
        @parser.graph.should pass_query(query_string, self)
      else
        raise SparqlException, "Query skipped, Redland not installed"
      end

      @parser.graph.to_rdfxml.should be_valid_xml
    end
    
    def trace
      @parser.debug.to_a.join("\n")
    end
    
    def self.test_cases(suite)
      @test_cases = [] unless @suite == suite
      return @test_cases unless @test_cases.empty?
      
      @suite = suite # Process the given test suite
      @manifest_url = "#{RDFA_MANIFEST_URL}#{suite}-manifest.rdf"
      
      manifest_file = File.join(RDFA_DIR, "#{suite}-manifest.rdf")
      yaml_file = File.join(File.dirname(__FILE__), "#{suite}-manifest.yml")

      @test_cases = unless File.file?(yaml_file)
        t = Time.now
        puts "parse #{manifest_file} @#{Time.now}"
        parser = RdfXmlParser.new

        begin
          parser.parse(File.open(manifest_file), @manifest_url)
        rescue
          raise "Parse error: #{$!}\n\t#{parser.debug.to_a.join("\t\n")}\n\n"
        end
        graph = parser.graph
        diff = Time.now - t
        puts "parsed #{graph.size} statements in #{diff} seconds (#{(graph.size / diff).to_i} statements/sec) @#{Time.now}"

        # Group by subject
        test_hash = graph.triples.inject({}) do |hash, st|
          a = hash[st.subject] ||= []
          a << st
          hash
        end
        
        test_hash.values.map {|statements| TestCase.new(statements, suite)}.
          compact.
          sort_by{|t| t.name }
      else
        # Read tests from Manifest.yml
        self.from_yaml(yaml_file)
      end
    end
    
    def self.to_yaml(suite, file)
      test_cases = self.test_cases(suite)
      puts "write test cases to #{file}"
      File.open(file, 'w') do |out|
        YAML.dump(test_cases, out )
      end
    end
    
    def self.from_yaml(file)
      YAML::add_private_type("RdfaHelper::TestCase") do |type, val|
        TestCase.new( val )
      end
      File.open(file, 'r') do |input|
        @test_cases = YAML.load(input)
      end
    end
  end
end

module OpenURI
  #alias_method :open_uri_orig, :open_uri
  def self.open_uri(uri)
    uri = Addressable::URI.parse(uri).normalize.to_s
    case uri
    when %r(http://rdfa.digitalbazaar.com/test-suite/profiles/(.*)$)
      file = File.join(File.expand_path(File.dirname(__FILE__)), 'rdfa-test-suite', 'profiles', $1)
      #puts "file: #{file}"
      File.open(file)
    when %r(http://rdfa.digitalbazaar.com/test-suite/test-cases/\w+)
      file = uri.to_s.sub(%r(http://rdfa.digitalbazaar.com/test-suite/test-cases/\w+),
        File.join(File.expand_path(File.dirname(__FILE__)), 'rdfa-test-suite', 'tests'))
      #puts "file: #{file}"
      File.open(file)
    when "http://www.w3.org/1999/xhtml/vocab"
      file = File.join(File.expand_path(File.dirname(__FILE__)), 'rdfa-test-suite', 'profile', "xhv")
      File.open(file)
    when "http://www.w3.org/2005/10/profile"
      "PROFILE"
    end
  end
end


