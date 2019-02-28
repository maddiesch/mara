require_relative 'client'
require_relative 'configure'
require_relative 'instrument'
require_relative 'attribute_formatter'
require_relative 'dynamo_helpers'

module Mara
  ##
  # @private
  #
  # Perform calls to DynamoDB for fetching
  #
  # @author Maddie Schipper
  # @since 1.0.0
  class Query
    include DynamoHelpers

    ##
    # The response from DynamoDB
    #
    # @!attribute [r] items
    #   The items returned by DynamoDB
    #
    #   @return [Array<Hash>]
    #
    # @!attribute [r] consumed_capacity
    #   The capacity DyanmoDB used to perform the request.
    #
    #   @return [Float]
    Result = Struct.new(:items, :consumed_capacity)

    class << self
      ##
      # Perform a single item get request by the primary key.
      #
      # @param query_params [Hash] The query items.
      #
      # @return [ Mara::Query::Result]
      def get_item(query_params)
        client, table_name = config_params(query_params)
        primary_key = query_params.fetch(:key)
        projection_expression = query_params.fetch(:projection_expression, nil).presence

        params = {
          key: primary_key,
          table_name: table_name,
          return_consumed_capacity: 'TOTAL',
          projection_expression: projection_expression
        }

        result =  Mara.instrument('get_item', params) do
          client.get_item(params)
        end

        return nil if result.item.nil?

        item = format_item(result.item)
        cc = calculate_consumed_capacity(result.consumed_capacity, table_name)

        Result.new(
          [item],
          cc
        )
      end

      private

      def format_item(item)
        item.map do |key, value|
          [key,  Mara::AttributeFormatter.flatten(value)]
        end.to_h
      end

      def wrap_items(result)
        if result.responses
          result.responses
        else
          [result.item]
        end
      end

      def config_params(params)
        [
          params.fetch(:client,  Mara::Client.shared),
          params.fetch(:table_name,  Mara.config.dynamodb.table_name)
        ]
      end
    end
  end
end
