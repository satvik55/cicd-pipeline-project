pipeline {
    agent any

    environment {
        DOCKERHUB_REPO = 'satvik55/cicd-api'
        DOCKER_IMAGE   = ''
        IMAGE_TAG      = "${env.BUILD_NUMBER}-${env.GIT_COMMIT?.take(7) ?: 'unknown'}"
        APP_SERVER_IP  = '3.109.171.228'
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '5'))
        timestamps()
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo "Build #${env.BUILD_NUMBER} | ${env.GIT_COMMIT?.take(7)} | Tag: ${IMAGE_TAG}"
            }
        }

        stage('Install Dependencies') {
            steps {
                dir('app') {
                    sh 'npm ci --maxsockets=2'
                }
            }
        }

        stage('Run Tests') {
            steps {
                dir('app') {
                    sh 'npm test'
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    DOCKER_IMAGE = docker.build(
                        "${DOCKERHUB_REPO}:${IMAGE_TAG}",
                        "-f docker/Dockerfile ."
                    )
                }
            }
        }

        stage('Trivy Security Scan') {
            steps {
                sh """
                    chmod +x scripts/trivy_scan.sh
                    scripts/trivy_scan.sh ${DOCKERHUB_REPO}:${IMAGE_TAG} --strict
                """
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-reports/**', allowEmptyArchive: true
                }
            }
        }

        stage('Docker Push') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-creds') {
                        DOCKER_IMAGE.push("${IMAGE_TAG}")
                        DOCKER_IMAGE.push('latest')
                    }
                }
            }
        }

        stage('Deploy to App Server') {
            steps {
                sh """
                    chmod +x scripts/deploy.sh
                    scripts/deploy.sh 3.109.171.228 ${IMAGE_TAG} /var/lib/jenkins/.ssh/devops-project-key.pem
                """
            }
        }

        stage('Post-Deploy Verify') {
            steps {
                sh '''
                    echo "Verifying deployment via Nginx..."
                    for i in $(seq 1 5); do
                        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://3.109.171.228/health)
                        if [ "$HTTP_CODE" = "200" ]; then
                            echo "VERIFIED: App healthy (HTTP 200)"
                            curl -s http://3.109.171.228/health
                            exit 0
                        fi
                        echo "  Attempt $i: HTTP $HTTP_CODE"
                        sleep 5
                    done
                    echo "ERROR: Post-deploy verification failed"
                    exit 1
                '''
            }
        }
    }

    post {
        always {
            sh '''
                if [ -f scripts/build_summary.sh ]; then
                    chmod +x scripts/build_summary.sh
                    scripts/build_summary.sh || true
                else
                    echo "build_summary.sh not found — skipping"
                fi
            '''
            sh 'docker image prune -f || true'
        }
        cleanup {
            cleanWs()
        }
    }
}
