pipeline {
    agent any

    environment {
        IMAGE_NAME = "database"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Sanity') {
            steps {
                sh 'which docker || true; docker --version || true; ls -la /var/run/docker.sock || true'
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Container Build') {
            steps {
                sh '''
                docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                '''
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


        stage('Container Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} $DOCKER_USER/${IMAGE_NAME}:latest
                    docker push $DOCKER_USER/${IMAGE_NAME}:latest
                    '''
                }
            }
        }
    }
}