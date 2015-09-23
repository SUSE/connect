[![Build Status](https://secure.travis-ci.org/SUSE/connect.png?branch=master)](https://travis-ci.org/SUSE/connect)
[![Code Climate](https://codeclimate.com/github/SUSE/connect.png)](https://codeclimate.com/github/SUSE/connect)
[![Coverage Status](https://coveralls.io/repos/SUSE/connect/badge.png?branch=master)](https://coveralls.io/r/SUSE/connect)

#SUSEConnect

is a command line tool for connecting a client system to the SUSE Customer Center.
It will connect the system to your product subscriptions and enable the product repositories/services locally.

Please visit https://scc.suse.com to see and manage your subscriptions.

# Rake tasks

NOTE: If you are using RVM/Chruby/rbenv - make sure you installed gem2rpm as the package to the system itself and
using it for `rake build`

```
rake build    # build locally (prepare for pushing to ibs)
rake bump     # increase version of a gem
rake console  # Run console loaded with gem
rake rubocop  # Run Rubocop
rake spec     # Run RSpec
```

# Docker usage

Build an image (and everytime to change code)

* `docker build -t connect .`

Run RSpec 

* `docker run --privileged --rm -t connect su nobody -c rspec`

Run Cucumber 

* `docker run --privileged --rm -t connect cucumber`

Run Rubocop 

* `docker run --privileged --rm -t connect su nobody -c rubocop`

Or run whole set of tests together 

* `docker run --privileged --rm -t connect sh docker/runall.sh`
