require 'active_model'

require_relative '../error'
require_relative '../primary_key'

require_relative 'dsl'
require_relative 'query'
require_relative 'persistence'
require_relative 'attributes'

module Mara
  module Model
    class PrimaryKeyError <  Mara::Error; end

    ##
    # The base class for a  Mara Model
    #
    # @example A basic Person class.
    #   class Person <  Mara::Model::Base
    #     # Set the Partition Key & Sort Key names.
    #     primary_key 'PrimaryKey', 'RangeKey'
    #   end
    #
    # @example Set dynamic attribute values.
    #   person = Person.build
    #   person[:first_name] = 'Maddie'
    #   person.last_name = 'Schipper'
    #
    # @author Maddie Schipper
    # @since 1.0.0
    class Base
      # @!parse extend  Mara::Model::Dsl::ClassMethods
      # @!parse extend  Mara::Model::Query::ClassMethods
      # @!parse extend  Mara::Model::Persistence::ClassMethods

      include ActiveModel::Validations
      include  Mara::Model::Dsl
      include  Mara::Model::Query
      include  Mara::Model::Persistence

      ##
      # @private
      #
      # The attributes container.
      #
      # @return [ Mara::Model::Attributes]
      attr_reader :attributes

      class << self
        ##
        # Create a new instance of the model.
        #
        # @example Building a new model.
        #   person = Person.build(
        #     partition_key: SecureRandom.uuid,
        #     first_name: 'Maddie',
        #     last_name: 'Schipper'
        #   )
        #
        # @param attributes [Hash] The default attributes that can be assigned.
        #
        #   If a +partition_key+ is specified it will be used to set the model's
        #   +partion_key+
        #
        #   If a +sort_key+ is specified it will be used to set the model's
        #   +sort_key+
        #
        # @return [ Mara::Model::Base]
        def build(attributes = {})
          partition_key = attributes.delete(:partition_key)
          sort_key = attributes.delete(:sort_key)

          attrs =  Mara::Model::Attributes.new(attributes)

          new(
            partition_key: partition_key,
            sort_key: sort_key,
            attributes: attrs,
            persisted: false
          )
        end

        ##
        # @private
        def construct(record_hash)
          partition_key = record_hash.delete(self.partition_key)
          sort_key = record_hash.delete(self.sort_key)

          attrs =  Mara::Model::Attributes.new(record_hash)

          new(
            partition_key: partition_key,
            sort_key: sort_key,
            attributes: attrs,
            persisted: true
          )
        end
      end

      ##
      # @private
      #
      # Create a new instance of the model.
      #
      # @param partition_key [Any] The partition_key for the model.
      # @param sort_key [Any] The sort key for the model.
      # @param attributes [ Mara::Model::Attributes] The already existing
      #   attributes for the model.
      def initialize(partition_key:, sort_key:, attributes:, persisted:)
        if self.class.partition_key.blank?
          raise  Mara::Model::PrimaryKeyError,
                "Can't create instance of #{self.class.name} without a `partition_key` set."
        end

        unless attributes.is_a?( Mara::Model::Attributes)
          raise ArgumentError, 'attributes is not  Mara::Model::Attributes'
        end

        @persisted = persisted == true
        @attributes = attributes

        self.partition_key = partition_key
        self.sort_key = sort_key if sort_key
      end

      ##
      # The partition_key key value for the object.
      #
      # @return [Any, nil]
      attr_accessor :partition_key

      ##
      # Set an attribute key value pair.
      #
      # @param key [#to_s] The key for the attribute.
      # @param value [Any, nil] The value of the attribute.
      #
      # @return [void]
      def []=(key, value)
        attributes.set(key, value)
      end

      ##
      # Get an attribute's current value.
      #
      # @param key [#to_s] The key for the attribute.
      #
      # @return [Any, nil]
      def [](key)
        attributes.get(key)
      end

      def model_primary_key
         Mara::PrimaryKey.new(model: self)
      end

      def model_identifier
         Mara::PrimaryKey.generate(model_primary_key)
      end

      ##
      # Fetch the current sort key value.
      #
      # @return [Any, nil]
      def sort_key
        if self.class.sort_key.blank?
          raise  Mara::Model::PrimaryKeyError,
                "Model #{self.class.name} does not specify a sort_key."
        end

        @sort_key
      end

      ##
      # Checks if the model should have a sort key and returns the value if
      # it does.
      #
      # @return [Any, nil]
      def conditional_sort_key
        return nil if self.class.sort_key.blank?

        sort_key
      end

      ##
      # Set a sort key value.
      #
      # @param sort_key [String] The sort key value.
      #
      # @return [void]
      def sort_key=(sort_key)
        if self.class.sort_key.blank?
          raise  Mara::Model::PrimaryKeyError,
                "Model #{self.class.name} does not specify a sort_key."
        end

        @sort_key = sort_key
      end

      ##
      # @private
      #
      # Attribute Magic
      def method_missing(name, *args, &block)
        if attributes.respond_to?(name)
          attributes.send(name, *args, &block)
        else
          super
        end
      end

      ##
      # @private
      #
      # Attribute Magic
      def respond_to_missing?(name, include_private = false)
        if attributes.respond_to?(name)
          true
        else
          super
        end
      end
    end
  end
end
