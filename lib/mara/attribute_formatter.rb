require 'aws-sdk-dynamodb'

require_relative 'error'
require_relative 'null_value'

module Mara
  ##
  # Helper class that provides Attribute Formatting for DynamoDB values.
  #
  # @author Maddie Schipper
  # @since 1.0.0
  class AttributeFormatter
    ##
    # The error that is raised if an attribute value fails to be converted into
    # a valid DynamoDB value.
    #
    # @author Maddie Schipper
    # @since 1.0.0
    class Error <  Mara::Error; end

    class << self
      ##
      # @private
      #
      # Format a value into a DynamoDB valid format.
      #
      # @param value [Object] The value to be formatted.
      #
      # @return [Hash]
      def format(value)
        case value
        when true, false
          { bool: value }
        when nil,  Mara::NullValue
          { null: true }
        when String
          { s: value }
        when Symbol
          { s: value.to_s }
        when Numeric
          { n: value.to_s }
        when Time
          { n: value.utc.to_i.to_s }
        when DateTime, Date
          format(value.to_time)
        when Hash
          format_hash(value)
        when Array
          format_array(value)
        when Set
          format_set(value)
        else
          raise Error, "Unexpected value type #{value.class.name} <#{value}>"
        end
      end

      ##
      # @private
      #
      # Convert a Aws::DynamoDB::Types::AttributeValue to a raw value
      #
      # @param value [Aws::DynamoDB::Types::AttributeValue] The value to convert
      #
      # @return [Object]
      def flatten(value)
        unless value.is_a?(Aws::DynamoDB::Types::AttributeValue)
          raise ArgumentError, 'Not an attribute type'
        end

        if value.s.present?
          value.s
        elsif value.n.present?
          format_number(value.n)
        elsif value.ss.present?
          Set.new(value.ss)
        elsif value.ns.present?
          Set.new(value.ns.map { |v| format_number(v) })
        elsif value.m.present?
          flatten_hash(value.m)
        elsif value.l.present?
          flatten_array(value.l)
        elsif value.null
           Mara::NULL
        elsif !value.bool.nil?
          value.bool
        else
          raise Error, 'Unexpected value type from DynamoDB'
        end
      end

      private

      def format_number(number)
        if number.include?('.')
          number.to_f
        else
          number.to_i
        end
      end

      def flatten_hash(hash)
        hash.each_with_object({}) do |(key, value), object|
          object[key] = flatten(value)
        end
      end

      def flatten_array(array)
        array.map { |value| flatten(value) }
      end

      def format_array(array)
        value = Array(array)
        if value.empty?
          return format(nil)
        end

        values = value.map do |val|
          format(val)
        end

        { l: values }
      end

      def format_hash(hash)
        value = Hash(hash)
        if value.empty?
          return format(nil)
        end

        formatted = value.each_with_object({}) do |(key, sub_value), object|
          next unless value.present?

          object[key.to_s] = format(sub_value)
        end

        { m: formatted }
      end

      def format_set(set)
        value = Set.new(set.to_a)
        if value.empty?
          return format(nil)
        end

        kind = value.map(&:class).uniq

        if kind.count != 1 && kind.to_a.reject { |v| v.ancestors.include?(Numeric) }.any?
          raise Error, "Set type must only contain 1 type #{value.class.name}"
        end

        if kind.first == String || kind.first == Symbol
          { ss: value.to_a.map(&:to_s) }
        elsif kind.first.ancestors.include?(Numeric)
          { ns: value.to_a.map(&:to_s) }
        else
          raise Error, "Unexpected Set type #{kind.first.class.name}"
        end
      end
    end
  end
end
