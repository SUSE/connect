$LOAD_PATH << 'lib'
require 'suse/connect'
require 'tempfile'
require 'English'

def check_git
  modified = `git ls-files -m --exclude-standard .`
  if !modified.empty?
    raise "Warning: uncommitted changes!\n\n#{modified}\n"
  else
    puts 'No uncommitted changes detected.'
  end
end

def build_gem(package_dir)
  gemfilename = "suse-connect-#{SUSE::Connect::VERSION}.gem"

  `rm *.gem` if Dir['*.gem'].any?
  `gem build suse-connect.gemspec`

  raise 'Gem build failed.' unless $CHILD_STATUS.exitstatus.zero?

  Dir.chdir "#{package_dir}"
  sh "cp ../#{gemfilename} ."
  puts "Gem built and copied to #{package_dir}." if $CHILD_STATUS.exitstatus.zero?
end

def checkout_package(obs_project, package_name)
  unless Dir['.osc'].any?
    sh 'mkdir .tmp; mv * .tmp/'
    sh "osc co #{obs_project} #{package_name} -o ."
    sh 'mv .tmp/* .; rm -r .tmp/'
    puts 'Checkout successful.' if $CHILD_STATUS.exitstatus.zero?
  end
end

def check_specfile_version(obs_project, package_name)
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
  end
end

def version_from_spec(spec_glob)
  version = `grep '^Version:' #{spec_glob}`
  version.sub!(/^Version:\s*/, '')
  version.sub!(/#.*$/, '')
  version.strip!
  version
end

desc 'Prepare package for checking in to IBS'
task :prepare do
  package_dir = 'package/'
  package_name = 'SUSEConnect'
  obs_project = 'systemsmanagement:SCC'
  local_spec_file = "#{package_name}.spec"

  puts ">> #{package_name} is now at #{SUSE::Connect::VERSION} <<"

  ###
  puts '== Step 1: check for uncommitted changes'
  check_git
  sleep 1

  ###
  puts '== Step 2: Build gem and copy to package'
  build_gem(package_dir)
  sleep 1

  ###
  puts '== Step 3: change to package dir and checkout from IBS =='
  checkout_package(obs_project, package_name)
  sleep 1

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
  check_specfile_version(obs_project, package_name)
  sleep 1

  puts 'Package preparation complete. Run `osc ci` to check in package.'
end
