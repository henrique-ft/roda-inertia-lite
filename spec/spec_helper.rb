require "rack/test"
require "roda"
require_relative "../lib/roda-inertia-lite"

RSpec.configure do |config|
  config.include Rack::Test::Methods
end
