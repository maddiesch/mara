require_relative '../error'

module Mara
  module Model
    ##
    # An error raised if the index requested in
    # {Dsl::ClassMethods.global_secondary_index} or
    # {Dsl::ClassMethods.global_secondary_index} are not found.
    #
    # @author Maddie Schipper
    # @since 1.0.0
    class IndexError <  Mara::Error; end

    ##
    # Represents a DynamoDB Local Secondary Index.
    #
    # @see  Mara::Model::Dsl::ClassMethods#add_lsi
    #
    # @!attribute [rw] name
    #   The name of the index.
    #
    #   @return [String]
    #
    # @!attribute [rw] key_name
    #   The name of the LSI sort_key.
    #
    #   @return [String]
    LocalSecondaryIndex = Struct.new(:name, :key_name)

    ##
    # Represents a DynamoDB Global Secondary Index.
    #
    # @see  Mara::Model::Dsl::ClassMethods#add_gsi
    #
    # @!attribute [rw] name
    #   The name of the index.
    #
    #   @return [String]
    #
    # @!attribute [rw] partition_key
    #   The name of the GSI partion key.
    #
    #   @return [String]
    #
    # @!attribute [rw] sort_key
    #   The name of the GSI sort_key.
    #
    #   @return [String, nil]
    GlobalSecondaryIndex = Struct.new(:name, :partition_key, :sort_key)

    ##
    # Helper DSL methods for Base class.
    #
    # @author Maddie Schipper
    # @since 1.0.0
    module Dsl
      ##
      # @private
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      ##
      # Helper method added at the class level.
      #
      # @author Maddie Schipper
      # @since 1.0.0
      module ClassMethods
        ##
        # Set a partion_key and sort_key for a model.
        #
        # @see #partition_key
        #
        # @see #sort_key
        #
        # @example Setting the partition_key & sort_key
        #   class Person <  Mara::Model::Base
        #     primary_key('PartionKeyName', 'SortKeyName')
        #     # ...
        #
        # @param partition_key [#to_s] The name of the DynamoDB table's partion
        #   key.
        #
        # @param sort_key [#to_s, nil] The name of the DynamoDB table's sort
        #   key.
        #
        # @return [void]
        def primary_key(partition_key, sort_key = nil)
          partition_key(partition_key)
          sort_key(sort_key)
        end

        ##
        # Set the partion key name for the model. This value is required.
        #
        # @param partition_key [#to_s] The name of the partion key.
        #
        # @return [String]
        def partition_key(partition_key = nil)
          unless partition_key.nil?
            @partition_key = partition_key.to_s
            validates_presence_of :partition_key
          end
          @partition_key
        end

        ##
        # Set the sort key name for the model.
        #
        # @param sort_key [#to_s] The name of the sort key.
        #
        # @return [String]
        def sort_key(sort_key = nil)
          unless sort_key.nil?
            @sort_key = sort_key.to_s
            validates_presence_of :sort_key
          end

          @sort_key
        end

        ##
        # Add a local secondary index definition.
        #
        # @note This is only required for querying.
        #
        # @param name [String] The name of the index.
        #
        # @param key_name [String] The name of the LSI sort key.
        #
        # @return [void]
        def add_lsi(name, key_name)
          local_secondary_indices[name.to_s] = LocalSecondaryIndex.new(name.to_s, key_name.to_s)
        end

        ##
        # @private
        #
        # All registered local secondary indices
        #
        # @return [Hash<String, LocalSecondaryIndex>]
        def local_secondary_indices
          @local_secondary_indices ||= {}
        end

        ##
        # Get a defined local secondary index by name.
        #
        # @param name [#to_s] The name of the LSI to get.
        #
        # @raise [IndexError] The index is not registered on the model.
        #
        # @return [LocalSecondaryIndex]
        def local_secondary_index(name)
          index = local_secondary_indices[name.to_s]
          if index.nil?
            raise  Mara::Model::IndexError, "Can't find a LSI with the name `#{name}`"
          end

          index
        end

        ##
        # Add a global secondary index definition.
        #
        # @note This is only required for querying.
        #
        # @param name [#to_s] The name of the index.
        #
        # @param partition_key [#to_s] The name of the GSI partition key.
        #
        # @param sort_key [String, nil] The name of the GSI sort key.
        #
        # @return [void]
        def add_gsi(name, partition_key, sort_key = nil)
          global_secondary_indices[name.to_s] = GlobalSecondaryIndex.new(name.to_s, partition_key.to_s, sort_key)
        end

        ##
        # @private
        #
        # All registered global secondary indices
        #
        # @return [Hash<String, GlobalSecondaryIndex>]
        def global_secondary_indices
          @global_secondary_indices ||= {}
        end

        ##
        # Get a defined global secondary index by name.
        #
        # @param name [#to_s] The name of the GSI to get.
        #
        # @raise [IndexError] The index is not registered on the model.
        #
        # @return [GlobalSecondaryIndex]
        def global_secondary_index(name)
          index = global_secondary_indices[name.to_s]
          if index.nil?
            raise  Mara::Model::IndexError, "Can't find a GSI with the name `#{name}`"
          end

          index
        end
      end
    end
  end
end
