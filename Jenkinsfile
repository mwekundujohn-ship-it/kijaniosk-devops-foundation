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
                script {
                    def base = sh(script: "node -p 'require(\"./${APP_DIR}/package.json\").version'", returnStdout: true).trim()
                    def sha = (env.GIT_COMMIT ?: '').take(7)
                    env.PUBLISH_VERSION = "${base}-${sha}"
                    env.ARTIFACT_URL = "${env.NEXUS_URL}/repository/${env.NEXUS_REPO}/${env.APP_NAME}/-/${env.APP_NAME}-${env.PUBLISH_VERSION}.tgz"
                }
                dir("${APP_DIR}") {
                    withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                        sh '''
                            set -eu
                            cleanup() { rm -f .npmrc; }
                            trap cleanup EXIT
                            npm version "$PUBLISH_VERSION" --no-git-tag-version --allow-same-version
                            AUTH=$(printf '%s:%s' "$NEXUS_USER" "$NEXUS_PASS" | base64 -w0)
                            NEXUS_HOST=${NEXUS_URL#*://}
                            {
                              echo "registry=${NEXUS_URL}/repository/${NEXUS_REPO}/"
                              echo "//${NEXUS_HOST}/repository/${NEXUS_REPO}/:_auth=${AUTH}"
                              echo "always-auth=true"
                            } > .npmrc
                            npm publish --registry "${NEXUS_URL}/repository/${NEXUS_REPO}/"
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
            echo "SUCCESS: published ${env.APP_NAME} ${env.PUBLISH_VERSION} to Nexus -> ${env.ARTIFACT_URL}"
        }
        failure {
            echo "FAILURE: build ${env.BUILD_NUMBER} stopped at the first failing stage. Later stages were skipped and no new version was published from this run."
        }
        changed {
            echo "Pipeline status changed to ${currentBuild.currentResult} on build ${env.BUILD_NUMBER}."
        }
    }
}
