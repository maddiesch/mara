require_relative 'error'
require_relative 'client'
require_relative 'configure'
require_relative 'instrument'
require_relative 'dynamo_helpers'

module Mara
  ##
  # @private
  #
  # Perform calls to DynamoDB for saving/updating/deleting
  #
  # @author Maddie Schipper
  # @since 1.0.0
  class Persistence
    include DynamoHelpers

    ##
    # @private
    #
    # A wrapper for a create request.
    #
    # @!attribute [rw] record
    #   The record hash to be created.
    #
    #   @return [Hash]
    #
    # @author Maddie Schipper
    # @since 1.0.0
    CreateRequest = Struct.new(:record) do
      ##
      # Converts the CreateRequest to JSON
      #
      # @return [Hash]
      def as_json
        {
          put_request: {
            item: record
          }
        }
      end
    end

    ##
    # @private
    #
    # A wrapper for a destroy request.
    #
    # @!attribute [rw] record
    #   The record hash to be destroyed.
    #
    #   @return [Hash]
    #
    # @author Maddie Schipper
    # @since 1.0.0
    DestroyRequest = Struct.new(:record) do
      ##
      # Converts the DestroyRequest to JSON
      #
      # @return [Hash]
      def as_json
        {
          delete_request: {
            key: record
          }
        }
      end
    end

    ##
    # @private The response for a save operation.
    #
    # @!attribute [r] consumed_capacity
    #   The total consumed capacity for the request.
    #
    #   @return [Float]
    #
    # @!attribute [r] operation_count
    #   The total number of API calls required to perform the operation.
    #
    #   @return [Integer]
    #
    # @author Maddie Schipper
    # @since 1.0.0
    Response = Struct.new(:consumed_capacity, :operation_count)

    ##
    # @private
    #
    # Error thrown by Persistence calls.
    #
    # @author Maddie Schipper
    # @since 1.0.0
    class Error <  Mara::Error; end

    class << self
      ##
      # Perform a save on a item.
      #
      # @param item [Hash] The item to be saved.
      #
      # @return [true, false]
      def save_model(item)
        create = CreateRequest.new(item)
        response = perform_requests(
           Mara::Client.shared,
           Mara.config.dynamodb.table_name,
          [create]
        )
        !response.nil?
      end

      ##
      # Perform a save on the a item.
      #
      # @see .save_model
      #
      # @param item [Hash] The item to be saved.
      #
      # @raise Error If the save operation fails.
      #
      # @return [void]
      def save_model!(item)
        return if save_model(item)

        raise Error, 'Failed to save!'
      end

      ##
      # Delete an item.
      #
      # @param item [Hash] The item to be deleted.
      #
      # @return [true, false]
      def delete_model(item)
        delete = DestroyRequest.new(item)
        response = perform_requests(
           Mara::Client.shared,
           Mara.config.dynamodb.table_name,
          [delete]
        )
        !response.nil?
      end

      ##
      # Delete an item.
      #
      # @see .delete_model
      #
      # @param item [Hash] The item to be deleted.
      #
      # @raise Error If the delete operation fails.
      #
      # @return [void]
      def delete_model!(item)
        return if delete_model(item)

        raise Error, 'Failed to delete!'
      end

      ##
      # Perform a batch of save requests.
      def perform_requests(client, table_name, requests, group_size = 10)
        results =  Mara.instrument('save_batch_records', requests: requests, table_name: table_name) do
          requests.each_slice(group_size).map do |sub_requests|
            _perform_requests(client, table_name, sub_requests)
          end
        end
        Response.new(
          results.map(&:consumed_capacity).sum,
          results.map(&:operation_count).sum
        )
      end

      private

      def _base_batch_write_item_params(table_name)
        params = {
          return_consumed_capacity: 'TOTAL',
          return_item_collection_metrics: 'SIZE',
          request_items: {}
        }
        if block_given?
          params[:request_items][table_name] = yield
        end
        params
      end

      def _perform_requests(client, table_name, requests)
        params = _base_batch_write_item_params(table_name) { requests.map(&:as_json) }
        response =  Mara.instrument('save_batch_record_operation', requests: requests, table_name: table_name) do
          client.batch_write_item(params)
        end

        cc = calculate_consumed_capacity(response.consumed_capacity, table_name)

        Response.new(
          cc,
          1
        )
      end
    end
  end
end
