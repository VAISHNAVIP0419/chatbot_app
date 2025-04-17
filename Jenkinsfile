pipeline {
  agent any

  tools {
    jdk 'jdk-17'
    nodejs 'node20'
  }

  environment {
    SCANNER_HOME = tool 'sonar-scanner-5'
    SONARQUBE_ENV = 'sonar-server'
    SONAR_TOKEN = credentials('sonar-token')
    REPO = 'vaishnavi2301/chatbot-app'
    IMAGE_TAG = 'latest'
    DOCKER_CREDENTIALS_ID = 'docker'
    NVD_API_KEY = 'nvd-api-key-id'
  }

  stages {
    stage('Clean Workspace') {
      steps {
        cleanWs()
      }
    }

    stage('Git Checkout') {
      steps {
        git branch: 'main', 
            url: 'https://github.com/VAISHNAVIP0419/chatbot_app.git', 
            credentialsId: 'git'
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv("${SONARQUBE_ENV}") {
          dir('project') {
            sh '''
              echo "Running SonarQube analysis..."
              $SCANNER_HOME/bin/sonar-scanner \
                -Dsonar.projectName=chatbot \
                -Dsonar.projectKey=chatbot \
                -Dsonar.sources=. \
                -Dsonar.login=${SONAR_TOKEN}
            '''
          }
        }
      }
    }

    stage('Code Quality Gate') {
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Install NPM Dependencies') {
      steps {
        dir('project') {
          sh '''
            echo "Installing NPM dependencies..."
            npm install
          '''
        }
      }
    }

    stage('OWASP Dependency Check') {
      steps {
        withCredentials([string(credentialsId: 'nvd-api-key-id', variable: 'NVD_API_KEY')]) {
          echo "Running OWASP Dependency Check..."
          dependencyCheck additionalArguments: "--format XML --project starbucks-ci --nvdApiKey ${env.NVD_API_KEY}", odcInstallation: 'db-check'
          dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
        }
      }
    }

    stage('Trivy Vulnerability Scan') {
      steps {
        sh '''
          echo "Running Trivy filesystem scan..."
          trivy fs . > trivy-fs-report.txt || true
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        dir('project') {
          sh '''
            echo "Building Docker image..."
            docker build -t $REPO:$IMAGE_TAG .
          '''
        }
      }
    }

    stage('Docker Scout Scan') {
      steps {
        script {
          withDockerRegistry(credentialsId: "${DOCKER_CREDENTIALS_ID}", url: 'https://index.docker.io/v1/') {
            sh '''
              echo "Running Docker Scout analysis..."
              docker scout quickview vaishnavi2301/chatbot-app:latest || true
              docker scout cves vaishnavi2301/chatbot-app:latest || true
              docker scout recommendations vaishnavi2301/chatbot-app:latest || true
            '''
          }
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
          sh '''
            echo "Pushing Docker image to Docker Hub..."
            echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
            docker push $REPO:$IMAGE_TAG
          '''
        }
      }
    }

    stage('Deploy to Docker Container') {
      steps {
        sh '''
          echo "Deploying container locally..."
          docker stop chatbot-app || true
          docker rm chatbot-app || true
          docker run -d --name chatbot-app -p 3000:80 $REPO:$IMAGE_TAG
        '''
      }
    }

    stage('Set up Kubeconfig') {
      steps {
        withCredentials([
          string(credentialsId: 'aws_access_key_id', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'aws_secret_access_key', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          sh '''
            echo "Setting up AWS credentials..."
            mkdir -p ~/.aws
            cat > ~/.aws/credentials <<EOL
[default]
aws_access_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
EOL

            echo "Setting up kubeconfig for EKS..."
            aws eks --region ap-south-1 update-kubeconfig --name "vaishnavi-eks"
          '''
        }
      }
    }

   stage('Deploy to EKS with Helm') {
  steps {
    dir('helm/chatbot_chart') {
      sh '''
        echo "Current directory:"
        pwd
        echo "Chart directory contents:"
        ls -al

        echo "Deploying to EKS with Helm..."
        helm upgrade --install chatbot-app . \
          --namespace chatbot --create-namespace
      '''
    }
  }
}

  }

  post {
    always {
      echo 'CI/CD Pipeline execution completed.'
    }
    success {
      echo '✅ CI/CD passed. Code is clean, image built, and deployed successfully.'
    }
    failure {
      echo '❌ CI/CD pipeline failed. Please check logs and fix the issues.'
    }
  }
}
