require 'base64'
require 'json'

module Mara
  ##
  # Wraps a primary key.
  #
  # @author Maddie Schipper
  # @since 1.0.0
  class PrimaryKey
    class << self
      ##
      # Create a primary key from a model.
      #
      # @param model [Mara::PrimaryKey,  Mara::Model::Base] The object to
      #   stringify.
      #
      # @return [String]
      def generate(model)
        case model
        when  Mara::PrimaryKey
          model.to_s
        when  Mara::Model::Base
          new(model: model).to_s
        else
          raise ArgumentError, "The value passed into generate isn't expected <#{model}>"
        end
      end

      ##
      # Parse a primary key string.
      #
      # @param key_str [String] The primary key string to return.
      #
      # @return [Mara::PrimaryKey]
      def parse(key_str)
        parts = JSON.parse(decode(key_str))
        new(
          class_name: parts[0],
          partition_key: parts[1],
          sort_key: parts[2]
        )
      end

      private

      def decode(str)
        str = str.tr('-_', '+/')
        str = str.ljust((str.length + 3) & ~3, '=')
        Base64.strict_decode64(str)
      end
    end

    ##
    # The classname of the model that the primary key represents.
    #
    # @return [String]
    attr_reader :class_name

    ##
    # The partion key
    #
    # @return [String]
    attr_reader :partition_key

    ##
    # The sort key
    #
    # @return [String]
    attr_reader :sort_key

    ##
    # Create a new primary key.
    #
    # @note If +:model+ is not present the other three options are required.
    #
    # @param opts [Hash] The options param
    # @option opts [ Mara::Model::Base] :model The model this key will represent.
    # @option opts [String] :class_name The class name of the model.
    # @option opts [String] :partition_key The partition key value.
    # @option opts [String] :sort_key The sort key value.
    def initialize(opts)
      if (model = opts.delete(:model)).present?
        @class_name = model.class.name
        @partition_key = if model.class.partition_key.present?
                           model.partition_key
                         end
        @sort_key = if model.class.sort_key.present?
                      model.sort_key
                    end
      else
        @class_name = opts.fetch(:class_name).camelize
        @partition_key = opts.fetch(:partition_key)
        @sort_key = opts.fetch(:sort_key, nil).presence
      end
    end

    ##
    # Convert the primary key into a URL safe representation.
    #
    # @return [String]
    def to_s
      payload = JSON.dump([
                            (class_name.presence || '').underscore,
                            partition_key.presence || '',
                            sort_key.presence || ''
                          ])
      encode(payload)
    end

    private

    def encode(bin)
      Base64.strict_encode64(bin).tr('+/', '-_').tr('=', '')
    end
  end
end
