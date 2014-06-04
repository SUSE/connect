$LOAD_PATH << 'lib'
require 'suse/connect'
require 'rspec/core/rake_task'

task :default => [:spec, :rubocop]

desc 'Run RSpec'
RSpec::Core::RakeTask.new(:spec)

desc 'Run console loaded with gem'
task :console do
  require 'irb'
  ARGV.clear
  IRB.start
end

desc 'Run Rubocop'
task :rubocop do
  sh 'bundle exec rubocop -c rubocop.yml'
end

desc 'Increase version of a gem'
task :bump do
  sh 'gem bump --no-commit'
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
  sh "gem2rpm -l -s -o SUSEConnect.spec -t SUSEConnect.spec.erb #{gemfilename}"
  sh 'ronn --roff --manual SUSEConnect --pipe SUSEConnect.8.ronn > SUSEConnect.8 && gzip -f SUSEConnect.8'
  sh 'ronn --roff --manual SUSEConnect --pipe SUSEConnect.5.ronn > SUSEConnect.5 && gzip -f SUSEConnect.5'
  sh 'osc -A https://api.suse.de build SLE_12 x86_64 --no-verify'

end
