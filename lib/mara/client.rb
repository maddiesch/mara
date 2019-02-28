require 'aws-sdk-dynamodb'

require_relative 'configure'

module Mara
  ##
  # @private
  #
  # Internal DynamoDB client.
  #
  # @author Maddie Schipper
  # @since 1.0.0
  class Client
    class << self
      ##
      # @private
      #
      # Create a new DynamoDB client.
      #
      # @return [Aws::DynamoDB::Client]
      def create_client
        params = {
          region:  Mara.config.aws.region,
          simple_attributes: false
        }
        if (endpoint =  Mara.config.dynamodb.endpoint)
          params[:endpoint] = endpoint
        end
        Aws::DynamoDB::Client.new(params)
      end

      ##
      # @private
      #
      # The shared client.
      #
      # @return [Aws::DynamoDB::Client]
      def shared
        @shared ||= create_client
      end
    end
  end
end
