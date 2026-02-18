pipeline {
    agent any

    environment {
        IMAGE_NAME = "database"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

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
            steps {
                sh '''
                trivy image --exit-code 1 --severity HIGH ${IMAGE_NAME}:${BUILD_NUMBER}
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
                    docker tag database:${BUILD_NUMBER} $DOCKER_USER/database:${BUILD_NUMBER}
                    docker push $DOCKER_USER/database:${BUILD_NUMBER}
                    '''
                }
            }
        }
    }
}
