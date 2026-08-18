pipeline {

    /*
     * ============================================================
     * ECOMMERCE PORT DESIGN
     * COMPLETE DEVOPS CI/CD PIPELINE
     *
     * Platform:
     *   Jenkins on Windows
     *
     * Flow:
     *   GitLab
     *      ↓
     *   Checkout
     *      ↓
     *   NPM Validation
     *      ↓
     *   SonarQube
     *      ↓
     *   Quality Gate
     *      ↓
     *   Docker Build
     *      ↓
     *   Trivy Security Scan
     *      ↓
     *   Docker Hub
     *      ↓
     *   Terraform
     *      ↓
     *   AWS EKS
     *      ↓
     *   Kubernetes Deployment
     *      ↓
     *   Health Check
     *
     * Repository:
     * https://gitlab.com/SOFTAPP-TECHNOLOGIES/ecommerce-port-design.git
     * ============================================================
     */

    agent any


    // ============================================================
    // ENVIRONMENT
    // ============================================================

    environment {

        // -------------------------------
        // Docker
        // -------------------------------

        DOCKER_IMAGE = "YOUR_DOCKERHUB_USERNAME/ecommerce-port-design"

        IMAGE_TAG = "${BUILD_NUMBER}"

        FULL_IMAGE = "${DOCKER_IMAGE}:${IMAGE_TAG}"


        // -------------------------------
        // AWS
        // -------------------------------

        AWS_REGION = "ap-south-1"

        EKS_CLUSTER_NAME = "ecommerce-eks"


        // -------------------------------
        // Kubernetes
        // -------------------------------

        K8S_NAMESPACE = "ecommerce"

        K8S_DEPLOYMENT = "ecommerce-port-design"

        K8S_CONTAINER = "ecommerce-port-design"


        // -------------------------------
        // SonarQube
        // -------------------------------

        SONAR_PROJECT_KEY = "ecommerce-port-design"

    }


    // ============================================================
    // PIPELINE OPTIONS
    // ============================================================

    options {

        // Do not allow two builds at the same time
        disableConcurrentBuilds()

        // Keep last 10 builds
        buildDiscarder(
            logRotator(
                numToKeepStr: '10'
            )
        )

        // Timeout
        timeout(
            time: 60,
            unit: 'MINUTES'
        )

        // Add timestamps to console output
        timestamps()
    }


    // ============================================================
    // STAGES
    // ============================================================

    stages {


        // ========================================================
        // 1. CHECKOUT
        // ========================================================

        stage('01 - Checkout GitLab') {

            steps {

                echo "=============================================="
                echo "CHECKOUT SOURCE CODE"
                echo "=============================================="

                checkout scm

                bat '''
                    echo.
                    echo ===== Git Version =====
                    git --version

                    echo.
                    echo ===== Current Branch =====
                    git branch

                    echo.
                    echo ===== Git Commit =====
                    git rev-parse --short HEAD
                '''
            }
        }


        // ========================================================
        // 2. VERIFY PROJECT
        // ========================================================

        stage('02 - Verify Project Structure') {

            steps {

                echo "=============================================="
                echo "VERIFY PROJECT STRUCTURE"
                echo "=============================================="

                bat '''
                    echo.
                    echo ===== Root Directory =====
                    dir

                    echo.
                    echo ===== Source Directory =====
                    dir src

                    echo.
                    echo ===== HTML Directory =====
                    dir src\\html

                    echo.
                    echo ===== Assets Directory =====
                    dir src\\assets

                    echo.
                    echo ===== Dockerfile =====

                    if not exist Dockerfile (
                        echo ERROR: Dockerfile not found
                        exit /b 1
                    )

                    echo Dockerfile found.

                    echo.
                    echo ===== package.json =====

                    if not exist package.json (
                        echo ERROR: package.json not found
                        exit /b 1
                    )

                    echo package.json found.
                '''
            }
        }


        // ========================================================
        // 3. NPM INSTALL / VALIDATION
        // ========================================================

        stage('03 - NPM Validation') {

            steps {

                echo "=============================================="
                echo "NPM INSTALL / PROJECT VALIDATION"
                echo "=============================================="

                bat '''
                    echo.
                    echo ===== Node Version =====
                    node --version

                    echo.
                    echo ===== NPM Version =====
                    npm --version

                    echo.
                    echo ===== Installing Dependencies =====

                    if exist package-lock.json (
                        npm ci --ignore-scripts
                    ) else (
                        npm install --ignore-scripts
                    )

                    echo.
                    echo ===== Running Available Tests =====

                    npm test --if-present

                    echo.
                    echo ===== Running Available Build =====

                    npm run build --if-present
                '''
            }
        }


        // ========================================================
        // 4. SONARQUBE
        // ========================================================

        stage('04 - SonarQube Analysis') {

            steps {

                echo "=============================================="
                echo "SONARQUBE CODE QUALITY ANALYSIS"
                echo "=============================================="

                withSonarQubeEnv('SonarQube') {

                    bat """
                        sonar-scanner ^
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} ^
                        -Dsonar.projectName=ecommerce-port-design ^
                        -Dsonar.sources=src ^
                        -Dsonar.sourceEncoding=UTF-8
                    """
                }
            }
        }


        // ========================================================
        // 5. SONAR QUALITY GATE
        // ========================================================

        stage('05 - SonarQube Quality Gate') {

            steps {

                echo "=============================================="
                echo "SONARQUBE QUALITY GATE"
                echo "=============================================="

                timeout(
                    time: 10,
                    unit: 'MINUTES'
                ) {

                    waitForQualityGate(
                        abortPipeline: true
                    )
                }
            }
        }


        // ========================================================
        // 6. DOCKER BUILD
        // ========================================================

        stage('06 - Docker Build') {

            steps {

                echo "=============================================="
                echo "BUILDING DOCKER IMAGE"
                echo "=============================================="

                bat """
                    echo.
                    echo ===== Docker Version =====
                    docker --version

                    echo.
                    echo ===== Building Image =====

                    docker build ^
                    --pull ^
                    -t ${FULL_IMAGE} ^
                    .

                    echo.
                    echo ===== Docker Image =====

                    docker images ${DOCKER_IMAGE}
                """
            }
        }


        // ========================================================
        // 7. TRIVY SECURITY SCAN
        // ========================================================

        stage('07 - Trivy Security Scan') {

            steps {

                echo "=============================================="
                echo "TRIVY CONTAINER SECURITY SCAN"
                echo "=============================================="

                bat """
                    trivy image ^
                    --severity HIGH,CRITICAL ^
                    --exit-code 1 ^
                    --ignore-unfixed ^
                    ${FULL_IMAGE}
                """
            }
        }


        // ========================================================
        // 8. DOCKER HUB PUSH
        // ========================================================

        stage('08 - Push Image to Docker Hub') {

            steps {

                echo "=============================================="
                echo "PUSHING IMAGE TO DOCKER HUB"
                echo "=============================================="

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {

                    bat """
                        echo.
                        echo ===== Docker Login =====

                        docker login ^
                        -u %DOCKER_USERNAME% ^
                        -p %DOCKER_PASSWORD%

                        echo.
                        echo ===== Push Image =====

                        docker push ${FULL_IMAGE}

                        echo.
                        echo ===== Docker Logout =====

                        docker logout
                    """
                }
            }
        }


        // ========================================================
        // 9. TERRAFORM INIT
        // ========================================================

        stage('09 - Terraform Init') {

            steps {

                echo "=============================================="
                echo "TERRAFORM INITIALIZATION"
                echo "=============================================="

                dir('terraform') {

                    bat '''
                        terraform version

                        terraform init -input=false
                    '''
                }
            }
        }


        // ========================================================
        // 10. TERRAFORM VALIDATE
        // ========================================================

        stage('10 - Terraform Validate') {

            steps {

                echo "=============================================="
                echo "TERRAFORM VALIDATION"
                echo "=============================================="

                dir('terraform') {

                    bat '''
                        terraform validate
                    '''
                }
            }
        }


        // ========================================================
        // 11. TERRAFORM PLAN
        // ========================================================

        stage('11 - Terraform Plan') {

            steps {

                echo "=============================================="
                echo "TERRAFORM PLAN"
                echo "=============================================="

                dir('terraform') {

                    bat """
                        terraform plan ^
                        -input=false ^
                        -out=tfplan
                    """
                }
            }
        }


        // ========================================================
        // 12. TERRAFORM APPLY
        // ========================================================

        stage('12 - Terraform Apply') {

            steps {

                echo "=============================================="
                echo "TERRAFORM APPLY"
                echo "=============================================="

                withCredentials([
                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]
                ]) {

                    dir('terraform') {

                        bat '''
                            terraform apply ^
                            -input=false ^
                            -auto-approve ^
                            tfplan
                        '''
                    }
                }
            }
        }


        // ========================================================
        // 13. CONNECT TO EKS
        // ========================================================

        stage('13 - Connect to AWS EKS') {

            steps {

                echo "=============================================="
                echo "CONNECTING TO AWS EKS"
                echo "=============================================="

                withCredentials([
                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]
                ]) {

                    bat """
                        echo.
                        echo ===== AWS Identity =====

                        aws sts get-caller-identity

                        echo.
                        echo ===== Updating EKS Kubeconfig =====

                        aws eks update-kubeconfig ^
                        --region ${AWS_REGION} ^
                        --name ${EKS_CLUSTER_NAME}

                        echo.
                        echo ===== Kubernetes Nodes =====

                        kubectl get nodes
                    """
                }
            }
        }


        // ========================================================
        // 14. KUBERNETES DEPLOYMENT
        // ========================================================

        stage('14 - Kubernetes Deploy') {

            steps {

                echo "=============================================="
                echo "DEPLOYING APPLICATION TO KUBERNETES"
                echo "=============================================="

                bat """
                    echo.
                    echo ===== Namespace =====

                    kubectl get namespace ${K8S_NAMESPACE}

                    echo.
                    echo ===== Kubernetes Deployment =====

                    kubectl apply ^
                    -f k8s\\namespace.yaml

                    kubectl apply ^
                    -f k8s\\deployment.yaml ^
                    -n ${K8S_NAMESPACE}

                    kubectl apply ^
                    -f k8s\\service.yaml ^
                    -n ${K8S_NAMESPACE}

                    kubectl apply ^
                    -f k8s\\hpa.yaml ^
                    -n ${K8S_NAMESPACE}
                """
            }
        }


        // ========================================================
        // 15. UPDATE IMAGE
        // ========================================================

        stage('15 - Kubernetes Rolling Update') {

            steps {

                echo "=============================================="
                echo "UPDATING KUBERNETES IMAGE"
                echo "=============================================="

                bat """
                    kubectl set image ^
                    deployment/${K8S_DEPLOYMENT} ^
                    ${K8S_CONTAINER}=${FULL_IMAGE} ^
                    -n ${K8S_NAMESPACE}

                    echo.
                    echo ===== Rollout Status =====

                    kubectl rollout status ^
                    deployment/${K8S_DEPLOYMENT} ^
                    -n ${K8S_NAMESPACE} ^
                    --timeout=5m
                """
            }
        }


        // ========================================================
        // 16. KUBERNETES VERIFICATION
        // ========================================================

        stage('16 - Kubernetes Verification') {

            steps {

                echo "=============================================="
                echo "VERIFYING KUBERNETES DEPLOYMENT"
                echo "=============================================="

                bat """
                    echo.
                    echo ===== Pods =====

                    kubectl get pods ^
                    -n ${K8S_NAMESPACE} ^
                    -o wide

                    echo.
                    echo ===== Deployment =====

                    kubectl get deployment ^
                    ${K8S_DEPLOYMENT} ^
                    -n ${K8S_NAMESPACE}

                    echo.
                    echo ===== Service =====

                    kubectl get service ^
                    -n ${K8S_NAMESPACE}

                    echo.
                    echo ===== HPA =====

                    kubectl get hpa ^
                    -n ${K8S_NAMESPACE}
                """
            }
        }


        // ========================================================
        // 17. APPLICATION HEALTH CHECK
        // ========================================================

        stage('17 - Application Health Check') {

            steps {

                echo "=============================================="
                echo "APPLICATION HEALTH CHECK"
                echo "=============================================="

                bat """
                    echo.
                    echo ===== Pod Status =====

                    kubectl get pods ^
                    -n ${K8S_NAMESPACE}

                    echo.
                    echo ===== Service Details =====

                    kubectl describe service ^
                    ecommerce-port-service ^
                    -n ${K8S_NAMESPACE}
                """
            }
        }


        // ========================================================
        // 18. FINAL SUCCESS
        // ========================================================

        stage('18 - Deployment Summary') {

            steps {

                echo "=============================================="
                echo "DEPLOYMENT COMPLETED SUCCESSFULLY"
                echo "=============================================="

                echo "Application      : ecommerce-port-design"

                echo "Docker Image     : ${FULL_IMAGE}"

                echo "AWS Region       : ${AWS_REGION}"

                echo "EKS Cluster      : ${EKS_CLUSTER_NAME}"

                echo "Kubernetes NS    : ${K8S_NAMESPACE}"

                echo "Deployment       : ${K8S_DEPLOYMENT}"

                echo "Build Number     : ${BUILD_NUMBER}"

                echo "Git Commit       : ${GIT_COMMIT}"

                echo "=============================================="
            }
        }
    }


    // ============================================================
    // POST ACTIONS
    // ============================================================

    post {


        // --------------------------------------------------------
        // SUCCESS
        // --------------------------------------------------------

        success {

            echo """
            ======================================================
                    CI/CD PIPELINE SUCCESS
            ======================================================

            Project:
              ecommerce-port-design

            Build:
              ${BUILD_NUMBER}

            Docker Image:
              ${FULL_IMAGE}

            Kubernetes:
              ${K8S_NAMESPACE}

            EKS:
              ${EKS_CLUSTER_NAME}

            Status:
              SUCCESS

            ======================================================
            """
        }


        // --------------------------------------------------------
        // FAILURE
        // --------------------------------------------------------

        failure {

            echo """
            ======================================================
                    CI/CD PIPELINE FAILED
            ======================================================

            Project:
              ecommerce-port-design

            Build:
              ${BUILD_NUMBER}

            Status:
              FAILED

            Please check Jenkins Console Output.

            ======================================================
            """
        }


        // --------------------------------------------------------
        // ALWAYS
        // --------------------------------------------------------

        always {

            echo "Pipeline execution completed."

            // Remove local Docker image after build
            bat """
                docker image rm ${FULL_IMAGE} || exit 0
            """
        }
    }
}