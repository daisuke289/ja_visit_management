# frozen_string_literal: true

RSpec.configure do |config|
  config.include Warden::Test::Helpers
  config.include Devise::Test::IntegrationHelpers, type: :request

  config.before(:suite) do
    Warden.test_mode!
  end

  config.after(:each) do
    Warden.test_reset!
  end
end
