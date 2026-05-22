pipeline {
    agent any

    environment {
        APP_DIR = "DevOps/Docker_Projects/simple-webapp"
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
                dir("${APP_DIR}") {
                    sh '''
                    docker build -t $IMAGE_NAME .
                    '''
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                mkdir -p compliance/reports

                trivy image \
                  --format json \
                  -o compliance/reports/trivy-image-report.json \
                  $IMAGE_NAME || true

                trivy image $IMAGE_NAME || true
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

                kubectl get nodes
                '''
            }
        }

        stage('Production Approval') {
            steps {
                input(
                    message: 'Approve Production Deployment?',
                    ok: 'Deploy',
                    submitter: 'approver'
                )
            }
        }

        stage('Deploy To Kubernetes') {
            steps {
                dir("${APP_DIR}") {
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

        stage('Archive Reports') {
            steps {
                archiveArtifacts artifacts: 'compliance/reports/*', allowEmptyArchive: true
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