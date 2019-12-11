# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"

module ActiveRecord
  # == Single table inheritance
  #
  # Active Record allows inheritance by storing the name of the class in a column that by
  # default is named "type" (can be changed by overwriting <tt>Base.inheritance_column</tt>).
  # This means that an inheritance looking like this:
  #
  #   class Company < ActiveRecord::Base; end
  #   class Firm < Company; end
  #   class Client < Company; end
  #   class PriorityClient < Client; end
  #
  # When you do <tt>Firm.create(name: "37signals")</tt>, this record will be saved in
  # the companies table with type = "Firm". You can then fetch this row again using
  # <tt>Company.where(name: '37signals').first</tt> and it will return a Firm object.
  #
  # Be aware that because the type column is an attribute on the record every new
  # subclass will instantly be marked as dirty and the type column will be included
  # in the list of changed attributes on the record. This is different from non
  # Single Table Inheritance(STI) classes:
  #
  #   Company.new.changed? # => false
  #   Firm.new.changed?    # => true
  #   Firm.new.changes     # => {"type"=>["","Firm"]}
  #
  # If you don't have a type column defined in your table, single-table inheritance won't
  # be triggered. In that case, it'll work just like normal subclasses with no special magic
  # for differentiating between them or reloading the right type with find.
  #
  # Note, all the attributes for all the cases are kept in the same table. Read more:
  # https://www.martinfowler.com/eaaCatalog/singleTableInheritance.html
  #
  module Inheritance
    extend ActiveSupport::Concern

    included do
      # Determines whether to store the full constant name including namespace when using STI.
      # This is true, by default.
      class_attribute :store_full_sti_class, instance_writer: false, default: true
    end

    module ClassMethods
      # Determines if one of the attributes passed in is the inheritance column,
      # and if the inheritance column is attr accessible, it initializes an
      # instance of the given subclass instead of the base class.
      def new(attributes = nil, &block)
        if abstract_class? || self == Base
          raise NotImplementedError, "#{self} is an abstract class and cannot be instantiated."
        end

        if has_attribute?(inheritance_column)
          subclass = subclass_from_attributes(attributes)

          if subclass.nil? && scope_attributes = current_scope&.scope_for_create
            subclass = subclass_from_attributes(scope_attributes)
          end

          if subclass.nil? && base_class?
            subclass = subclass_from_attributes(column_defaults)
          end
        end

        if subclass && subclass != self
          subclass.new(attributes, &block)
        else
          super
        end
      end

      # Returns +true+ if this does not need STI type condition. Returns
      # +false+ if STI type condition needs to be applied.
      def descends_from_active_record?
        if self == Base
          false
        elsif superclass.abstract_class?
          superclass.descends_from_active_record?
        else
          superclass == Base || !columns_hash.include?(inheritance_column)
        end
      end

      def finder_needs_type_condition? #:nodoc:
        # This is like this because benchmarking justifies the strange :false stuff
        :true == (@finder_needs_type_condition ||= descends_from_active_record? ? :false : :true)
      end

      # Returns the class descending directly from ActiveRecord::Base, or
      # an abstract class, if any, in the inheritance hierarchy.
      #
      # If A extends ActiveRecord::Base, A.base_class will return A. If B descends from A
      # through some arbitrarily deep hierarchy, B.base_class will return A.
      #
      # If B < A and C < B and if A is an abstract_class then both B.base_class
      # and C.base_class would return B as the answer since A is an abstract_class.
      def base_class
        unless self < Base
          raise ActiveRecordError, "#{name} doesn't belong in a hierarchy descending from ActiveRecord"
        end

        if superclass == Base || superclass.abstract_class?
          self
        else
          superclass.base_class
        end
      end

      # Returns whether the class is a base class.
      # See #base_class for more information.
      def base_class?
        base_class == self
      end

      # Set this to +true+ if this is an abstract class (see
      # <tt>abstract_class?</tt>).
      # If you are using inheritance with Active Record and don't want a class
      # to be considered as part of the STI hierarchy, you must set this to
      # true.
      # +ApplicationRecord+, for example, is generated as an abstract class.
      #
      # Consider the following default behaviour:
      #
      #   Shape = Class.new(ActiveRecord::Base)
      #   Polygon = Class.new(Shape)
      #   Square = Class.new(Polygon)
      #
      #   Shape.table_name   # => "shapes"
      #   Polygon.table_name # => "shapes"
      #   Square.table_name  # => "shapes"
      #   Shape.create!      # => #<Shape id: 1, type: nil>
      #   Polygon.create!    # => #<Polygon id: 2, type: "Polygon">
      #   Square.create!     # => #<Square id: 3, type: "Square">
      #
      # However, when using <tt>abstract_class</tt>, +Shape+ is omitted from
      # the hierarchy:
      #
      #   class Shape < ActiveRecord::Base
      #     self.abstract_class = true
      #   end
      #   Polygon = Class.new(Shape)
      #   Square = Class.new(Polygon)
      #
      #   Shape.table_name   # => nil
      #   Polygon.table_name # => "polygons"
      #   Square.table_name  # => "polygons"
      #   Shape.create!      # => NotImplementedError: Shape is an abstract class and cannot be instantiated.
      #   Polygon.create!    # => #<Polygon id: 1, type: nil>
      #   Square.create!     # => #<Square id: 2, type: "Square">
      #
      # Note that in the above example, to disallow the creation of a plain
      # +Polygon+, you should use <tt>validates :type, presence: true</tt>,
      # instead of setting it as an abstract class. This way, +Polygon+ will
      # stay in the hierarchy, and Active Record will continue to correctly
      # derive the table name.
      attr_accessor :abstract_class

      # Returns whether this class is an abstract class or not.
      def abstract_class?
        defined?(@abstract_class) && @abstract_class == true
      end

      def sti_name
        store_full_sti_class ? name : name.demodulize
      end

      def polymorphic_name
        base_class.name
      end

      def inherited(subclass)
        subclass.instance_variable_set(:@_type_candidates_cache, Concurrent::Map.new)
        super
      end

      protected

        # Returns the class type of the record using the current module as a prefix. So descendants of
        # MyApp::Business::Account would appear as MyApp::Business::AccountSubclass.
        def compute_type(type_name)
          if type_name.start_with?("::")
            # If the type is prefixed with a scope operator then we assume that
            # the type_name is an absolute reference.
            ActiveSupport::Dependencies.constantize(type_name)
          else
            type_candidate = @_type_candidates_cache[type_name]
            if type_candidate && type_constant = ActiveSupport::Dependencies.safe_constantize(type_candidate)
              return type_constant
            end

            # Build a list of candidates to search for
            candidates = []
            name.scan(/::|$/) { candidates.unshift "#{$`}::#{type_name}" }
            candidates << type_name

            candidates.each do |candidate|
              constant = ActiveSupport::Dependencies.safe_constantize(candidate)
              if candidate == constant.to_s
                @_type_candidates_cache[type_name] = candidate
                return constant
              end
            end

            raise NameError.new("uninitialized constant #{candidates.first}", candidates.first)
          end
        end

      private

        # Called by +instantiate+ to decide which class to use for a new
        # record instance. For single-table inheritance, we check the record
        # for a +type+ column and return the corresponding class.
        def discriminate_class_for_record(record)
          if using_single_table_inheritance?(record)
            find_sti_class(record[inheritance_column])
          else
            super
          end
        end

        def using_single_table_inheritance?(record)
          record[inheritance_column].present? && has_attribute?(inheritance_column)
        end

        def find_sti_class(type_name)
          type_name = base_class.type_for_attribute(inheritance_column).cast(type_name)
          subclass = begin
            if store_full_sti_class
              ActiveSupport::Dependencies.constantize(type_name)
            else
              compute_type(type_name)
            end
          rescue NameError
            raise SubclassNotFound,
              "The single-table inheritance mechanism failed to locate the subclass: '#{type_name}'. " \
              "This error is raised because the column '#{inheritance_column}' is reserved for storing the class in case of inheritance. " \
              "Please rename this column if you didn't intend it to be used for storing the inheritance class " \
              "or overwrite #{name}.inheritance_column to use another column for that information."
          end
          unless subclass == self || descendants.include?(subclass)
            raise SubclassNotFound, "Invalid single-table inheritance type: #{subclass.name} is not a subclass of #{name}"
          end
          subclass
        end

        def type_condition(table = arel_table)
          sti_column = arel_attribute(inheritance_column, table)
          sti_names  = ([self] + descendants).map(&:sti_name)

          predicate_builder.build(sti_column, sti_names)
        end

        # Detect the subclass from the inheritance column of attrs. If the inheritance column value
        # is not self or a valid subclass, raises ActiveRecord::SubclassNotFound
        def subclass_from_attributes(attrs)
          attrs = attrs.to_h if attrs.respond_to?(:permitted?)
          if attrs.is_a?(Hash)
            subclass_name = attrs[inheritance_column] || attrs[inheritance_column.to_sym]

            if subclass_name.present?
              find_sti_class(subclass_name)
            end
          end
        end
    end

    def initialize_dup(other)
      super
      ensure_proper_type
    end

    private

      def initialize_internals_callback
        super
        ensure_proper_type
      end

      # Sets the attribute used for single table inheritance to this class name if this is not the
      # ActiveRecord::Base descendant.
      # Considering the hierarchy Reply < Message < ActiveRecord::Base, this makes it possible to
      # do Reply.new without having to set <tt>Reply[Reply.inheritance_column] = "Reply"</tt> yourself.
      # No such attribute would be set for objects of the Message class in that example.
      def ensure_proper_type
        klass = self.class
        if klass.finder_needs_type_condition?
          _write_attribute(klass.inheritance_column, klass.sti_name)
        end
      end
  end
end
