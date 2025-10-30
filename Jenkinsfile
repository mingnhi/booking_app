pipeline {
    agent any

    environment {
        REGISTRY = "docker.io/${DOCKER_USERNAME}"
        IMAGE_BACKEND = "booking-backend"
        IMAGE_FRONTEND = "booking-frontend"
        SERVER_HOST = "139.59.247.233"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/mingnhi/booking_app.git',
                        credentialsId: 'github-pat'
                    ]]
                ])
            }
        }

        stage('Build & Push Images') {
            parallel {
                stage('Backend') {
                    steps {
                        dir('backend') {
                            withCredentials([usernamePassword(credentialsId: 'dockerhub-cred',
                                usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                                sh '''
                                    set -e
                                    echo "Building backend image..."
                                    docker build -t docker.io/$DOCKER_USER/booking-backend:latest .
                                    echo "$DOCKER_PASS" | docker login -u $DOCKER_USER --password-stdin
                                    docker push docker.io/$DOCKER_USER/booking-backend:latest
                                '''
                            }
                        }
                    }
                }
                stage('Frontend') {
                    steps {
                        dir('frontend') {
                            withCredentials([usernamePassword(credentialsId: 'dockerhub-cred',
                                usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                                sh '''
                                    set -e
                                    echo "Building frontend image..."
                                    docker build -t docker.io/$DOCKER_USER/booking-frontend:latest .
                                    echo "$DOCKER_PASS" | docker login -u $DOCKER_USER --password-stdin
                                    docker push docker.io/$DOCKER_USER/booking-frontend:latest
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Deploy to Server') {
            steps {
                sshagent (credentials: ['server-ssh-key']) {
                    withCredentials([
                        usernamePassword(credentialsId: 'dockerhub-cred', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS'),
                        string(credentialsId: 'db-conn', variable: 'DB_CONN')
                    ]) {
                        sh '''
                            set -e
                            echo "Deploying to server $SERVER_HOST..."

                            scp -o StrictHostKeyChecking=no docker-compose.prod.yml root@$SERVER_HOST:/root/project/docker-compose.yml

                            ssh -o StrictHostKeyChecking=no root@$SERVER_HOST "
                                cd /root/project &&
                                echo 'DB_CONN=$DB_CONN' > .env &&
                                echo 'MONGODB_URI=$DB_CONN' >> .env &&
                                echo '$DOCKER_PASS' | docker login -u $DOCKER_USER --password-stdin &&
                                docker compose --env-file .env pull &&
                                docker compose --env-file .env down &&
                                docker compose --env-file .env up -d &&
                                docker image prune -f
                            "
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'CI/CD pipeline completed successfully!'
        }
        failure {
            echo 'Build failed. Check logs for details.'
        }
    }
}
