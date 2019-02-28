require_relative '../attribute_formatter'
require_relative '../batch'
require_relative '../instrument'

module Mara
  module Model
    ##
    # Methods that save/update/delete a model.
    #
    # @author Maddie Schipper
    # @since 1.0.0
    module Persistence
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
      end

      ##
      # @private
      #
      # Converts the attributes into a DynamoDB compatable hash.
      #
      # @return [Hash]
      def to_dynamo
        {}.tap do |formatted|
          attributes.each do |key, value|
            formatted[key] =  Mara::AttributeFormatter.format(value)
          end
        end
      end

      ##
      # @private
      #
      # Get a primary key attribute for the item.
      #
      # @return [Hash]
      def primary_key
        {}.tap do |base|
          base[self.class.partition_key] =  Mara::AttributeFormatter.format(partition_key)

          unless self.class.sort_key.blank?
            base[self.class.sort_key] =  Mara::AttributeFormatter.format(sort_key)
          end
        end
      end

      ##
      # @private
      #
      # Create a DynamoDB representation of the model.
      #
      # @return [Hash]
      def to_item
        to_dynamo.merge(primary_key)
      end

      ##
      # Perform validation and save the model.
      #
      # @return [true, false]
      def save
         Mara.instrument('model.save', model: self) do
          next false unless valid?

           Mara::Batch.save_model(to_item)
        end
      end

      ##
      # Perform validation and save the model.
      #
      # @see #save
      #
      # @note Same as {#save} but will raise an error on validation faiure and
      #   save failure
      #
      # @return [void]
      def save!
         Mara.instrument('model.save', model: self) do
          validate!
           Mara::Batch.save_model!(to_item)
        end
      end

      ##
      # Perform a destroy on the model.
      #
      # @return [true, false]
      def destroy
         Mara.instrument('model.destroy', model: self) do
           Mara::Batch.delete_model(primary_key)
        end
      end

      ##
      # Perform a destroy on the model.
      #
      # @see #destroy
      #
      # @note Same as {#destroy} but will raise an error on delete failure.
      #
      # @return [void]
      def destroy!
         Mara.instrument('model.destroy', model: self) do
           Mara::Batch.delete_model!(primary_key)
        end
      end
    end
  end
end
