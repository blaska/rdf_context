require File.join(File.dirname(__FILE__), 'spec_helper')

# Specification: http://www.w3.org/TR/rdfa-syntax/
# docs:
# - http://www.xml.com/pub/a/2007/02/14/introducing-rdfa.html
# - http://www.w3.org/TR/xhtml-rdfa-primer/
# W3C test suite: http://www.w3.org/2006/07/SWD/RDFa/testsuite/xhtml1-testcases/

describe "RDFa parser" do
  it "should be able to pass xhtml1-0001.xhtml" do
    sampledoc = <<-EOF;
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.0//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml"
          xmlns:dc="http://purl.org/dc/elements/1.1/">
    <head>
    	<title>Test 0001</title>
    </head>
    <body>
    	<p>This photo was taken by <span class="author" about="photo1.jpg" property="dc:creator">Mark Birbeck</span>.</p>
    </body>
    </html>
    EOF
    
    parser = RdfaParser.new(sampledoc, uri = "http://www.w3.org/2006/07/SWD/RDFa/testsuite/xhtml1-testcases/0001.xhtml")
    parser.graph.size.should == 1
  end

  # W3C Test suite from http://www.w3.org/2006/07/SWD/RDFa/testsuite/
  describe "w3c xhtml1 testcases" do
    require 'rdfa_helper'
    include RdfaHelper
    
    def self.test_cases
      RdfaHelper::TestCase.test_cases
    end

    test_cases.each do |t|
      specify "test #{t.name}: #{t.title}" do
        rdfa_string = File.read(t.informationResourceInput)
        rdfa_parser = RdfaParser.new(rdfa_string, t.about.uri.to_s)

        nt_string = t.informationResourceResults ? File.read(t.informationResourceResults) : ""
        # Triples are valid N3 documents
        nt_parser = N3Parser.new(nt_string)

        rdfa_parser.graph.should be_equivalent_graph(nt_parser.graph, t.information)
      end
    end
  end
end