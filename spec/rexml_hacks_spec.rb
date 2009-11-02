require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rexml/document'
#require 'lib/rexml_hacks'

describe "REXML" do
  before do
    string = <<-EOF;
<?xml version="1.0" ?>
    <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:ex="http://example.org/" xml:lang="en" xml:base="http://example.org/">
      <rdf:Description>
        <foo>bar</foo>
        <bar:bar xmlns:bar="http://foo.com/">foo</bar:bar>
        <ex:ex>fap</ex:ex>
      </rdf:Description>
    </rdf:RDF>
    EOF
    
    @doc = REXML::Document.new(string)
    
    string2 = <<-EOF;
<?xml version="1.0" ?>
    <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:ex="http://example.org/">
      <rdf:Description>
        <foo>bar</foo>
        <bar:bar xmlns:bar="http://foo.com/">foo</bar:bar>
        <ex:ex>fap</ex:ex>
      </rdf:Description>
    </rdf:RDF>
    EOF
    @doc2 = REXML::Document.new(string2)
  end
  
  it "should have support for xml:base" do
    @doc.root.elements[1].base?.should == true
    @doc.root.elements[1].base.should == "http://example.org/"
    @doc2.root.elements[1].base?.should_not == true
    @doc2.root.elements[1].base.should == nil
  end
  
  it "should have support for xml:lang" do
    @doc.root.elements[1].lang?.should == true
    @doc.root.elements[1].lang.should == "en"
    @doc2.root.elements[1].lang?.should_not == true
    @doc2.root.elements[1].lang.should == nil
  end
  
  it "should allow individual writing-out of XML" do
#    puts @doc.root.elements[1].write
    
    sampledoc = <<-EOF;
    <?xml version="1.0"?>

    <!--
      Copyright World Wide Web Consortium, (Massachusetts Institute of
      Technology, Institut National de Recherche en Informatique et en
      Automatique, Keio University).

      All Rights Reserved.

      Please see the full Copyright clause at
      <http://www.w3.org/Consortium/Legal/copyright-software.html>

      Description: Visibly used namespaces must be included in XML
             Literal values. Treatment of namespaces that are not 
             visibly used (e.g. rdf: in this example) is implementation
             dependent. Based on example from Issues List.


      $Id: test001.rdf,v 1.2 2002/11/22 13:52:15 jcarroll Exp $

    -->
    <rdf:RDF xmlns="http://www.w3.org/1999/xhtml"
       xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
       xmlns:html="http://NoHTML.example.org"
       xmlns:my="http://my.example.org/">
       <rdf:Description rdf:ID="John_Smith">
        <my:Name rdf:parseType="Literal">
          <html:h1>
            <b>John</b>
          </html:h1>
       </my:Name>

      </rdf:Description>
    </rdf:RDF>
    EOF
    doc2 = REXML::Document.new(sampledoc)
    expectedoutput_str = "<html:h1 xmlns:html=\'http://NoHTML.example.org\' xmlns:my=\'http://my.example.org/\' xmlns:rdf=\'http://www.w3.org/1999/02/22-rdf-syntax-ns#\'>\n            <b xmlns=\'http://www.w3.org/1999/xhtml\'>John</b>\n          </html:h1>"
    expectedout = REXML::Document.new(expectedoutput_str)
    doc2.root.elements[1].elements[1].elements[1].write_reddy == expectedout.root
    
    sampledoc3 = <<-EOF;
<?xml version="1.0"?><RDF xmlns="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><Description><x:li xmlns:x="http://example.org/notRDF" /></Description></RDF>
    EOF
    
    doc3 = REXML::Document.new(sampledoc3)
    out3 = REXML::Document.new(doc3.root.elements[1].write_reddy)
    out3.root.class == REXML::Element
  end
end
