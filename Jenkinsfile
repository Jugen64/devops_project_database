pipeline {
  agent any

  options { skipDefaultCheckout(true) }

  environment {
    IMAGE_NAME = "database"
    IMAGE_TAG  = "${BUILD_NUMBER}"
  }

  stages {

    stage('Sanity') {
      steps {
        sh 'which docker || true; docker --version || true; ls -la /var/run/docker.sock || true'
      }
    }

    stage('Checkout') {
      steps {
        deleteDir()
        checkout scm
      }
    }

    // --- BUILD (all branches + PRs) ---
    stage('Container Build') {
      steps {
        sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
      }
    }

    stage('Security Scan') {
      steps {
        sh '''
          docker pull aquasec/trivy:latest
          docker run --rm \
            -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy:latest image ${IMAGE_NAME}:${IMAGE_TAG}
        '''
      }
    }

    // --- DEV: develop branch (auto) ---
    stage('Push (Dev)') {
      when {
        allOf {
          branch 'develop'
          not { changeRequest() }
        }
      }
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker tag ${IMAGE_NAME}:${IMAGE_TAG} $DOCKER_USER/${IMAGE_NAME}:dev-${IMAGE_TAG}
            docker push $DOCKER_USER/${IMAGE_NAME}:dev-${IMAGE_TAG}
          '''
        }
      }
    }

    // --- STAGING: release/* branches (auto) ---
    stage('Push (Staging)') {
      when {
        allOf {
          expression { env.BRANCH_NAME ==~ /^release\\/.*$/ }
          not { changeRequest() }
        }
      }
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker tag ${IMAGE_NAME}:${IMAGE_TAG} $DOCKER_USER/${IMAGE_NAME}:rc-${IMAGE_TAG}
            docker push $DOCKER_USER/${IMAGE_NAME}:rc-${IMAGE_TAG}
          '''
        }
      }
    }

    // --- PROD: main branch (manual approval) ---
    stage('Approve Prod') {
      when {
        allOf {
          branch 'main'
          not { changeRequest() }
        }
      }
      steps {
        input message: "Deploy to PROD? (push ${IMAGE_NAME}:${IMAGE_TAG})", ok: "Approve"
      }
    }

    stage('Push (Prod)') {
      when {
        allOf {
          branch 'main'
          not { changeRequest() }
        }
      }
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker tag ${IMAGE_NAME}:${IMAGE_TAG} $DOCKER_USER/${IMAGE_NAME}:prod-${IMAGE_TAG}
            docker tag ${IMAGE_NAME}:${IMAGE_TAG} $DOCKER_USER/${IMAGE_NAME}:latest
            docker push $DOCKER_USER/${IMAGE_NAME}:prod-${IMAGE_TAG}
            docker push $DOCKER_USER/${IMAGE_NAME}:latest
          '''
        }
      }
    }
  }

  post {
    always {
      // optional cleanup so your Jenkins box doesn't fill up
      sh 'docker image prune -f || true'
    }
  }
}