pipeline {

    /*
     * ============================================================
     * ECOMMERCE PORT DESIGN
     * STATIC HTML/CSS/JS DEVOPS CI/CD PIPELINE
     *
     * GitLab:
     * https://gitlab.com/SOFTAPP-TECHNOLOGIES/ecommerce-port-design.git
     *
     * Branch:
     * main
     *
     * Jenkins:
     * Windows
     *
     * Pipeline:
     *
     * GitLab
     *   ↓
     * Checkout
     *   ↓
     * SonarQube
     *   ↓
     * Quality Gate
     *   ↓
     * Docker Build
     *   ↓
     * Trivy Scan
     *   ↓
     * Docker Hub
     *   ↓
     * AWS EKS
     *   ↓
     * Kubernetes
     *   ↓
     * Rolling Deployment
     *
     * ============================================================
     */

    agent any


    // ============================================================
    // ENVIRONMENT VARIABLES
    // ============================================================

    environment {

        // --------------------------------------------------------
        // GitLab
        // --------------------------------------------------------

        GITLAB_URL =
            'https://gitlab.com/SOFTAPP-TECHNOLOGIES/ecommerce-port-design.git'

        GIT_BRANCH = 'main'


        // --------------------------------------------------------
        // Docker Hub
        // --------------------------------------------------------

        DOCKER_IMAGE =
            'YOUR_DOCKERHUB_USERNAME/ecommerce-port-design'

        IMAGE_TAG =
            "${BUILD_NUMBER}"

        FULL_IMAGE =
            "${DOCKER_IMAGE}:${IMAGE_TAG}"


        // --------------------------------------------------------
        // AWS
        // --------------------------------------------------------

        AWS_REGION =
            'ap-south-1'

        EKS_CLUSTER_NAME =
            'ecommerce-eks'


        // --------------------------------------------------------
        // Kubernetes
        // --------------------------------------------------------

        K8S_NAMESPACE =
            'ecommerce'

        K8S_DEPLOYMENT =
            'ecommerce-port-design'

        K8S_CONTAINER =
            'ecommerce-port-design'


        // --------------------------------------------------------
        // SonarQube
        // --------------------------------------------------------

        SONAR_PROJECT_KEY =
            'ecommerce-port-design'
    }


    // ============================================================
    // PIPELINE OPTIONS
    // ============================================================

    options {

        disableConcurrentBuilds()

        buildDiscarder(
            logRotator(
                numToKeepStr: '10'
            )
        )

        timeout(
            time: 60,
            unit: 'MINUTES'
        )

        timestamps()
    }


    // ============================================================
    // STAGES
    // ============================================================

    stages {


        // ========================================================
        // STAGE 1
        // GITLAB CHECKOUT
        // ========================================================

        stage('01 - GitLab Checkout') {

            steps {

                echo "=============================================="
                echo "GITLAB CHECKOUT"
                echo "=============================================="

                echo "Repository: ${GITLAB_URL}"
                echo "Branch    : ${GIT_BRANCH}"

                /*
                 * GitLab repository explicitly defined.
                 *
                 * Jenkins Credentials:
                 * gitlab-credentials
                 */

                git(
                    url: "${GITLAB_URL}",
                    branch: "${GIT_BRANCH}",
                    credentialsId: 'gitlab-credentials'
                )

                bat '''
                    echo.
                    echo ===== CURRENT BRANCH =====

                    git branch

                    echo.
                    echo ===== LATEST COMMIT =====

                    git log -1 --oneline

                    echo.
                    echo ===== REMOTE =====

                    git remote -v
                '''
            }
        }


        // ========================================================
        // STAGE 2
        // PROJECT VALIDATION
        // ========================================================

        stage('02 - Project Validation') {

            steps {

                echo "=============================================="
                echo "VALIDATING HTML PROJECT"
                echo "=============================================="

                bat '''
                    echo.
                    echo ===== ROOT PROJECT =====

                    dir

                    echo.
                    echo ===== SRC DIRECTORY =====

                    dir src

                    echo.
                    echo ===== HTML DIRECTORY =====

                    dir src\\html

                    echo.
                    echo ===== ASSETS DIRECTORY =====

                    dir src\\assets

                    echo.
                    echo ===== CHECKING INDEX.HTML =====

                    if not exist src\\html\\index.html (
                        echo ERROR: index.html not found
                        exit /b 1
                    )

                    echo index.html found successfully.

                    echo.
                    echo ===== CHECKING DOCKERFILE =====

                    if not exist Dockerfile (
                        echo ERROR: Dockerfile not found
                        exit /b 1
                    )

                    echo Dockerfile found successfully.

                    echo.
                    echo ===== CHECKING NGINX CONFIG =====

                    if not exist docker\\nginx.conf (
                        echo ERROR: docker\\nginx.conf not found
                        exit /b 1
                    )

                    echo nginx.conf found successfully.
                '''
            }
        }


        // ========================================================
        // STAGE 3
        // SONARQUBE
        // ========================================================

        stage('03 - SonarQube Analysis') {

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
        // STAGE 4
        // SONAR QUALITY GATE
        // ========================================================

        stage('04 - SonarQube Quality Gate') {

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
        // STAGE 5
        // DOCKER BUILD
        // ========================================================

        stage('05 - Docker Build') {

            steps {

                echo "=============================================="
                echo "DOCKER IMAGE BUILD"
                echo "=============================================="

                bat """
                    echo.
                    echo ===== DOCKER VERSION =====

                    docker --version

                    echo.
                    echo ===== BUILDING IMAGE =====

                    docker build ^
                    --pull ^
                    -t ${FULL_IMAGE} ^
                    .

                    echo.
                    echo ===== IMAGE CREATED =====

                    docker images ${DOCKER_IMAGE}
                """
            }
        }


        // ========================================================
        // STAGE 6
        // LOCAL CONTAINER TEST
        // ========================================================

        stage('06 - Docker Container Test') {

            steps {

                echo "=============================================="
                echo "DOCKER CONTAINER TEST"
                echo "=============================================="

                bat """
                    echo.
                    echo ===== STARTING TEST CONTAINER =====

                    docker run -d ^
                    --name ecommerce-test ^
                    -p 8090:80 ^
                    ${FULL_IMAGE}

                    timeout /t 5 /nobreak

                    echo.
                    echo ===== TESTING HEALTH ENDPOINT =====

                    curl.exe -f http://localhost:8090/health

                    if %ERRORLEVEL% NEQ 0 (
                        echo ERROR: Health check failed
                        docker logs ecommerce-test
                        docker rm -f ecommerce-test
                        exit /b 1
                    )

                    echo.
                    echo Health check successful.

                    echo.
                    echo ===== STOPPING TEST CONTAINER =====

                    docker rm -f ecommerce-test
                """
            }
        }


        // ========================================================
        // STAGE 7
        // TRIVY SECURITY SCAN
        // ========================================================

        stage('07 - Trivy Security Scan') {

            steps {

                echo "=============================================="
                echo "TRIVY SECURITY SCAN"
                echo "=============================================="

                bat """
                    trivy image ^
                    --severity HIGH,CRITICAL ^
                    --ignore-unfixed ^
                    --exit-code 1 ^
                    ${FULL_IMAGE}
                """
            }
        }


        // ========================================================
        // STAGE 8
        // DOCKER HUB PUSH
        // ========================================================

        stage('08 - Docker Hub Push') {

            steps {

                echo "=============================================="
                echo "PUSHING IMAGE TO DOCKER HUB"
                echo "=============================================="

                withCredentials([

                    usernamePassword(
                        credentialsId:
                            'dockerhub-credentials',

                        usernameVariable:
                            'DOCKER_USERNAME',

                        passwordVariable:
                            'DOCKER_PASSWORD'
                    )

                ]) {

                    bat """
                        echo.
                        echo ===== DOCKER LOGIN =====

                        docker login ^
                        -u %DOCKER_USERNAME% ^
                        -p %DOCKER_PASSWORD%

                        echo.
                        echo ===== PUSHING IMAGE =====

                        docker push ${FULL_IMAGE}

                        echo.
                        echo ===== LOGOUT =====

                        docker logout
                    """
                }
            }
        }


        // ========================================================
        // STAGE 9
        // TERRAFORM INIT
        // ========================================================

        stage('09 - Terraform Init') {

            steps {

                echo "=============================================="
                echo "TERRAFORM INIT"
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
        // STAGE 10
        // TERRAFORM VALIDATE
        // ========================================================

        stage('10 - Terraform Validate') {

            steps {

                echo "=============================================="
                echo "TERRAFORM VALIDATE"
                echo "=============================================="

                dir('terraform') {

                    bat '''
                        terraform validate
                    '''
                }
            }
        }


        // ========================================================
        // STAGE 11
        // TERRAFORM PLAN
        // ========================================================

        stage('11 - Terraform Plan') {

            steps {

                echo "=============================================="
                echo "TERRAFORM PLAN"
                echo "=============================================="

                dir('terraform') {

                    bat '''
                        terraform plan ^
                        -input=false ^
                        -out=tfplan
                    '''
                }
            }
        }


        // ========================================================
        // STAGE 12
        // TERRAFORM APPLY
        // ========================================================

        stage('12 - Terraform Apply') {

            steps {

                echo "=============================================="
                echo "TERRAFORM APPLY"
                echo "=============================================="

                withCredentials([

                    [
                        $class:
                            'AmazonWebServicesCredentialsBinding',

                        credentialsId:
                            'aws-credentials',

                        accessKeyVariable:
                            'AWS_ACCESS_KEY_ID',

                        secretKeyVariable:
                            'AWS_SECRET_ACCESS_KEY'
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
        // STAGE 13
        // AWS EKS CONNECTION
        // ========================================================

        stage('13 - AWS EKS Connection') {

            steps {

                echo "=============================================="
                echo "CONNECTING TO AWS EKS"
                echo "=============================================="

                withCredentials([

                    [
                        $class:
                            'AmazonWebServicesCredentialsBinding',

                        credentialsId:
                            'aws-credentials',

                        accessKeyVariable:
                            'AWS_ACCESS_KEY_ID',

                        secretKeyVariable:
                            'AWS_SECRET_ACCESS_KEY'
                    ]

                ]) {

                    bat """
                        echo.
                        echo ===== AWS IDENTITY =====

                        aws sts get-caller-identity

                        echo.
                        echo ===== EKS KUBECONFIG =====

                        aws eks update-kubeconfig ^
                        --region ${AWS_REGION} ^
                        --name ${EKS_CLUSTER_NAME}

                        echo.
                        echo ===== EKS NODES =====

                        kubectl get nodes
                    """
                }
            }
        }


        // ========================================================
        // STAGE 14
        // KUBERNETES MANIFESTS
        // ========================================================

        stage('14 - Kubernetes Apply') {

            steps {

                echo "=============================================="
                echo "APPLYING KUBERNETES MANIFESTS"
                echo "=============================================="

                bat """
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
        // STAGE 15
        // UPDATE DOCKER IMAGE
        // ========================================================

        stage('15 - Kubernetes Rolling Deployment') {

            steps {

                echo "=============================================="
                echo "KUBERNETES ROLLING DEPLOYMENT"
                echo "=============================================="

                bat """
                    kubectl set image ^
                    deployment/${K8S_DEPLOYMENT} ^
                    ${K8S_CONTAINER}=${FULL_IMAGE} ^
                    -n ${K8S_NAMESPACE}

                    echo.
                    echo ===== WAITING FOR ROLLOUT =====

                    kubectl rollout status ^
                    deployment/${K8S_DEPLOYMENT} ^
                    -n ${K8S_NAMESPACE} ^
                    --timeout=5m
                """
            }
        }


        // ========================================================
        // STAGE 16
        // KUBERNETES VERIFICATION
        // ========================================================

        stage('16 - Kubernetes Verification') {

            steps {

                echo "=============================================="
                echo "KUBERNETES VERIFICATION"
                echo "=============================================="

                bat """
                    echo.
                    echo ===== PODS =====

                    kubectl get pods ^
                    -n ${K8S_NAMESPACE} ^
                    -o wide

                    echo.
                    echo ===== DEPLOYMENT =====

                    kubectl get deployment ^
                    ${K8S_DEPLOYMENT} ^
                    -n ${K8S_NAMESPACE}

                    echo.
                    echo ===== SERVICE =====

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
        // STAGE 17
        // FINAL HEALTH CHECK
        // ========================================================

        stage('17 - Final Health Check') {

            steps {

                echo "=============================================="
                echo "FINAL APPLICATION HEALTH CHECK"
                echo "=============================================="

                bat """
                    echo.
                    echo ===== POD STATUS =====

                    kubectl get pods ^
                    -n ${K8S_NAMESPACE}

                    echo.
                    echo ===== DEPLOYMENT STATUS =====

                    kubectl rollout status ^
                    deployment/${K8S_DEPLOYMENT} ^
                    -n ${K8S_NAMESPACE} ^
                    --timeout=5m

                    echo.
                    echo ===== APPLICATION DEPLOYMENT SUCCESSFUL =====
                """
            }
        }


        // ========================================================
        // STAGE 18
        // SUMMARY
        // ========================================================

        stage('18 - Deployment Summary') {

            steps {

                echo """
                ====================================================
                    ECOMMERCE PORT DESIGN
                    DEVOPS DEPLOYMENT COMPLETED
                ====================================================

                GitLab:
                ${GITLAB_URL}

                Branch:
                ${GIT_BRANCH}

                Docker Image:
                ${FULL_IMAGE}

                AWS Region:
                ${AWS_REGION}

                EKS Cluster:
                ${EKS_CLUSTER_NAME}

                Kubernetes Namespace:
                ${K8S_NAMESPACE}

                Kubernetes Deployment:
                ${K8S_DEPLOYMENT}

                Jenkins Build:
                ${BUILD_NUMBER}

                Status:
                SUCCESS

                ====================================================
                """
            }
        }
    }


    // ============================================================
    // POST ACTIONS
    // ============================================================

    post {

        success {

            echo """
            ====================================================
                  PIPELINE SUCCESS
            ====================================================

            GitLab:
            ${GITLAB_URL}

            Branch:
            ${GIT_BRANCH}

            Docker:
            ${FULL_IMAGE}

            Kubernetes:
            ${K8S_DEPLOYMENT}

            Status:
            SUCCESS

            ====================================================
            """
        }


        failure {

            echo """
            ====================================================
                  PIPELINE FAILED
            ====================================================

            Project:
            ecommerce-port-design

            Build:
            ${BUILD_NUMBER}

            Check Jenkins Console Output.

            ====================================================
            """
        }


        always {

            echo "Cleaning Jenkins workspace Docker resources..."

            bat """
                docker rm -f ecommerce-test 2>NUL || exit 0
            """
        }
    }
}