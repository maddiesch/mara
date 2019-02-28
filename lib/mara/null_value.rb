module Mara
  ##
  # @private
  #
  # The null value placeholder
  class NullValue; end

  ##
  # @private
  #
  # Default NULL value
  NULL = NullValue.new.freeze
end
