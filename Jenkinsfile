pipeline {
    agent any

    tools {
        git 'DefaultGit'
        nodejs 'node20'                    
        jdk 'jdk-17'         
    }

    environment {
        SONARQUBE_ENV = 'sonar-server'  
        SONAR_TOKEN = credentials('sonarqube')
        DOCKER_CREDENTIALS_ID = 'vaishnavi2301'
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
                script {
                    echo "✅ Workspace cleaned successfully"
                }
            }
            post {
                failure {
                    echo "❌ Workspace cleanup failed"
                }
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'main', credentialsId: 'github-credentials', url: 'https://github.com/VAISHNAVIP0419/chatbot_app.git'
                script {
                    echo "✅ Code checked out from Git"
                }
            }
            post {
                failure {
                    echo "❌ Git checkout failed"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                dir('project') {
                    sh 'npm install'
                }
                script {
                    echo "✅ Node dependencies installed"
                }
            }
            post {
                failure {
                    echo "❌ Failed to install dependencies"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv('sonar-server') {
                        def scannerHome = tool name: 'sonar-scanner-5'
                        dir('project') {
                            sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=ChatBot-Application -Dsonar.sources=. -Dsonar.login=${SONAR_TOKEN}"
                        }
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
                script {
                    echo "✅ Quality gate passed"
                }
            }
            post {
                failure {
                    echo "❌ Quality gate failed"
                }
            }
        }

        stage('Update Dependency-Check DB') {
            steps {
                script {
                    sh '/usr/local/bin/dependency-check.sh --updateonly --data $WORKSPACE/owasp-data'
                    echo "✅ Dependency-Check database updated"
                }
            }
            post {
                failure {
                    echo "❌ Failed to update Dependency-Check database"
                }
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                script {
                    sh '/usr/local/bin/dependency-check.sh --project ChatBot-Application --scan . --data $WORKSPACE/owasp-data --noupdate --disableYarnAudit'
                    echo "✅ OWASP dependency check completed"
                }
            }
            post {
                failure {
                    echo "❌ OWASP dependency check failed"
                }
            }
        }

        stage('Trivy FS Scan') {
            steps {
                script {
                    sh '/usr/local/bin/trivy fs . > trivy-fs-report.txt'
                    echo "✅ Trivy file system scan completed, check trivy-fs-report.txt"
                }
            }
            post {
                failure {
                    echo "❌ Trivy FS scan failed"
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    def image = "vaishnavi2301/chatbot-app:latest"
                    dir('project') {
                        sh "docker build -t ${image} ."
                    }
                    echo "✅ Docker image built"
                }
            }
            post {
                failure {
                    echo "❌ Docker build failed"
                }
            }
        }

        stage('Docker Push') {
            steps {
                script {
                    def image = "vaishnavi2301/chatbot-app:latest"
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                        sh "docker push ${image}"
                    }
                    echo "✅ Docker image pushed to Docker Hub"
                }
            }
            post {
                failure {
                    echo "❌ Docker push failed"
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                script {
                    def image = "vaishnavi2301/chatbot-app:latest"
                    sh "trivy image ${image} --exit-code 0 --severity HIGH,CRITICAL > trivy-image-report.txt"
                    echo "✅ Trivy image scan completed, check trivy-image-report.txt"
                }
            }
            post {
                failure {
                    echo "❌ Trivy image scan failed"
                }
            }
        }

        stage('Deploy to Container') {
            steps {
                script {
                    def image = "vaishnavi2301/chatbot-app:latest"
                    sh 'docker rm -f chatbot-app || true'
                    sh "docker run -d -p 80:80 --name chatbot-app ${image}"
                    echo "✅ Application deployed in container"
                }
            }
            post {
                failure {
                    echo "❌ Deployment to container failed"
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Pipeline completed successfully!"
        }
        failure {
            echo "🚨 Pipeline failed. Check logs for errors."
        }
    }
}
