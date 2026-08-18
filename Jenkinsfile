pipeline {

    agent any

    environment {

        // =====================================================
        // GITLAB
        // =====================================================

        GITLAB_REPO =
            'https://gitlab.com/SOFTAPP-TECHNOLOGIES/ecommerce-port-design.git'

        GITLAB_BRANCH =
            'main'


        // =====================================================
        // DOCKER HUB
        // =====================================================

        DOCKER_IMAGE =
            'shivsoftapp/ecommerce-port-design'

        IMAGE_TAG =
            "555"

        FULL_IMAGE =
            "${DOCKER_IMAGE}:${IMAGE_TAG}"


        // =====================================================
        // AWS
        // =====================================================

        AWS_REGION =
            'ap-south-1'

        EKS_CLUSTER =
            'ecommerce-eks'


        // =====================================================
        // KUBERNETES
        // =====================================================

        K8S_NAMESPACE =
            'ecommerce'

        K8S_DEPLOYMENT =
            'ecommerce-port-design'

        K8S_CONTAINER =
            'ecommerce-port-design'


        // =====================================================
        // SONARQUBE
        // =====================================================

        SONAR_PROJECT =
            'ecommerce-port-design'
    }


    // =========================================================
    // OPTIONS
    // =========================================================

    options {

        disableConcurrentBuilds()

        buildDiscarder(
            logRotator(
                numToKeepStr: '10'
            )
        )

        timestamps()

        timeout(
            time: 60,
            unit: 'MINUTES'
        )
    }


    // =========================================================
    // STAGES
    // =========================================================

    stages {


        // =====================================================
        // 01 GITLAB CHECKOUT
        // =====================================================

        stage('01 - GitLab Checkout') {

            steps {

                echo "=========================================="
                echo "GITLAB CHECKOUT"
                echo "=========================================="

                echo "Repository: ${GITLAB_REPO}"
                echo "Branch: ${GITLAB_BRANCH}"

                git(
                    url: "${GITLAB_REPO}",
                    branch: "${GITLAB_BRANCH}",
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


        // =====================================================
        // 02 PROJECT VALIDATION
        // =====================================================

        stage('02 - Project Validation') {

            steps {

                echo "=========================================="
                echo "PROJECT VALIDATION"
                echo "=========================================="

                bat '''
                    echo.
                    echo ===== PROJECT STRUCTURE =====

                    dir

                    echo.
                    echo ===== SRC =====

                    dir src

                    echo.
                    echo ===== HTML =====

                    dir src\\html

                    echo.
                    echo ===== ASSETS =====

                    dir src\\assets

                    echo.
                    echo ===== CHECKING INDEX =====

                    if not exist src\\html\\index.html (
                        echo ERROR: index.html not found
                        exit /b 1
                    )

                    echo index.html OK

                    echo.
                    echo ===== CHECKING DOCKERFILE =====

                    if not exist Dockerfile (
                        echo ERROR: Dockerfile not found
                        exit /b 1
                    )

                    echo Dockerfile OK

                    echo.
                    echo ===== CHECKING NGINX =====

                    if not exist docker\\nginx.conf (
                        echo ERROR: nginx.conf not found
                        exit /b 1
                    )

                    echo nginx.conf OK

                    echo.
                    echo ===== CHECKING KUBERNETES =====

                    if not exist k8s\\namespace.yaml exit /b 1
                    if not exist k8s\\deployment.yaml exit /b 1
                    if not exist k8s\\service.yaml exit /b 1
                    if not exist k8s\\hpa.yaml exit /b 1
                    if not exist k8s\\ingress.yaml exit /b 1

                    echo Kubernetes files OK
                '''
            }
        }


        // =====================================================
        // 03 SONARQUBE
        // =====================================================

        stage('03 - SonarQube Analysis') {

            steps {

                echo "=========================================="
                echo "SONARQUBE ANALYSIS"
                echo "=========================================="

                withSonarQubeEnv('SonarQube') {

                    bat """
                        sonar-scanner ^
                        -Dsonar.projectKey=${SONAR_PROJECT} ^
                        -Dsonar.projectName=ecommerce-port-design ^
                        -Dsonar.sources=src ^
                        -Dsonar.sourceEncoding=UTF-8
                    """
                }
            }
        }


        // =====================================================
        // 04 QUALITY GATE
        // =====================================================

        stage('04 - SonarQube Quality Gate') {

            steps {

                echo "=========================================="
                echo "SONARQUBE QUALITY GATE"
                echo "=========================================="

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


        // =====================================================
        // 05 DOCKER BUILD
        // =====================================================

        stage('05 - Docker Build') {

            steps {

                echo "=========================================="
                echo "DOCKER BUILD"
                echo "=========================================="

                bat """
                    docker --version

                    docker build ^
                    --pull ^
                    -t ${FULL_IMAGE} ^
                    .
                """

                bat """
                    docker images ${DOCKER_IMAGE}
                """
            }
        }


        // =====================================================
        // 06 DOCKER CONTAINER TEST
        // =====================================================

        stage('06 - Docker Test') {

            steps {

                echo "=========================================="
                echo "DOCKER CONTAINER TEST"
                echo "=========================================="

                bat """
                    docker run -d ^
                    --name ecommerce-test ^
                    -p 8090:80 ^
                    ${FULL_IMAGE}

                    timeout /t 5 /nobreak

                    curl.exe -f http://localhost:8090/health

                    if %ERRORLEVEL% NEQ 0 (
                        echo Health check failed
                        docker logs ecommerce-test
                        docker rm -f ecommerce-test
                        exit /b 1
                    )

                    echo.
                    echo APPLICATION HEALTH CHECK PASSED

                    docker rm -f ecommerce-test
                """
            }
        }


        // =====================================================
        // 07 TRIVY
        // =====================================================

        stage('07 - Trivy Security Scan') {

            steps {

                echo "=========================================="
                echo "TRIVY SECURITY SCAN"
                echo "=========================================="

                bat """
                    trivy image ^
                    --severity HIGH,CRITICAL ^
                    --ignore-unfixed ^
                    --exit-code 1 ^
                    ${FULL_IMAGE}
                """
            }
        }


        // =====================================================
        // 08 DOCKER HUB
        // =====================================================

        stage('08 - Docker Hub Push') {

            steps {

                echo "=========================================="
                echo "DOCKER HUB PUSH"
                echo "=========================================="

                withCredentials([

                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )

                ]) {

                    bat """
                        docker login ^
                        -u %DOCKER_USERNAME% ^
                        -p %DOCKER_PASSWORD%

                        docker push ${FULL_IMAGE}

                        docker logout
                    """
                }
            }
        }


        // =====================================================
        // 09 TERRAFORM INIT
        // =====================================================

        stage('09 - Terraform Init') {

            steps {

                dir('terraform') {

                    bat '''
                        terraform version

                        terraform init -input=false
                    '''
                }
            }
        }


        // =====================================================
        // 10 TERRAFORM VALIDATE
        // =====================================================

        stage('10 - Terraform Validate') {

            steps {

                dir('terraform') {

                    bat '''
                        terraform validate
                    '''
                }
            }
        }


        // =====================================================
        // 11 TERRAFORM PLAN
        // =====================================================

        stage('11 - Terraform Plan') {

            steps {

                dir('terraform') {

                    bat '''
                        terraform plan ^
                        -input=false ^
                        -out=tfplan
                    '''
                }
            }
        }


        // =====================================================
        // 12 TERRAFORM APPLY
        // =====================================================

        stage('12 - Terraform Apply') {

            steps {

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


        // =====================================================
        // 13 AWS EKS
        // =====================================================

        stage('13 - AWS EKS Connection') {

            steps {

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
                        aws sts get-caller-identity

                        aws eks update-kubeconfig ^
                        --region ${AWS_REGION} ^
                        --name ${EKS_CLUSTER}

                        kubectl get nodes
                    """
                }
            }
        }


        // =====================================================
        // 14 KUBERNETES APPLY
        // =====================================================

        stage('14 - Kubernetes Apply') {

            steps {

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

                    kubectl apply ^
                    -f k8s\\ingress.yaml ^
                    -n ${K8S_NAMESPACE}
                """
            }
        }


        // =====================================================
        // 15 UPDATE IMAGE
        // =====================================================

        stage('15 - Kubernetes Rolling Update') {

            steps {

                bat """
                    kubectl set image ^
                    deployment/${K8S_DEPLOYMENT} ^
                    ${K8S_CONTAINER}=${FULL_IMAGE} ^
                    -n ${K8S_NAMESPACE}

                    kubectl rollout status ^
                    deployment/${K8S_DEPLOYMENT} ^
                    -n ${K8S_NAMESPACE} ^
                    --timeout=5m
                """
            }
        }


        // =====================================================
        // 16 VERIFY
        // =====================================================

        stage('16 - Kubernetes Verification') {

            steps {

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

                    echo.
                    echo ===== INGRESS =====

                    kubectl get ingress ^
                    -n ${K8S_NAMESPACE}
                """
            }
        }


        // =====================================================
        // 17 FINAL ROLLOUT
        // =====================================================

        stage('17 - Final Health Verification') {

            steps {

                bat """
                    kubectl rollout status ^
                    deployment/${K8S_DEPLOYMENT} ^
                    -n ${K8S_NAMESPACE} ^
                    --timeout=5m

                    echo.
                    echo ==========================================
                    echo APPLICATION DEPLOYMENT SUCCESSFUL
                    echo ==========================================
                """
            }
        }


        // =====================================================
        // 18 SUMMARY
        // =====================================================

        stage('18 - Deployment Summary') {

            steps {

                echo """
                ==================================================

                    ECOMMERCE PORT DESIGN
                    COMPLETE DEVOPS PIPELINE

                ==================================================

                GitLab:
                ${GITLAB_REPO}

                Branch:
                ${GITLAB_BRANCH}

                Docker:
                ${FULL_IMAGE}

                AWS Region:
                ${AWS_REGION}

                EKS:
                ${EKS_CLUSTER}

                Namespace:
                ${K8S_NAMESPACE}

                Deployment:
                ${K8S_DEPLOYMENT}

                Jenkins Build:
                ${BUILD_NUMBER}

                STATUS:
                SUCCESS

                ==================================================
                """
            }
        }
    }


    // =========================================================
    // POST
    // =========================================================

    post {

        success {

            echo "=========================================="
            echo "CI/CD PIPELINE SUCCESS"
            echo "=========================================="
        }

        failure {

            echo "=========================================="
            echo "CI/CD PIPELINE FAILED"
            echo "=========================================="

            echo "Check Jenkins Console Output."
        }

        always {

            bat """
                docker rm -f ecommerce-test 2>NUL || exit 0
            """
        }
    }
}