$LOAD_PATH << 'lib'
require 'suse/connect'
require 'rspec/core/rake_task'
require 'date'


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

# SLE_12, SLE_12_SP1, and SLE_12_SP2 valid products for testing; use 'osc repos' in package dir to check others.
desc 'Build locally (prepare for pushing to ibs)'
task :build, [:product] do |t, args|

  gemfilename = "suse-connect-#{SUSE::Connect::VERSION}.gem"
  sh 'rm *.gem' if Dir['*.gem'].any?
  sh 'gem build suse-connect.gemspec'

  Dir.chdir 'package'
  unless Dir['.osc'].any?
    sh 'mkdir .tmp; mv * .tmp/'
    sh 'osc co systemsmanagement:SCC SUSEConnect -o .'
    sh 'mv .tmp/* .; rm -r .tmp/'
  end
  sh "cp ../#{gemfilename} ."
  sh 'ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.8.ronn > SUSEConnect.8 && gzip -f SUSEConnect.8'
  sh 'ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.5.ronn > SUSEConnect.5 && gzip -f SUSEConnect.5'
  sh "osc build #{args[:product]} x86_64 --no-verify --trust-all-projects"
  Dir.chdir '..'
end
