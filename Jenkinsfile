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
        stage('SLE12 SP2') {
          steps {
            sh 'docker build --build-arg OBS_USER=$OBS_USER --build-arg OBS_PASSWORD=$OBS_PASSWORD -t connect.12sp2 -f Dockerfile.12sp2 .'
            sh 'docker run -e VALID_REGCODE=$VALID_REGCODE -e EXPIRED_REGCODE=$EXPIRED_REGCODE -e NOT_ACTIVATED_REGCODE=$NOT_ACTIVATED_REGCODE -v /space/oscbuild:/oscbuild --privileged --rm -t connect.12sp2 ./docker/integration.sh'
          }
        }

        stage('SLE12 SP3') {
          steps {
            sh 'docker build --build-arg OBS_USER=$OBS_USER --build-arg OBS_PASSWORD=$OBS_PASSWORD -t connect.12sp3 -f Dockerfile.12sp3 .'
            sh 'docker run -e VALID_REGCODE=$VALID_REGCODE -e EXPIRED_REGCODE=$EXPIRED_REGCODE -e NOT_ACTIVATED_REGCODE=$NOT_ACTIVATED_REGCODE -v /space/oscbuild:/oscbuild --privileged --rm -t connect.12sp3 ./docker/integration.sh'
          }
        }

        stage('SLE15 SP0') {
          steps {
            sh 'docker build --build-arg OBS_USER=$OBS_USER --build-arg OBS_PASSWORD=$OBS_PASSWORD -t connect.15sp0 -f Dockerfile.15sp0 .'
            sh 'docker run --rm -t connect.15sp0 rspec'
            sh 'docker run -e VALID_REGCODE=$VALID_REGCODE -e EXPIRED_REGCODE=$EXPIRED_REGCODE -e NOT_ACTIVATED_REGCODE=$NOT_ACTIVATED_REGCODE -v /space/oscbuild:/oscbuild --privileged --rm -t connect.15sp0 ./docker/integration.sh'
          }
        }

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
