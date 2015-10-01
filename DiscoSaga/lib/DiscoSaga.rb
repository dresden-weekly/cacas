require "DiscoSaga/version"
require 'DiscoSaga/meta/saga'

module DiscoSaga
  # Your code goes here...

  def self.acts_as_saga &block
    s = Meta::Saga.new
    block.call(s)
    # TODO: build code
  end

end
