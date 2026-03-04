pipeline {
  agent any

  environment {
    IMAGE_TAG = "${BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Decide Tag') {
      steps {
        script {
          // main gets a stable tag; everything else can use build number
          if (env.BRANCH_NAME == 'main') {
            env.IMAGE_TAG = "prod-${BUILD_NUMBER}"
          } else if (env.BRANCH_NAME == 'develop') {
            env.IMAGE_TAG = "dev-${BUILD_NUMBER}"
          } else {
            env.IMAGE_TAG = "ci-${BUILD_NUMBER}"
          }
        }
      }
    }

    stage('Build (all services)') {
      steps {
        sh '''
          docker compose build
        '''
      }
    }

    stage('Security Scan (all images)') {
      steps {
        sh '''
          docker pull aquasec/trivy:latest
          for img in database product-service order-service ecommerce-frontend; do
            docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
              aquasec/trivy:latest image "${DOCKER_USER}/${img}:${IMAGE_TAG}" || exit 1
          done
        '''
      }
    }

    stage('Push (develop/main/release only)') {
      when {
        anyOf {
          branch 'develop'
          branch 'main'
          branch pattern: "release/.*", comparator: "REGEXP"
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

            export DOCKER_USER="$DOCKER_USER"
            export IMAGE_TAG="$IMAGE_TAG"

            # This pushes every service image defined in docker-compose.yml
            docker compose push
          '''
        }
      }
    }

    stage('Deploy Dev') {
      when { branch 'develop' }
      steps {
        sh '''
          export IMAGE_TAG="$IMAGE_TAG"
          docker compose pull
          docker compose up -d
        '''
      }
    }

    stage('Deploy Prod') {
      when { branch 'main' }
      steps {
        sh '''
          export IMAGE_TAG="$IMAGE_TAG"
          docker compose pull
          docker compose up -d
        '''
      }
    }
  }
}