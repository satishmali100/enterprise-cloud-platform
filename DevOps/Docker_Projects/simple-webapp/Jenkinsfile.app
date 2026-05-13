pipeline {
    agent any

    environment {
        APP_DIR = 'DevOps/Docker_Projects/simple-webapp'
        APP_NAME = 'enterprise-webapp'
        IMAGE_REPO = 'enterprise-webapp-jenkins'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        K8S_DEPLOYMENT = 'enterprise-webapp-deployment'
        KIND_CLUSTER = 'cicd-lab'
    }

    stages {

        stage('Secret Scan - Gitleaks') {
            steps {
                dir("${APP_DIR}") {
                    sh '''
                    gitleaks detect --source . --no-git --redact --exit-code 0
                    '''
                }
            }
        }

        stage('SAST Scan - Semgrep') {
            steps {
                dir("${APP_DIR}") {
                    sh '''
                    semgrep scan --config auto . || true
                    '''
                }
            }
        }

        stage('IaC Scan - Checkov') {
            steps {
                dir("${APP_DIR}") {
                    sh '''
                    checkov -d . --quiet || true
                    '''
                }
            }
        }

        stage('Docker Build') {
            steps {
                dir("${APP_DIR}") {
                    sh '''
                    IMAGE_NAME=${IMAGE_REPO}:${IMAGE_TAG}
                    docker build -t $IMAGE_NAME .
                    '''
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                dir("${APP_DIR}") {
                    sh '''
                    IMAGE_NAME=${IMAGE_REPO}:${IMAGE_TAG}

                    trivy image \
                    --timeout 10m \
                    --severity HIGH,CRITICAL \
                    --exit-code 0 \
                    $IMAGE_NAME
                    '''
                }
            }
        }

        stage('Load Image Into kind') {
            steps {
                sh '''
                IMAGE_NAME=${IMAGE_REPO}:${IMAGE_TAG}

                kind load docker-image \
                $IMAGE_NAME \
                --name ${KIND_CLUSTER}
                '''
            }
        }

        stage('Deploy To Kubernetes') {
            steps {
                dir("${APP_DIR}") {
                    sh '''
                    IMAGE_NAME=${IMAGE_REPO}:${IMAGE_TAG}

                    kubectl apply -f k8s/service.yaml --validate=false
                    kubectl apply -f k8s/deployment.yaml --validate=false

                    kubectl set image deployment/${K8S_DEPLOYMENT} \
                    ${APP_NAME}=$IMAGE_NAME
                    '''
                }
            }
        }

        stage('Rollout Status') {
            steps {
                sh '''
                kubectl rollout status deployment/${K8S_DEPLOYMENT}
                kubectl get pods
                '''
            }
        }
    }

    post {
        success {
            echo "APP Pipeline Success"
        }

        failure {
            echo "APP Pipeline Failed"
        }
    }
}