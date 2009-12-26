module Reddy
  # Abstract storage module, superclass of other storage classes
  class AbstractStore
    attr_reader :nsbinding, :identifier
    attr_reader :named_nodes
    
    def initialize(identifier = nil, configuration = {})
      @nsbinding = {}
      # Reverse namespace binding
      @prefix = {}
      
      # For BNode identifier generation
      @next_generated = "a"
      @named_nodes = {}
      
      @identifier = identifier || BNode.new(self)
    end
    
    # Interfaces that must be implemented
#    def triples(triple, context = nil); raise StoreException, "not implemented"; end
#    def add(triple, context = nil, quoted = false); raise StoreException, "not implemented"; end
#    def remove(triple, context = nil); raise StoreException, "not implemented"; end
    
    # Default (sub-optimal) implemenations of interfaces
    def inspect
      "#{self.class}[id=#{identifier}]"
    end

    # Bind namespace to store, returns bound namespace
    def bind(namespace)
      @prefix[namespace.uri.to_s] = namespace.prefix
      @nsbinding[namespace.prefix] ||= namespace
    end

    # Namespace for prefix
    def namespace(prefix)
      @nsbinding[prefix]
    end
    
    def generate_bn_identifier
      bn = @next_generated
      @next_generated = @next_generated.succ
      bn
    end

    # Prefix for namespace
    def prefix(namespace)
      namespace.is_a?(Namespace) ? @prefix[namespace.uri.to_s] : @prefix[namespace]
    end
    
    # Get all BNodes with usage count used within graph
    def bnodes(context = nil)
      bn = {}
      triples(Triple.new(nil, nil, nil), context) do |t|
        if t.subject.is_a?(BNode)
          bn[t.subject] ||= 0
          bn[t.subject] += 1
        end
        if t.object.is_a?(BNode)
          bn[t.object] ||= 0
          bn[t.object] += 1
        end
      end
      bn
    end

    def size(context = nil); triples(Triple.new(nil, nil, nil), context).size; end
    def subjects(context = nil); triples(Triple.new(nil, nil, nil), context).map {|t| t.subject}.uniq; end
    def predicates(context = nil); triples(Triple.new(nil, nil, nil), context).map {|t| t.predicate}.uniq; end
    def objects(context = nil); triples(Triple.new(nil, nil, nil), context).map {|t| t.object}.uniq; end
    def item(item, context = nil) triples(Triple.new(nil, nil, nil), context)[item]; end
    def contains?(triple, context = nil); !triples(triple, context).empty?; end
    def self.context_aware?; false; end
    def self.formula_aware?; false; end
  end
end