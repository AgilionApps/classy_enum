require "classy_enum/classy_enum_attributes"
require 'classy_enum/classy_enum_formtastic_input' if Object.const_defined? 'Formtastic'

class ClassyEnumValue < Object 

  attr_reader :to_s, :to_sym, :index, :base_class

  def initialize(base_class, option, index)
    @to_s = option.to_s.downcase
    @to_sym = @to_s.to_sym
    @index = index + 1
    @base_class = base_class
  end
  
  def name
    to_s.titleize
  end
  
  def <=> other
    @index <=> other.index
  end

end

module ClassyEnum
    
  module SuperClassMethods
      
    def new(option)
      self::OPTION_HASH[option] || TypeError.new("Valid #{self} options are #{self.valid_options}")
    end
    
    def all
      self::OPTIONS.map {|e| self.new(e) }
    end
    
    # Uses the name field for select options
    def all_with_name
      self.all.map {|e| [e.name, e.to_s] }
    end
    
    def valid_options
      self::OPTIONS.map(&:to_s).join(', ')
    end
    
    # Alias of new
    def find(option)
      new(option)
    end
  
  end
  
  def self.included(other)
    other.extend SuperClassMethods
    
    other.const_set("OPTION_HASH", Hash.new)

    other::OPTIONS.each do |option|

      klass = Class.new(ClassyEnumValue) do
        include other::InstanceMethods if other.const_defined?("InstanceMethods")
        extend other::ClassMethods if other.const_defined?("ClassMethods")
      end

      Object.const_set("#{other}#{option.to_s.camelize}", klass)
    
      instance = klass.new(other, option, other::OPTIONS.index(option))
      
      other::OPTION_HASH[option] = other::OPTION_HASH[option.to_s.downcase] = instance
      
      ClassyEnum.const_set(option.to_s.upcase, instance) unless ClassyEnum.const_defined?(option.to_s.upcase)
    end

  end
  
end


