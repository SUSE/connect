FROM registry.scc.suse.de/suse/sles15:ga-rc1
ENV PRODUCT SLE_15
ENV BUILT_AT "Wed Feb 21 15:32 CET 2018"

RUN useradd --no-log-init --create-home scc

# Remember to drop docker caches if any of these change
RUN zypper ar http://download.suse.de/ibs/SUSE:/SLE-15:/GA/standard/ sles-pool &&\
    zypper ar http://download.suse.de/ibs/SUSE:/SLE-15:/Update/standard/ sles-updates &&\
    zypper --non-interactive --gpg-auto-import-keys ref &&\
    zypper --non-interactive up zypper &&\
    zypper --non-interactive install git-core ruby-devel make gcc gcc-c++ build wget dmidecode \
      vim osc hwinfo libx86emu1 zypper-migration-plugin sudo awk &&\
    zypper --non-interactive rr sles-pool sles-updates

RUN wget http://username:password@gaffer.suse.de:9999/files/.regcode -O ~/.regcode
RUN wget http://username:password@gaffer.suse.de:9999/files/.oscrc -O ~/.oscrc

RUN echo 'gem: --no-ri --no-rdoc' > /etc/gemrc && \
    gem install bundler --no-document

RUN mkdir /tmp/connect && mkdir -p /tmp/connect/lib/suse/connect
WORKDIR /tmp/connect

ADD Gemfile .
ADD suse-connect.gemspec .
ADD lib/suse/connect/version.rb ./lib/suse/connect/
RUN bundle config jobs $(nproc) && \
    bundle install
ADD . /tmp/connect
RUN chown -R scc /tmp/connect
