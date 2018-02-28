#!groovy

node('scc-connect') {

  stage('checkout') {
    git 'git@github.com:SUSE/connect.git'
  }

  ansiColor('xterm') {

    stage('build docker images') {
      parallel (
        build12sp0: { sh 'docker build -t connect.12sp0 -f Dockerfile.12sp0 .' },
        build12sp1: { sh 'docker build -t connect.12sp1 -f Dockerfile.12sp1 .' },
        build12sp2: { sh 'docker build -t connect.12sp2 -f Dockerfile.12sp2 .' },
        build12sp3: { sh 'docker build -t connect.12sp3 -f Dockerfile.12sp3 .' }
        build15sp0: { sh 'docker build -t connect.15sp0 -f Dockerfile.15sp0 .' }
      )
    }

    stage('unit tests') {
      parallel (
        rubocop: { sh 'docker run --rm -t connect.12sp0 rubocop' },
        rspec_ruby21: { sh 'docker run --rm -t connect.12sp0 rspec' }
        rspec_ruby25: { sh 'docker run --rm -t connect.15sp0 rspec' }
      )
    }

    stage('integration tests') {
      parallel (
        test12sp0: { sh 'docker run -e "PRODUCT=SLE_12" -v /space/oscbuild:/oscbuild --privileged --rm -t connect.12sp0 ./docker/integration.sh' },
        test12sp1: { sh 'docker run -e "PRODUCT=SLE_12_SP1" -v /space/oscbuild:/oscbuild --privileged --rm -t connect.12sp1 ./docker/integration.sh' },
        test12sp2: { sh 'docker run -e "PRODUCT=SLE_12_SP2" -v /space/oscbuild:/oscbuild --privileged --rm -t connect.12sp2 ./docker/integration.sh' },
        test12sp3: { sh 'docker run -e "PRODUCT=SLE_12_SP3" -v /space/oscbuild:/oscbuild --privileged --rm -t connect.12sp3 ./docker/integration.sh' }
        // TODO: Connect and integration tests need to be adapted to SLES 15.
        // test15sp0: { sh 'docker run -e "PRODUCT=SLE_15" -v /space/oscbuild:/oscbuild --privileged --rm -t connect.15sp0 ./docker/integration.sh' }
      )
    }

    stage('Clean up docker') {
      sh 'docker system prune -f'
    }
  }
}
