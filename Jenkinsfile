pipeline {
    agent any

    tools {
        nodejs 'node20'                    
        jdk 'jdk-17.0.10+7'         
    }


    environment {
        SONARQUBE_ENV = 'sonar-server'        // SonarQube server name in Jenkins config
        SONAR_TOKEN = credentials('sonarqube')
        DOCKER_CREDENTIALS_ID = 'vaishnavi2301'
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
                echo "✅ Workspace cleaned successfully"
            }
            post {
                failure {
                    echo "❌ Workspace cleanup failed"
                }
            }
        }

        stage('Checkout Code') {
            steps {
                git credentialsId: 'VAISHNAVIP0419', url: 'https://github.com/VAISHNAVIP0419/chatbot_app.git'
                echo "✅ Code checked out from Git"
            }
            post {
                failure {
                    echo "❌ Git checkout failed"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
                echo "✅ Node dependencies installed"
            }
            post {
                failure {
                    echo "❌ Failed to install dependencies"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh "sonar-scanner -Dsonar.projectKey=ChatBot-Application -Dsonar.sources=. -Dsonar.login=${SONAR_TOKEN}"
                }
                echo "✅ SonarQube analysis triggered"
            }
            post {
                failure {
                    echo "❌ SonarQube analysis failed"
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
                echo "✅ Quality gate passed"
            }
            post {
                failure {
                    echo "❌ Quality gate failed"
                }
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                sh 'dependency-check.sh --project ChatBot-Application --scan .'
                echo "✅ OWASP dependency check completed"
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
                    // File system scan for vulnerabilities
                    sh 'trivy fs . > trivy-fs-report.txt'
                }
                echo "✅ Trivy file system scan completed, check trivy-fs-report.txt"
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
                    sh "docker build -t ${image} ."
                }
                echo "✅ Docker image built"
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
                        sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                        sh "docker push ${image}"
                    }
                }
                echo "✅ Docker image pushed to Docker Hub"
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
                    // Run Trivy image scan; adjust exit-code/flags as needed
                    sh "trivy image ${image} --exit-code 0 --severity HIGH,CRITICAL > trivy-image-report.txt"
                }
                echo "✅ Trivy image scan completed, check trivy-image-report.txt"
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
                    // Cleanup any existing container to avoid port conflict
                    sh 'docker rm -f chatbot-app || true'
                    // Deploy the new container
                    sh 'docker run -d -p 80:80 --name chatbot-app vaishnavi2301/chatbot-app:latest'
                }
                echo "✅ Application deployed in container"
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

