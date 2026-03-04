pipeline {
    agent any

    environment {
        IMAGE = "database:${BUILD_NUMBER}"
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
                sh 'docker build -t $IMAGE .'
            }
        }

        stage('Security Scan') {
            steps {
                sh '''
                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        aquasec/trivy:latest image $IMAGE
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
                        docker tag $IMAGE $DOCKER_USER/database:${BUILD_NUMBER}
                        docker push $DOCKER_USER/database:${BUILD_NUMBER}
                        '''
                }
            }
        }
    }
}
