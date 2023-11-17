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
        stage('SLE15 SP3') {
          steps {
            sh 'docker build --build-arg OBS_USER=$OBS_USER --build-arg OBS_PASSWORD=$OBS_PASSWORD -t connect.15sp3 -f Dockerfile.15sp3 .'
            sh 'docker run --rm -t connect.15sp3 rspec'
            sh 'docker run -e VALID_REGCODE=$VALID_REGCODE -e EXPIRED_REGCODE=$EXPIRED_REGCODE -e NOT_ACTIVATED_REGCODE=$NOT_ACTIVATED_REGCODE -v /space/oscbuild:/oscbuild --privileged --rm -t connect.15sp3 ./docker/integration.sh'
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
