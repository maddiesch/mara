require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :docs do
  desc 'Generate docs'
  task :generate do
    YARD::CLI::Yardoc.run
  end

  desc 'Get docs stats'
  task :stats do
    YARD::CLI::Stats.run('--list-undoc')
  end

  desc 'View docs'
  task :view do
    # Viewing should always generate the freshest
    Rake::Task['docs:generate'].invoke
    exec("open #{File.expand_path('./doc/index.html', __dir__)}")
  end
end
