pipeline {
    agent any

    environment {
        IMAGE_NAME = "enterprise-webapp-jenkins:build-${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('DevOps/Docker_Projects/simple-webapp') {
                    sh '''
                    docker build -t $IMAGE_NAME .
                    '''
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                trivy image $IMAGE_NAME
                '''
            }
        }

        stage('Load Image Into kind') {
            steps {
                sh '''
                kind load docker-image $IMAGE_NAME --name cicd-lab
                '''
            }
        }

        stage('Fix Kubernetes Config') {
            steps {
                sh '''
                mkdir -p ~/.kube

                sed -i 's#https://127.0.0.1:54269#https://host.docker.internal:54269#g' ~/.kube/config

                kubectl config set-cluster kind-cicd-lab \
                  --server=https://host.docker.internal:54269 \
                  --insecure-skip-tls-verify=true

                kubectl config view --minify
                kubectl get nodes
                '''
            }
        }

        stage('Deploy To Kubernetes') {
            steps {
                dir('DevOps/Docker_Projects/simple-webapp') {
                    sh '''
                    kubectl apply -f k8s/deployment.yaml --validate=false
                    kubectl apply -f k8s/service.yaml --validate=false

                    kubectl set image deployment/enterprise-webapp-deployment \
                    enterprise-webapp=$IMAGE_NAME

                    kubectl rollout status deployment/enterprise-webapp-deployment
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'APP Pipeline Success'
        }

        failure {
            echo 'APP Pipeline Failed'
        }
    }
}