require_relative '../error'
require_relative '../query'
require_relative '../attribute_formatter'
require_relative '../instrument'

module Mara
  module Model
    ##
    # Error raised when a find method fails to find the requested object.
    #
    # @author Maddie Schipper
    # @since 1.0.0
    class NotFoundError < Error; end

    ##
    # Methods to query for a model.
    #
    # @author Maddie Schipper
    # @since 1.0.0
    module Query
      ##
      # @private
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      ##
      # Helper methods defined on the class.
      #
      # @author Maddie Schipper
      # @since 1.0.0
      module ClassMethods
        ##
        # Find a single object with the matching partition_key and sort key.
        #
        # @param partition_key [#to_s] The value for the partition key.
        #
        # @param sort_key [#to_s, nil] The value for the sort key.
        #
        # @raise [NotFoundError] If the object doesn't exist in the table for
        #   the requested primary key.
        #
        # @raise [ArgumentError] If the +partition_key+ is blank, or the
        #   +sort_key+ is blank and the class defines a sort_key name.
        #
        # @return [ Mara::Model::Base]
        def find(partition_key, sort_key = nil)
           Mara.instrument('model.find', class_name: name, partition_key: partition_key, sort_key: sort_key) do
            _find(partition_key, sort_key)
          end
        end

        ##
        # @private
        #
        # @see #find
        def _find(partition_key, sort_key = nil)
          if partition_key.blank?
            raise ArgumentError, 'Must specify a valid partition key value'
          end

          if sort_key.nil? && !self.sort_key.blank?
            raise ArgumentError, "#{self.class.name} specifies a sort key, but no sort key value was given."
          end

          key_params = {}
          key_params[self.partition_key] =  Mara::AttributeFormatter.format(partition_key)
          if self.sort_key.present?
            key_params[self.sort_key] =  Mara::AttributeFormatter.format(sort_key)
          end

          response =  Mara::Query.get_item(key: key_params)

          if response.nil? || response.items.empty?
            raise NotFoundError, "Can't find item with pk=#{partition_key} sk=#{sort_key}"
          end

          item = response.items[0]

          construct(item)
        end
      end

      ##
      # Checks if a the model exists in the table?
      #
      # @return [true, false]
      def exist?
        pk = partition_key
        sk = conditional_sort_key
        self.class.find(pk, sk).present?
      rescue  Mara::Model::NotFoundError
        false
      end
    end
  end
end
