module ClassyEnum
  class SubclassNameError < Exception; end

  class Base
    include Comparable
    include Conversion
    include Predicate

    extend Collection

    class_attribute :base_class
    attr_accessor :owner, :serialize_as_json

    class << self
      def inherited(klass)
        if self == ClassyEnum::Base
          klass.base_class = klass
        else

          # Ensure subclasses follow expected naming conventions
          unless klass.name.start_with? base_class.name
            raise SubclassNameError, "subclass name must start with #{base_class.name}"
          end

          # Add visit_EnumMember methods to support validates_uniqueness_of with enum field
          Arel::Visitors::ToSql.class_eval do
            define_method "visit_#{klass.name}", lambda {|value| quote(value.to_s) }
          end

          # Convert from MyEnumClassNumberTwo to :number_two
          enum = klass.name.gsub(klass.base_class.name, '').underscore.to_sym

          Predicate.define_predicate_method(klass, enum)

          klass.instance_variable_set('@option', enum)
        end

        super
      end

      # Build a new ClassyEnum child instance
      #
      # ==== Example
      #  # Create an Enum with some elements
      #  class Priority < ClassyEnum::Base
      #  end
      #
      #  class PriorityLow < Priority
      #  end
      #
      #  Priority.build(:low) # => PriorityLow.new
      def build(value, options={})
        return value if value.blank?

        # Return a TypeError if the build value is not a valid member
        unless all.map(&:to_sym).include? value.to_sym
          return TypeError.new("#{base_class} #{invalid_message}")
        end

        object = ("#{base_class}#{value.to_s.camelize}").constantize.new
        object.owner = options[:owner]
        object.serialize_as_json = options[:serialize_as_json]
        object
      end

      # Returns a a message indicating which fields are valid
      def invalid_message
        "must be one of #{all.join(', ')}"
      end

      # DSL setter method for reference to enum owner
      def owner(owner)
        define_method owner, lambda { @owner }
      end
    end

    # Sort an array of elements based on the order they are defined
    #
    # ==== Example
    #  # Create an Enum with some elements
    #  class Priority < ClassyEnum::Base
    #  end
    #
    # class PriorityLow < Priority; end
    # class PriorityMedium < Priority; end
    # class PriorityHigh < Priority; end
    #
    #  @low = Priority.build(:low)
    #  @medium = Priority.build(:medium)
    #  @high = Priority.build(:high)
    #  priorities = [@low, @high, @medium]
    #  priorities.sort # => [@low, @medium, @high]
    #  priorities.max # => @high
    #  priorities.min # => @low
    def <=> other
      index <=> other.index
    end
  end
end
