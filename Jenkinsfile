#!groovy

node('scc-jenkins-node-connect') {

  stage('checkout') {
     git 'git@github.com:SUSE/connect.git'
  }

  ansiColor('xterm') {

    stage('unit tests')
    {
      sh 'bundle.ruby2.1 install --path vendor/bundle'
      sh 'bundle.ruby2.1 exec rspec'
    }

    stage('build docker images') {
      sh 'docker build -t connect -f Dockerfile .'
      sh 'docker build -t connect.sp1 -f Dockerfile.sp1 .'
      sh 'docker build -t connect.sp2 -f Dockerfile.sp2 .'
    }

    // Remove untagged (prior) docker images
    // docker rmi $(docker images | grep "^<none>" | awk "{print $3}")

    stage('integration tests')
    {
      sh 'docker run -e "PRODUCT=SLE_12" -v /space/oscbuild:/oscbuild --privileged --rm -t connect ./docker/integration.sh'
      sh 'docker run -e "PRODUCT=SLE_12_SP1" -v /space/oscbuild:/oscbuild --privileged --rm -t connect.sp1 ./docker/integration.sh'
      sh 'docker run -e "PRODUCT=SLE_12_SP2" -v /space/oscbuild:/oscbuild --privileged --rm -t connect.sp2 ./docker/integration.sh'
    }

  }

}
