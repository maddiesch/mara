require_relative 'persistence'
require_relative 'instrument'

module Mara
  ##
  # Raise this within a { Mara::Batch#in_batch} to quietly rollback the batch.
  #
  # @note All current operations will be dropped.
  #
  # @author Maddie Schipper
  # @since 1.0.0
  class Rollback < StandardError; end

  ##
  # Perform operations in batches.
  #
  # @note This is not the same as a transaction. It only saves on the number
  #   of API calls to DynamoDB.
  #
  # @example Saving Multiple Records
  #   Mara::Batch.in_batch do
  #     person1.save
  #     person2.save
  #   end
  #
  # @author Maddie Schipper
  # @since 1.0.0
  class Batch
    ##
    # @private
    #
    # The name of the thread variable that holds the current batch spec.
    BATCH_STACK_VAR_NAME = 'mara_batch'.freeze

    class << self
      ##
      # Perform in a batch.
      #
      # All save/destroy calls on a model will be routed into the current batch.
      #
      # If there is a error raised all operations will be dropped.
      #
      # If the error is a { Mara::Rollback} the batch will silently rollback.
      # If not, it will be re-thrown after the rollback.
      #
      # @yield The batch operation.
      def in_batch
        begin_new_batch
        begin
          yield
        rescue  Mara::Rollback
          abort_current_batch
        # rubocop:disable Lint/RescueException
        rescue Exception => exception
          # rubocop:enable Lint/RescueException
          abort_current_batch
          raise exception
        else
          commit_current_batch
        end
      end

      ##
      # @private
      #
      # Perform a save model. If there is a current batch it is added to the
      # operation queue. If there is no current batch, this will be forwarded
      # directly to the { Mara::Persistence}.
      #
      # @param item [Hash] The model to perform the action with.
      def save_model(item)
        perform_for_model(:save_model, item)
      end

      ##
      # @private
      #
      # Perform a save model. If there is a current batch it is added to the
      # operation queue. If there is no current batch, this will be forwarded
      # directly to the { Mara::Persistence}.
      #
      # @param item [Hash] The model to perform the action with.
      def save_model!(item)
        perform_for_model(:save_model!, item)
      end

      ##
      # @private
      #
      # Perform a delete model. If there is a current batch it is added to the
      # operation queue. If there is no current batch, this will be forwarded
      # directly to the { Mara::Persistence}.
      #
      # @param item [Hash] The model to perform the action with.
      def delete_model(item)
        perform_for_model(:delete_model, item)
      end

      ##
      # @private
      #
      # Perform a delete model. If there is a current batch it is added to the
      # operation queue. If there is no current batch, this will be forwarded
      # directly to the { Mara::Persistence}.
      #
      # @param item [Hash] The model to perform the action with.
      def delete_model!(item)
        perform_for_model(:delete_model!, item)
      end

      private

      def perform_for_model(action_name, item)
        if (batch = current_batch)
          batch.add(action_name, item)
        else
           Mara::Persistence.send(action_name, item)
        end
      end

      def current_batch
        batch_stack.first
      end

      def batch_stack
        Thread.current[BATCH_STACK_VAR_NAME] ||= []
      end

      def begin_new_batch
        batch_stack <<  Mara::Batch.new
      end

      def commit_current_batch
        batch_stack.pop.commit_batch
      end

      def abort_current_batch
        batch_stack.pop.abort_batch
      end
    end

    ##
    # @private
    #
    # The queue of operations to perform on commit.
    #
    # @return [Array<Array<Symbol, Hash>>]
    attr_reader :operations

    ##
    # The current batch id.
    #
    # @return [String]
    attr_reader :batch_id

    ##
    # @private
    #
    # Create a new batch.
    def initialize
      @batch_id = SecureRandom.uuid
      @operations = []
    end

    ##
    # @private
    #
    # Add an item to the operation queue.
    #
    # @param action_name [Symbol] The action to perform for the item.
    # @param item [Hash] The hash of data for the action.
    #
    # @return [void]
    def add(action_name, item)
       Mara.instrument('batch.add_item', batch_id: batch_id, action: action_name, item: item) do
        operations << [action_name, item]
      end
    end

    ##
    # @private
    #
    # Perform all the operations in the queue.
    #
    # @return [void]
    def commit_batch
       Mara.instrument('batch.commit', batch_id: batch_id) do
        execute_commit
      end
    end

    ##
    # @private
    #
    # Abort the batch and clear the current batch operations.
    #
    # @return [void]
    def abort_batch
      @operations = []
       Mara.instrument('batch.abort', batch_id: batch_id)
    end

    private

    def execute_commit
      ops = operations.map do |action_name, item|
        case action_name
        when :save_model, :save_model!
           Mara::Persistence::CreateRequest.new(item)
        when :delete_model, :delete_model!
           Mara::Persistence::DestroyRequest.new(item)
        else
          raise "Unexpected operation action name #{action_name}"
        end
      end
       Mara::Persistence.perform_requests(
         Mara::Client.shared,
         Mara.config.dynamodb.table_name,
        ops
      )
    end
  end
end
