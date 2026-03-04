pipeline {
    agent any

    environment {
        IMAGE_NAME = "database"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

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
                docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                '''
            }
        }

        stage('Security Scan') {
            agent {
                docker {
                    image 'aquasec/trivy:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh 'trivy image $IMAGE_NAME:${BUILD_NUMBER}'
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
                    docker tag $IMAGE_NAME:${BUILD_NUMBER} $DOCKER_USER/$IMAGE_NAME:${BUILD_NUMBER}
                    docker push $DOCKER_USER/$IMAGE_NAME:${BUILD_NUMBER}
                    '''
                }
            }
        }
    }
}
