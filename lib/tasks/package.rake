$LOAD_PATH << 'lib'
require 'suse/connect'
require 'tempfile'


def version_from_spec (spec_glob)
  version = `grep '^Version:' #{spec_glob}`
  version.sub!(/^Version:\s*/, "")
  version.sub!(/#.*$/, "")
  version.strip!
  version
end

package_dir = 'package/'
package_name = 'SUSEConnect'
obs_project = 'systemsmanagement:SCC'
local_spec_file = "#{package_name}.spec"

task default: :prepare

desc 'Prepare package for checking in to IBS'
task :prepare do
  puts ">> #{package_name} is now at #{SUSE::Connect::VERSION} <<"

  ###
  puts '== Step 1: check for uncommitted changes'
  modified = `git ls-files -m --exclude-standard .`
  if ! modified.empty?
    raise "Warning: uncommitted changes!\n#{modified}"
  else
    puts 'No uncommitted changes detected.'
  end
  sleep 1

  ###
  puts '== Step 2: Build gem and copy to package'
  gemfilename = "suse-connect-#{SUSE::Connect::VERSION}.gem"

  `rm *.gem` if Dir['*.gem'].any?
  `gem build suse-connect.gemspec`

  raise 'Gem build failed.' unless $?.exitstatus.zero?

  Dir.chdir "#{package_dir}"
  sh "cp ../#{gemfilename} ."
  puts "Gem built and copied to #{package_dir}." if $?.exitstatus.zero?
  sleep 1

  ###
  puts '== Step 3: change to package dir and checkout from IBS =='
  unless Dir['.osc'].any?
    sh 'mkdir .tmp; mv * .tmp/'
    sh "osc co #{obs_project} #{package_name} -o ."
    sh 'mv .tmp/* .; rm -r .tmp/'
    puts 'Checkout successful.' if $?.exitstatus.zero?
    sleep 1
  end

  ####
  puts '== Step 4: Generate man pages'
  sh 'ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.8.ronn > SUSEConnect.8'
  sh 'ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.5.ronn > SUSEConnect.5'
  sleep 1

  ###
  puts "== Step 5: Log changes to #{package_name}.changes"
  sh 'osc vc'
  sleep 1

  ###
  puts '== Step 6: check for version bump in specfile'
  begin
    file = Tempfile.new('connect-spec-rake')
    file.close
    `osc -A 'https://api.opensuse.org' cat '#{obs_project}' '#{package_name}' '#{package_name}.spec' > #{file.path}`
    original_version = version_from_spec(file.path)
    new_version      = version_from_spec(local_spec_file)

    if new_version == original_version
      raise "Please change version to #{SUSE::Connect::VERSION} in #{package_name}.spec and commit before continuing.\n"
    else
      puts "Version change to #{new_version} in #{package_name}.spec detected."
    end
  ensure
    file.unlink if file
    sleep 1
  end

  puts 'Package preparation complete. Run `osc ci` to check in package.'
end
