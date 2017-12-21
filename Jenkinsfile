#!groovy

node('scc-connect') {

  stage('checkout') {
     git 'git@github.com:SUSE/connect.git'
  }

  ansiColor('xterm') {

    stage('build docker images') {
      parallel (
        buildga: { sh 'docker build -t connect.ga -f Dockerfile .' },
        buildsp1: { sh 'docker build -t connect.sp1 -f Dockerfile.sp1 .' },
        buildsp2: { sh 'docker build -t connect.sp2 -f Dockerfile.sp2 .' },
        buildsp3: { sh 'docker build -t connect.sp3 -f Dockerfile.sp3 .' }
      )
    }

    stage('unit tests') {
      parallel (
        rubocop: { sh 'docker run --rm -t connect.ga su nobody -c rubocop' },
        rspec: { sh 'docker run --rm -t connect.ga su nobody -c rspec' }
      )
    }

    // Remove untagged (prior) docker images
    // docker rmi $(docker images | grep "^<none>" | awk "{print $3}")

    stage('integration tests') {
      parallel (
        testga: { sh 'docker run -e "PRODUCT=SLE_12" -v /space/oscbuild:/oscbuild --privileged --rm -t connect.ga ./docker/integration.sh' },
        testsp1: { sh 'docker run -e "PRODUCT=SLE_12_SP1" -v /space/oscbuild:/oscbuild --privileged --rm -t connect.sp1 ./docker/integration.sh' },
        testsp2: { sh 'docker run -e "PRODUCT=SLE_12_SP2" -v /space/oscbuild:/oscbuild --privileged --rm -t connect.sp2 ./docker/integration.sh' },
        testsp3: { sh 'docker run -e "PRODUCT=SLE_12_SP3" -v /space/oscbuild:/oscbuild --privileged --rm -t connect.sp3 ./docker/integration.sh' }
      )
    }
  }
}
