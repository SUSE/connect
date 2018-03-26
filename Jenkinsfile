pipeline {
  agent { label "scc-connect" }

  options {
    ansiColor('xterm')
  }

  stages {
    stage('Checkout') {
      steps {
        git 'git@github.com:SUSE/connect.git'
      }
    }

    stage('Run tests on supported SLE versions') {
      parallel {
        // stage('SLE12 SP0') {
        //   steps {
        //     sh 'docker build -t connect.12sp0 -f Dockerfile.12sp0 .'
        //     sh 'docker run --rm -t connect.12sp0 rubocop'
        //     sh 'docker run --rm -t connect.12sp0 rspec'
        //     sh 'docker run -v /space/oscbuild:/oscbuild --privileged --rm -t connect.12sp0 ./docker/integration.sh'
        //   }
        // }
        //
        // stage('SLE12 SP1') {
        //   steps {
        //     sh 'docker build -t connect.12sp1 -f Dockerfile.12sp1 .'
        //     sh 'docker run -v /space/oscbuild:/oscbuild --privileged --rm -t connect.12sp1 ./docker/integration.sh'
        //   }
        // }
        //
        // stage('SLE12 SP2') {
        //   steps {
        //     sh 'docker build -t connect.12sp2 -f Dockerfile.12sp2 .'
        //     sh 'docker run -v /space/oscbuild:/oscbuild --privileged --rm -t connect.12sp2 ./docker/integration.sh'
        //   }
        // }
        //
        // stage('SLE12 SP3') {
        //   steps {
        //     sh 'docker build -t connect.12sp3 -f Dockerfile.12sp3 .'
        //     sh 'docker run -v /space/oscbuild:/oscbuild --privileged --rm -t connect.12sp3 ./docker/integration.sh'
        //   }
        // }

        stage('SLE15 SP0') {
          steps {
            sh 'docker build -t connect.15sp0 -f Dockerfile.15sp0 .'
            sh 'docker run --rm -t connect.15sp0 rspec'
            sh 'docker run -v /space/oscbuild:/oscbuild --privileged --name connect-15sp0-$BUILD_NUMBER -t connect.15sp0 ./docker/integration.sh'
          }
        }
      }
    }
  }

  post {
    always {
      sh 'docker system prune -f'
    }
  }
}
