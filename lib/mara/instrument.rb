require 'active_support'

module Mara
  ##
  # @private
  #
  # Convenience method for {ActiveSupport::Notifications} that also namespaces
  #   the key.
  #
  # @param name [string] The name of the action being instrumented.
  #
  # @return [Object] The return value of the block
  def self.instrument(name, *args, &block)
    ActiveSupport::Notifications.instrument("mara.#{name}", *args, &block)
  end
end
