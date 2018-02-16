$LOAD_PATH << 'lib'
require 'suse/connect'
require 'rspec/core/rake_task'
require 'date'

Dir.glob('lib/tasks/*.rake') { |f| load f }

# The last_comment method has been silently removed from Rake 11.0.1,
# then restored with a deprecation warning:
# https://github.com/ruby/rake/blob/v11.1.2/lib/rake/task_manager.rb#L9-L12
#
# We currently happen to use the affected 11.0.x versions in our build pipeline, so this is really needed.
module MonkeypatchRakeLastComment
  def last_comment
    last_description
  end
end
Rake::Application.send :include, MonkeypatchRakeLastComment unless Rake::Application.method_defined? :last_comment

task default: [:spec, :rubocop]

desc 'Run RSpec'
RSpec::Core::RakeTask.new(:spec)

desc 'Run console loaded with gem'
task :console do
  require 'irb'
  require 'irb/completion'
  require 'byebug'
  require 'awesome_print'
  require 'date'
  ARGV.clear
  IRB.start
end

desc 'Run Rubocop'
task :rubocop do
  sh 'bundle exec rubocop'
end
