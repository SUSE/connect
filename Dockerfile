FROM registry.scc.suse.de/sles12_base

RUN zypper --non-interactive ar http://download.suse.de/ibs/SUSE:/SLE-12:/GA/standard/ SLE-12-standard &&\
    zypper --non-interactive ar -f http://download.suse.de/ibs/SUSE:/SLE-12:/Update/standard/ SLE-12-update-standard &&\
    zypper --non-interactive ar -f http://download.opensuse.org/repositories/openSUSE:/Tools/SLE_12/ opensuse-tools && \
    zypper --non-interactive --gpg-auto-import-keys ref &&\
    zypper --no-gpg-checks --non-interactive install git-core ruby-devel make gcc gcc-c++ build wget dmidecode vim zypper>=1.11.32 osc ruby2.1-rubygem-gem2rpm

RUN wget http://username:password@gaffer.suse.de:9999/files/.regcode -O /root/.regcode
RUN wget --http-user=username --http-password=password http://gaffer.suse.de:9999/files/.oscrc -O /root/.oscrc

RUN echo 'gem: --no-ri --no-rdoc' > /etc/gemrc && \
    gem install bundler --no-document
RUN mkdir /tmp/connect && mkdir -p /tmp/connect/lib/suse/connect
ADD Gemfile /tmp/connect/
ADD suse-connect.gemspec /tmp/connect/
ADD lib/suse/connect/version.rb /tmp/connect/lib/suse/connect/
WORKDIR /tmp/connect
RUN bundle -j8
ADD . /tmp/connect
RUN chown -R nobody /tmp/connect
RUN chmod +x /tmp/connect/docker/runall.sh /tmp/connect/docker/integration.sh
