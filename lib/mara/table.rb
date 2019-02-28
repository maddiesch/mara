require_relative 'client'
require_relative 'configure'

module Mara
  ##
  # Manage Dev/Test tables.
  #
  # While this _can_ be used to create real tables, we don't recommend it.
  #
  # @author Maddie Schipper
  # @since 1.0.0
  class Table
    class << self
      ##
      # @private
      #
      # Default supported environments
      SUPPORTED_ENVS = %w[development test].freeze

      ##
      # Create a new table if it doesn't exist.
      #
      # @note If the table_params do not include the table name, The default
      #   table name from the config will be used.
      #
      # @param table_params [Hash] DynamoDB create table params hash.
      #
      # @return [true, false]
      def prepare!(table_params)
        prepare_table!(table_params, SUPPORTED_ENVS, true)
      end

      ##
      # Teardown the table if it exists.
      #
      # @note If the table_params do not include the table name, The default
      #   table name from the config will be used.
      #
      # @param table_params [Hash] DynamoDB table name params.
      #
      # @return [true, false]
      def teardown!(table_params = {})
        teardown_table!(table_params, SUPPORTED_ENVS, true)
      end

      ##
      # Check if a table exists.
      #
      # @param table_name [String] the name of the table to check if it exists.
      #
      # @return [true, false]
      def table_exists?(table_name)
         Mara::Client.shared.list_tables.table_names.include?(table_name)
      end

      ##
      # @private
      #
      # Prepare the table with extra options.
      #
      # @param table_params [Hash] DynamoDB create table params hash.
      # @param envs [Array<String>] The environments that are allowed to check
      #   if this action is allowed.
      # @param wait [true, false] Should this function wait for the table to
      #   become fully available before returning.
      #
      # @return [true, false]
      def prepare_table!(table_params, envs, wait)
        env =  Mara.config.env
        unless Array(envs).include?(env)
          raise ArgumentError, "Can't prepare table outside of #{envs.join('/')}"
        end

        table_name = table_params.fetch(:table_name,  Mara.config.dynamodb.table_name)

        if table_exists?(table_name)
          return true
        end

        table_params = normalize_table_params(table_params, table_name)

        log(" Mara create_table(\"#{table_name}\")")

         Mara::Client.shared.create_table(table_params)
         Mara::Client.shared.wait_until(:table_exists, table_name: table_name) if wait

        true
      end

      ##
      # @private
      #
      # Teardown the table with extra options.
      #
      # @param table_params [Hash] DynamoDB create table params hash.
      # @param envs [Array<String>] The environments that are allowed to check
      #   if this action is allowed.
      # @param wait [true, false] Should this function wait for the table to
      #   become fully available before returning.
      #
      # @return [true, false]
      def teardown_table!(table_params, envs, wait)
        env =  Mara.config.env
        unless envs.include?(env)
          raise ArgumentError, "Can't prepare table outside of #{envs.join('/')}"
        end

        table_name = table_params.fetch(:table_name,  Mara.config.dynamodb.table_name)

        unless  Mara::Client.shared.list_tables.table_names.include?(table_name)
          return true
        end

        log(" Mara destroy_table(\"#{table_name}\")")

         Mara::Client.shared.delete_table(table_name: table_name)
         Mara::Client.shared.wait_until(:table_not_exists, table_name: table_name) if wait

        true
      end

      private

      def log(msg)
        STDERR.puts msg
      end

      def normalize_table_params(table_params, table_name)
        provisioned_throughput = table_params.fetch(:provisioned_throughput,
                                                    read_capacity_units: 10,
                                                    write_capacity_units: 10)

        table_params.delete(:billing_mode)
        table_params[:table_name] = table_name
        table_params[:provisioned_throughput] = provisioned_throughput

        table_params
      end
    end
  end
end
