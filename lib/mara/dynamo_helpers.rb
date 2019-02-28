module Mara
  ##
  # @private
  #
  # Helper methods for formatting data as it comes back from DynamoDB
  module DynamoHelpers
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      ##
      # Calculate all the consumed capacity in an array of capacity objects.
      def calculate_consumed_capacity(consumed_capacity, table_name)
        consumed = consumed_capacity.is_a?(Array) ? consumed_capacity : [consumed_capacity]

        if table_name
          consumed.select! { |cap| cap.table_name == table_name }
        end

        consumed.map! { |cap| _sum_capacity(cap) }
        consumed.sum
      end

      ##
      # @private
      #
      # Count the number of capcity unites in a capacity object.
      def _sum_capacity(cap)
        cap.capacity_units.to_f
      end
    end
  end
end
