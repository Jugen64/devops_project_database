pipeline {
  agent any

  environment {
    IMAGE = "database:${BUILD_NUMBER}"
    DOCKER_REPO = "database"
  }

  stages {

    stage('Sanity') {
      steps {
        sh '''
          which docker
          docker --version
          ls -la /var/run/docker.sock || true
        '''
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Container Build') {
      steps {
        sh 'docker build -t "$IMAGE" .'
      }
    }

    stage('Security Scan') {
      steps {
        sh '''
          docker pull aquasec/trivy:latest
          docker run --rm \
            -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy:latest image "$IMAGE"
        '''
      }
    }

    stage('Container Push') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh '''
            set -e

            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

            docker tag "$IMAGE" "$DOCKER_USER/$DOCKER_REPO:${BUILD_NUMBER}"
            docker push "$DOCKER_USER/$DOCKER_REPO:${BUILD_NUMBER}"

            docker tag "$IMAGE" "$DOCKER_USER/$DOCKER_REPO:latest"
            docker push "$DOCKER_USER/$DOCKER_REPO:latest"
          '''
        }
      }
    }
  }
}