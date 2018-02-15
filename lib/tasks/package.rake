require 'tempfile'
require 'English'

def version_from_spec(spec_glob)
  version = `grep '^Version:' #{spec_glob}`
  version[/(\d\.\d\.\d)/, 0]
end

def upstream_file(name, file_type, obs_project, package_name)
  file = Tempfile.new(name.to_s)
  file.close
  `osc -A 'https://api.opensuse.org' cat '#{obs_project}' '#{package_name}' '#{package_name}#{file_type}' > #{file.path}`
  file
end

namespace :package do
  package_dir = 'package/'
  package_name = 'SUSEConnect'
  obs_project = 'systemsmanagement:SCC'
  local_spec_file = "#{package_name}.spec"
  root_path = File.join(File.dirname(__FILE__), '../..')

  desc 'Check local checkout for uncommitted changes'
  task :check_git do
    modified = `git ls-files -m --exclude-standard .`
    if modified.empty?
      puts 'No uncommitted changes detected.'
    else
      raise "Warning: uncommitted changes!\n\n#{modified}\n"
    end
  end

  desc 'Checkout from OBS'
  task :checkout do
    Dir.chdir "#{root_path}/#{package_dir}"
    unless Dir['.osc'].any?
      sh 'mkdir .tmp; mv * .tmp/'
      sh "osc co #{obs_project} #{package_name} -o ."
      puts 'Checkout successful.' if $CHILD_STATUS.exitstatus.zero?
    end
    `rm *suse-connect-*.gem` if Dir['*.gem'].any?
    Dir.chdir '..'
  end

  desc 'Build gem and copy to package'
  task :build_gem do
    Dir.chdir root_path.to_s
    gemfilename = "suse-connect-#{SUSE::Connect::VERSION}.gem"

    `rm suse-connect-*.gem` if Dir['*.gem'].any?
    `gem build suse-connect.gemspec`

    raise 'Gem build failed.' unless $CHILD_STATUS.exitstatus.zero?

    sh "cp #{gemfilename} #{package_dir}"
    puts "Gem built and copied to #{package_dir}." if $CHILD_STATUS.exitstatus.zero?
  end

  desc 'Generate man pages'
  task :generate_manpages do
    Dir.chdir root_path.to_s
    sh 'ronn --roff --manual SUSEConnect --pipe SUSEConnect.8.ronn > package/SUSEConnect.8'
    sh 'ronn --roff --manual SUSEConnect --pipe SUSEConnect.5.ronn > package/SUSEConnect.5'
  end

  desc 'Check for changelog update'
  task :changelog do
    Dir.chdir "#{root_path}/#{package_dir}"
    file = upstream_file('connect-changes-rake', '.changes', obs_project, package_name)
    if FileUtils.compare_file("#{package_name}.changes", file.path)
      raise 'Upstream changelog identical. Please run `osc vc` to log new changes.'
    elsif !IO.read("#{package_name}.changes").include? "Update to #{SUSE::Connect::VERSION}"
      raise 'Please run `osc vc` to add changelog about version bump.'
    else
      modified = `osc status | grep -Po 'M\s+SUSEConnect\.changes'`
      puts 'Changelog updated.' if modified
    end
    Dir.chdir '..'
  end

  desc 'Check for version bump in specfile'
  task :check_specfile_version do
    Dir.chdir "#{root_path}/#{package_dir}"
    file = upstream_file('connect-spec-rake', '.spec', obs_project, package_name)
    original_version = version_from_spec(file.path)
    new_version      = version_from_spec(local_spec_file)

    if new_version == original_version
      raise "Version in #{package_name}.spec not changed. Please change to the latest version before committing.\n"
    else
      puts "Version change to #{new_version} in #{package_name}.spec detected."
    end
  end

  desc 'Prepare package for checking in to OBS'
  task :prepare do
    puts '== Step 1: check for uncommitted changes'
    Rake::Task['package:check_git'].invoke
    ##
    puts '== Step 2: Checkout from OBS'
    Rake::Task['package:checkout'].invoke
    ##
    puts '== Step 3: Build gem and copy to package'
    Rake::Task['package:build_gem'].invoke
    ##
    puts '== Step 4: Generate man pages'
    Rake::Task['package:generate_manpages'].invoke
    ##
    puts "== Step 5: Check changelog update in #{package_name}.changes"
    Rake::Task['package:changelog'].invoke
    ##
    puts '== Step 6: check for version bump in specfile'
    Rake::Task['package:check_specfile_version'].invoke
    ##
    puts 'Package preparation complete. Run `osc ar` to add changes and `osc ci` to check in package to OBS.'
    sh 'osc status'
  end
end
