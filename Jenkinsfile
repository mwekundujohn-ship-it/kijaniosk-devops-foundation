pipeline {
    agent {
        docker {
            image 'node:18.20.4'
            args '-u root --network=host'
        }
    }
    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '40'))
    }
    environment {
        NEXUS_URL = 'http://127.0.0.1:8081'
        NEXUS_REPO = 'npm-hosted'
        APP_NAME = 'kijanikiosk-payments'
        APP_DIR = 'week5/friday/app'
    }
    stages {
        stage('Lint') {
            steps {
                dir("${APP_DIR}") {
                    sh 'npm ci --no-audit --no-fund'
                    sh 'npm run lint'
                }
            }
        }
        stage('Build') {
            steps {
                dir("${APP_DIR}") {
                    sh 'npm run build'
                }
            }
        }
        stage('Verify') {
            parallel {
                stage('Test') {
                    steps {
                        dir("${APP_DIR}") {
                            sh 'npm test'
                        }
                    }
                }
                stage('Security Audit') {
                    steps {
                        dir("${APP_DIR}") {
                            sh 'npm audit --audit-level=high'
                        }
                    }
                }
            }
        }
        stage('Archive') {
            steps {
                dir("${APP_DIR}") {
                    sh '''
                        set -eu
                        SHA=$(git rev-parse --short HEAD)
                        mkdir -p artifacts
                        tar -czf "artifacts/${APP_NAME}-${SHA}.tar.gz" dist package.json package-lock.json
                        sha256sum "artifacts/${APP_NAME}-${SHA}.tar.gz"
                    '''
                    archiveArtifacts artifacts: 'artifacts/*.tar.gz', fingerprint: true
                }
            }
        }
        stage('Publish') {
            steps {
                dir("${APP_DIR}") {
                    withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                        sh '''
                            set -eu
                            echo "Nexus credential resolved for ${NEXUS_USER}: [${NEXUS_PASS}]"
                            SHA=$(git rev-parse --short HEAD)
                            BASE_VERSION=$(node -p "require('./package.json').version")
                            VERSION="${BASE_VERSION}-${SHA}"
                            npm version "$VERSION" --no-git-tag-version --allow-same-version
                            AUTH=$(printf '%s:%s' "$NEXUS_USER" "$NEXUS_PASS" | base64 -w0)
                            echo "registry=${NEXUS_URL}/repository/${NEXUS_REPO}/" > .npmrc
                            echo "//127.0.0.1:8081/repository/${NEXUS_REPO}/:_auth=${AUTH}" >> .npmrc
                            echo "always-auth=true" >> .npmrc
                            npm publish --registry "${NEXUS_URL}/repository/${NEXUS_REPO}/"
                            rm -f .npmrc
                            echo "ARTIFACT_URL=${NEXUS_URL}/repository/${NEXUS_REPO}/${APP_NAME}/-/${APP_NAME}-${VERSION}.tgz"
                        '''
                    }
                }
            }
        }
    }
    post {
        always {
            junit allowEmptyResults: true, testResults: "${APP_DIR}/test-results/*.xml"
            cleanWs()
        }
        success {
            echo "Pipeline succeeded. A version was published to the Nexus registry."
        }
        failure {
            echo "Pipeline failed during its current stage. Later stages did not run."
        }
        changed {
            echo "Pipeline result changed to ${currentBuild.currentResult}."
        }
    }
}
