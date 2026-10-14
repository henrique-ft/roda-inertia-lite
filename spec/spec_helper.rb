require "rack/test"
require "roda"
require_relative "../lib/inertia_roda"

RSpec.configure do |config|
  config.include Rack::Test::Methods
end
