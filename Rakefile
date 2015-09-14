$LOAD_PATH << 'lib'
require 'suse/connect'
require 'rspec/core/rake_task'
require 'date'

task :default => [:spec, :rubocop]

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

desc 'Build locally (prepare for pushing to ibs)'
task :build do
  def gemfilename
    "suse-connect-#{SUSE::Connect::VERSION}.gem"
  end

  sh 'rm *.gem' if Dir['*.gem'].any?
  sh 'rm package/*.gem' if Dir['package/*.gem'].any?
  sh 'gem build suse-connect.gemspec'
  sh "mv #{gemfilename} package/"
  Dir.chdir('package')
  # NB this requires rubygem-gem2rpm from devel:languages:ruby:extensions in OBS, or SLE12 for the --config support
  sh "/usr/bin/gem2rpm --config gem2rpm.yml -l -o SUSEConnect.spec -t /usr/share/doc/packages/ruby2.1-rubygem-gem2rpm/sles12.spec.erb #{gemfilename}"
  sh 'ronn --roff --manual SUSEConnect --pipe SUSEConnect.8.ronn > SUSEConnect.8 && gzip -f SUSEConnect.8'
  sh 'ronn --roff --manual SUSEConnect --pipe SUSEConnect.5.ronn > SUSEConnect.5 && gzip -f SUSEConnect.5'
  sh 'osc -A https://api.suse.de build SLE_12 x86_64 --no-verify'
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
