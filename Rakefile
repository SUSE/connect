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

  def gemfilename
    "suse-connect-#{SUSE::Connect::VERSION}.gem"
  end

  sh 'rm *.gem' if Dir['*.gem'].any?
  sh 'gem build suse-connect.gemspec'
  %w(ibs obs).each do |build_service|
    sh "rm package_#{build_service}/*.gem" if Dir["package_#{build_service}/*.gem"].any?
    sh "cp #{gemfilename} ./package_#{build_service}/"
    Dir.chdir "package_#{build_service}"
    sh 'ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.8.ronn > SUSEConnect.8 && gzip -f SUSEConnect.8'
    sh 'ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.5.ronn > SUSEConnect.5 && gzip -f SUSEConnect.5'
    sh "osc build #{args[:product]} x86_64 --no-verify --trust-all-projects"
    Dir.chdir '..'
  end
end

namespace :vm do
  desc 'Ssh into virtual machine'
  task :ssh, :ip do |_t, args|
    system("echo -e | ssh vagrant@#{args[:args]}")
  end

  namespace :remotefs do
    desc 'Mount remote connect source code'
    task :mount, :ip do |_t, args|
      if args[:ip]
        options = '-o password_stdin -o uid=$(id -u) -o gid=$(id -g) -o auto_unmount'
        system "echo vagrant | sshfs vagrant@#{args[:ip]}:/tmp/connect /tmp/remotefs #{options}"
      else
        puts 'ERROR: Missing VM IP address'
      end
    end

    desc 'Umount remote connect source code'
    task :umount do
      system('sudo umount /tmp/remotefs')
    end
  end
end
