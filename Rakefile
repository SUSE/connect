$LOAD_PATH << 'lib'
require 'suse/connect'
require 'rspec/core/rake_task'

task :default => [:spec, :rubocop]

desc 'Run console loaded with gem'
task :console do
  require 'irb'
  ARGV.clear
  IRB.start
end

desc 'Run Rubocop'
task :rubocop do
  sh 'bundle exec rubocop -c .rubocop.yml'
end

desc 'Increase version of a gem'
task :bump do
  sh 'gem bump --no-commit'
end

desc 'Run RSpec'
RSpec::Core::RakeTask.new(:spec)

desc 'Build locally (prepare for pushing to ibs)'
task :build => [:default] do

  def gemfilename
    "suse-connect-#{SUSE::Connect::VERSION}.gem"
  end

  sh 'rm *gem' if Dir['*.gem'].any?
  sh 'rm package/*gem' if Dir['package/*.gem'].any?
  sh 'gem build suse-connect.gemspec'
  sh "mv #{gemfilename} package/"
  Dir.chdir('package')
  sh "gem2rpm -l -o SUSEConnect.spec -t SUSEConnect.spec.erb #{gemfilename}"
  sh 'ronn --roff --manual SUSEConnect --pipe ../README.md > SUSEConnect.1 && gzip -f SUSEConnect.1'
  sh 'osc -A https://api.suse.de build SLE_12 x86_64 --no-verify'

end

require_relative 'jenkins/cloud_vm.rb'

namespace :cloud do
  namespace :vm do
    desc 'Creates and starts new VM instance on cloud.suse.de; Optional parameter: name'
    task :create, :name do |t, args|
      args.has_key?(:name) ? Cloud::VM.create(args[:name]) : Cloud::VM.create
    end

    desc 'Terminate VM instance on cloud.suse.de; Required parameter: name'
    task :terminate, :name do |t, args|
      if args.has_key?(:name)
        Cloud::VM.destroy(args[:name])
      else
        puts 'Please specify the name of the virtual machine'
      end
    end
  end
end
