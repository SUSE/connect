FROM registry.scc.suse.de/sles12_base

RUN zypper --non-interactive ar http://download.suse.de/ibs/SUSE:/SLE-12:/GA/standard/ SLE-12-standard &&\
    zypper --non-interactive --gpg-auto-import-keys ref &&\
    zypper --no-gpg-checks --non-interactive install git-core ruby-devel make gcc gcc-c++ build wget dmidecode

RUN wget http://username:password@gaffer.suse.de:9999/files/.regcode -O /root/.regcode

RUN rm /etc/gemrc && \
    gem install bundler --no-document
RUN mkdir /tmp/connect && mkdir -p /tmp/connect/lib/suse/connect
ADD Gemfile /tmp/connect/
ADD suse-connect.gemspec /tmp/connect/
ADD lib/suse/connect/version.rb /tmp/connect/lib/suse/connect/
WORKDIR /tmp/connect
RUN bundle -j8
ADD . /tmp/connect
RUN chown nobody /tmp/connect/coverage
