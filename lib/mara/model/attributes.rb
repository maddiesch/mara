require_relative '../error'

module Mara
  module Model
    ##
    # Errors raised when trying to set a key.
    #
    # @author Maddie Schipper
    # @since 1.0.0
    class AttributeError <  Mara::Error; end

    ##
    # The container class for attributes.
    #
    # This should not be created directly. Instead use the Model convenience
    # methods to have this setup automatically.
    #
    # @author Maddie Schipper
    # @since 1.0.0
    class Attributes
      ##
      # @private
      #
      # Create a new instance of attributes.
      #
      # @param default [Hash] The default attribute values to set.
      def initialize(default)
        @storage = {}
        default.each { |k, v| set(k, v) }
      end

      ##
      # @private
      #
      # Enumerate each key, value pair.
      def each
        return @storage.enum_for(:each) unless block_given?

        @storage.each do |*args|
          yield(*args)
        end
      end

      ##
      # Set a key, value pair on the attributes.
      #
      # @param key [#to_s] The key for the attribute you're trying to set.
      #
      #   This key will be normalized before being stored as an attribute.
      #
      # @param value [Any, nil] The value to set for the key.
      #
      # @param pre_formatted [true, false] If the key is already normalized.
      #
      # @note If the value is +nil+, the key will be deleted.
      #
      # @raise [AttributeError] The normalized value of the key can't be blank.
      #
      # @return [void]
      def set(key, value, pre_formatted: false)
        nkey = normalize_key(key, pre_formatted)

        raise AttributeError, "Can't set an attribute without a key" if nkey.blank?

        if value.nil?
          @storage.delete(nkey)
        else
          @storage[nkey] = value
        end
      end

      ##
      # Get a value an attribute value.
      #
      # @param key [#to_s] The key for the attribute you're getting.
      #
      # @param pre_formatted [true, false] If the key is already normalized.
      #
      # @raise [AttributeError] The normalized value of the key can't be blank.
      #
      # @return [Any, nil]
      def get(key, pre_formatted: false)
        nkey = normalize_key(key, pre_formatted)

        raise AttributeError, "Can't get an attribute without a key" if nkey.blank?

        @storage[nkey]
      end

      ##
      # Get an attribute value but it that value is nil, return the default
      # passed as the second argument.
      #
      # @example Get a default value.
      #   attrs.set('foo', nil)
      #   attrs.fetch('foo', 'bar')
      #   # => 'bar'
      #
      # @param key [#to_s] The key for the attribute you're getting.
      #
      # @param default [Any, nil] The default value to return if the value
      #   for the key is nil.
      #
      # @param pre_formatted [true, false] If the key is already normalized.
      #
      # @return [Any, nil]
      def fetch(key, default = nil, pre_formatted: false)
        value = get(key, pre_formatted: pre_formatted)
        return default if value.nil?

        value
      end

      ##
      # Check if a key exists.
      #
      # @param key [#to_s] The key you want to check to see if it exists.
      #
      # @param pre_formatted [true, false] If the key is already normalized.
      #
      # @return [true, false]
      def key?(key, pre_formatted: false)
        nkey = normalize_key(key, pre_formatted)
        @storage.key?(nkey)
      end

      ##
      # @private
      #
      # Dump the storage backend into a hash.
      #
      # @return [Hash<String, Any>]
      def to_h
        @storage.dup
      end

      ##
      # @private
      #
      # Attribute Magic
      def method_missing(name, *args, &_block)
        if name.to_s.end_with?('=')
          set(name.to_s.gsub(/=$/, ''), *args)
        else
          get(name, *args)
        end
      end

      ##
      # @private
      #
      # Attribute Magic
      def respond_to_missing?(_name, _include_private = false)
        true
      end

      private

      def normalize_key(key, pre_formatted)
        return key if pre_formatted == true

        key.to_s.camelize
      end
    end
  end
end
