#!groovy

node('scc-jenkins-node-connect') {

  stage('checkout') {
     git 'git@github.com:SUSE/connect.git'
  }

  ansiColor('xterm') {

    stage('build docker images') {
      sh 'docker build -t connect -f Dockerfile .'
      sh 'docker build -t connect.sp1 -f Dockerfile.sp1 .'
      sh 'docker build -t connect.sp2 -f Dockerfile.sp2 .'
    }

    # Remove untagged (prior) docker images
    #docker rmi $(docker images | grep "^<none>" | awk "{print $3}")

  }

}
