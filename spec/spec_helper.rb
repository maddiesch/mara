require 'simplecov'
SimpleCov.start do
  add_filter '/spec'
  add_filter '/vendor'
end

require 'bundler/setup'
require 'pry'
require 'yaml'
require 'mara'

module SupportHelpers
  def self.helper_file_path
    Pathname.new(__dir__).join('support', 'helper_files')
  end

  def self.helper_file(*args)
    File.read(helper_file_path.join(*args))
  end

  delegate :helper_file, :helper_file_path, to: :SupportHelpers
end

NOTIFICATION_NAMES = Set.new

RSpec.configure do |config|
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include(SupportHelpers)

  config.before(:suite) do
    content = SupportHelpers.helper_file('table.yml')
     Mara::Table.prepare!(YAML.safe_load(content, [Symbol]))
  end

  config.after(:suite) do
    puts
    puts NOTIFICATION_NAMES.to_a.sort
    puts
     Mara::Table.teardown!
  end
end

ActiveSupport::Notifications.subscribe(/^mara\.*/) do |*args|
  NOTIFICATION_NAMES.add(args.first)
end

 Mara.configure('test') do |config|
  config.dynamodb.table_name = 'mara_test'
  config.dynamodb.endpoint = 'http://127.0.0.1:8000'
end

Dir.glob(Pathname.new(__dir__).join('support', '**', '*.rb')).each { |f| require f }
