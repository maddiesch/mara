module Mara
  ##
  # Configure  Mara
  #
  # @param env [String] The default environment that is being configured.
  #
  #   If this block is called a second time, the previous env version will
  #   be overridden
  #
  # @yield [config] The configuration object to set values on.
  #
  # @yieldparam config [ Mara::Configure] The configuration object.
  # @yieldreturn [void]
  #
  # @return [void]
  def self.configure(env)
    instance = config
    instance.send(:_set_env, env)
    yield(instance)
  end

  ##
  # @private
  #
  # The current config
  def self.config
    @config ||= Configure.new
    @config
  end

  ##
  # The configuration for  Mara
  #
  # @author Maddie Schipper
  # @since 1.0.0
  class Configure
    ##
    # DynamoDB specific config values.
    #
    # @!attribute [rw] table_name
    #   The name of the DynamoDB table to use.
    #
    #   @note If this is not set, pretty much nothing will work.
    #
    #   @return [String, nil]
    # @!attribute [rw] endpoint
    #   The DynamoDB endpoint to use. If `nil` this will fallback to the
    #   AWS default endpoint.
    #
    #   @return [String, nil]
    DynamoConfig = Struct.new(:table_name, :endpoint)

    ##
    # Aws specific config values.
    #
    # @!attribute [rw] region
    #   The region name to use for the Client.
    #
    #   @note By default this is `us-east-1`
    #
    #   @return [String]
    AwsConfig = Struct.new(:region)

    ##
    # The current environment that  Mara is configured for.
    #
    # @return [String]
    attr_reader :env

    ##
    # The Aws config
    #
    # @return [ Mara::Configure::AwsConfig]
    attr_reader :aws

    ##
    # The DynamoDB config
    #
    # @return [ Mara::Configure::DynamoConfig]
    attr_reader :dynamodb

    ##
    # @private
    #
    # Create a new instance.
    #
    # @note This should never be called directly by the client.
    def initialize
      @env = 'production'
      @dynamodb = DynamoConfig.new(nil, nil)
      @aws = AwsConfig.new('us-east-1')
    end

    private

    def _set_env(env)
      @env = env.to_s
    end
  end
end
