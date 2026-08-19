pipeline {

    /*
     * ============================================================
     * ECOMMERCE PORT DESIGN
     * COMPLETE DEVOPS CI/CD PIPELINE
     *
     * GitLab
     *    ↓
     * Jenkins - Windows
     *    ↓
     * Terraform
     *    ↓
     * AWS VPC + EC2 + EKS
     *    ↓
     * Ansible
     *    ↓
     * SonarQube
     *    ↓
     * Docker Build
     *    ↓
     * Trivy
     *    ↓
     * Docker Hub
     *    ↓
     * EKS
     *    ↓
     * Kubernetes
     *    ↓
     * Helm
     *    ↓
     * Prometheus
     * Grafana
     * Alertmanager
     *
     * Jenkins Controller:
     * Windows
     *
     * Ansible:
     * WSL2 + Ubuntu
     * ============================================================
     */


    agent none


    // ==========================================================
    // PARAMETERS
    // ==========================================================

    parameters {

        string(
            name: 'AWS_KEYPAIR_NAME',
            defaultValue: 'ecommerce-devops-key',
            description: 'Existing AWS EC2 Key Pair name'
        )

        string(
            name: 'AWS_REGION',
            defaultValue: 'ap-south-1',
            description: 'AWS Region'
        )
    }


    // ==========================================================
    // ENVIRONMENT
    // ==========================================================

    environment {

        // ------------------------------------------------------
        // GitLab
        // ------------------------------------------------------

        GITLAB_REPO =
            'https://gitlab.com/SOFTAPP-TECHNOLOGIES/ecommerce-port-design.git'

        GITLAB_BRANCH =
            'main'


        // ------------------------------------------------------
        // AWS
        // ------------------------------------------------------

        AWS_DEFAULT_REGION =
            "${params.AWS_REGION}"

        EKS_CLUSTER_NAME =
            'ecommerce-eks'


        // ------------------------------------------------------
        // Docker
        // ------------------------------------------------------

        DOCKER_IMAGE =
            'shivsoftapp/ecommerce-port-design'

        /*
         * Jenkins BUILD_NUMBER automatically becomes image tag.
         *
         * Example:
         *
         * BUILD_NUMBER = 539
         *
         * Result:
         *
         * shivsoftapp/ecommerce-port-design:539
         */

        IMAGE_TAG =
            "539"

        FULL_IMAGE =
            "shivsoftapp/ecommerce-port-design:539"


        // ------------------------------------------------------
        // Kubernetes
        // ------------------------------------------------------

        K8S_NAMESPACE =
            'ecommerce'

        K8S_DEPLOYMENT =
            'ecommerce-port-design'

        K8S_CONTAINER =
            'ecommerce-port-design'


        // ------------------------------------------------------
        // Jenkins Credentials
        // ------------------------------------------------------

        GITLAB_CREDENTIALS =
            'gitlab-credentials'

        AWS_CREDENTIALS =
            'aws-credentials'

        DOCKERHUB_CREDENTIALS =
            'dockerhub-credentials'

        SONARQUBE_CREDENTIALS =
            'sonarqube-token'
    }


    // ==========================================================
    // OPTIONS
    // ==========================================================

    options {

        disableConcurrentBuilds()

        timestamps()

        timeout(
            time: 120,
            unit: 'MINUTES'
        )

        buildDiscarder(
            logRotator(
                numToKeepStr: '10'
            )
        )

        skipDefaultCheckout(true)
    }


    // ==========================================================
    // STAGES
    // ==========================================================

    stages {


        // ======================================================
        // 01 - GITLAB CHECKOUT
        // ======================================================

        stage('01 - GitLab Checkout') {

            agent {
                label 'built-in'
            }

            steps {

                echo '============================================'

                echo 'CHECKING OUT SOURCE CODE FROM GITLAB'

                echo '============================================'


                git(
                    url: "${GITLAB_REPO}",

                    branch: "${GITLAB_BRANCH}",

                    credentialsId: "${GITLAB_CREDENTIALS}"
                )


                bat '''
                    echo.
                    echo ===== GIT INFORMATION =====

                    git branch

                    git log -1 --oneline

                    git remote -v
                '''
            }
        }


        // ======================================================
        // 02 - BUILD INFORMATION
        // ======================================================

        stage('02 - Build Information') {

            agent {
                label 'built-in'
            }

            steps {

                echo '============================================'

                echo "JENKINS BUILD NUMBER : ${BUILD_NUMBER}"

                echo "DOCKER IMAGE          : ${FULL_IMAGE}"

                echo '============================================'
            }
        }


        // ======================================================
        // 03 - TERRAFORM VALIDATE
        // ======================================================

        stage('03 - Terraform Validate') {

            agent {
                label 'built-in'
            }

            steps {

                dir('terraform') {

                    bat '''
                        terraform version

                        terraform init -input=false

                        terraform validate
                    '''
                }
            }
        }


        // ======================================================
        // 04 - TERRAFORM PLAN
        // ======================================================

        stage('04 - Terraform Plan') {

            agent {
                label 'built-in'
            }

            steps {

                withCredentials([

                    [
                        $class:
                        'AmazonWebServicesCredentialsBinding',

                        credentialsId:
                        "${AWS_CREDENTIALS}",

                        accessKeyVariable:
                        'AWS_ACCESS_KEY_ID',

                        secretKeyVariable:
                        'AWS_SECRET_ACCESS_KEY'
                    ]

                ]) {

                    dir('terraform') {

                        bat '''

                            echo.
                            echo ===== AWS IDENTITY =====

                            aws sts get-caller-identity


                            echo.
                            echo ===== TERRAFORM PLAN =====

                            terraform plan ^
                              -input=false ^
                              -var="key_name=%AWS_KEYPAIR_NAME%" ^
                              -var="admin_cidr=0.0.0.0/0" ^
                              -out=tfplan

                        '''
                    }
                }
            }
        }


        // ======================================================
        // 05 - TERRAFORM APPLY
        // ======================================================

        stage('05 - Terraform Apply') {

            agent {
                label 'built-in'
            }

            steps {

                withCredentials([

                    [
                        $class:
                        'AmazonWebServicesCredentialsBinding',

                        credentialsId:
                        "${AWS_CREDENTIALS}",

                        accessKeyVariable:
                        'AWS_ACCESS_KEY_ID',

                        secretKeyVariable:
                        'AWS_SECRET_ACCESS_KEY'
                    ]

                ]) {

                    dir('terraform') {

                        bat '''

                            echo.
                            echo ===== TERRAFORM APPLY =====

                            terraform apply ^
                              -input=false ^
                              -auto-approve ^
                              tfplan

                        '''
                    }
                }
            }
        }


        // ======================================================
        // 06 - AWS OUTPUT
        // ======================================================

        stage('06 - Get AWS Outputs') {

            agent {
                label 'built-in'
            }

            steps {

                withCredentials([

                    [
                        $class:
                        'AmazonWebServicesCredentialsBinding',

                        credentialsId:
                        "${AWS_CREDENTIALS}",

                        accessKeyVariable:
                        'AWS_ACCESS_KEY_ID',

                        secretKeyVariable:
                        'AWS_SECRET_ACCESS_KEY'
                    ]

                ]) {

                    dir('terraform') {

                        bat '''

                            echo.
                            echo ===== EC2 PUBLIC IP =====

                            terraform output ec2_public_ip


                            echo.
                            echo ===== EKS CLUSTER =====

                            terraform output eks_cluster_name


                            echo.
                            echo ===== EKS ENDPOINT =====

                            terraform output eks_cluster_endpoint

                        '''
                    }
                }
            }
        }


        // ======================================================
        // 07 - GENERATE ANSIBLE INVENTORY
        // ======================================================

        stage('07 - Generate Ansible Inventory') {

            agent {
                label 'built-in'
            }

            steps {

                bat '''

                    echo.
                    echo ===== GET EC2 IP =====


                    cd terraform


                    for /f %%i in (
                        'terraform output -raw ec2_public_ip'
                    ) do set EC2_IP=%%i


                    cd ..


                    echo EC2 IP:

                    echo %EC2_IP%


                    echo.
                    echo ===== GENERATING INVENTORY =====


                    powershell -NoProfile -Command ^
                    "$content = '[servers]`nserver ansible_host=%EC2_IP% ansible_user=ubuntu'; ^
                    Set-Content -Path 'ansible\\inventory.ini' -Value $content"

                '''
            }
        }


        // ======================================================
        // 08 - ANSIBLE
        // ======================================================

        stage('08 - Ansible Configuration') {

            agent {
                label 'built-in'
            }

            steps {

                echo '''
                ============================================

                WINDOWS JENKINS

                       ↓

                WSL2 + UBUNTU

                       ↓

                ANSIBLE

                       ↓

                AWS EC2

                ============================================
                '''


                bat '''

                    echo.
                    echo ===== CHECK ANSIBLE =====


                    wsl.exe -d Ubuntu -- bash -lc ^
                    "ansible --version"


                    echo.
                    echo ===== RUN ANSIBLE =====


                    wsl.exe -d Ubuntu -- bash -lc ^
                    "cd /mnt/c/ProgramData/Jenkins/.jenkins/workspace/ecommerce-port-design && ^
                    ansible-playbook ^
                    -i ansible/inventory.ini ^
                    ansible/playbook.yml"

                '''
            }
        }


        // ======================================================
        // 09 - SONARQUBE
        // ======================================================

        stage('09 - SonarQube Analysis') {

            agent {
                label 'built-in'
            }

            steps {

                echo '============================================'

                echo 'SONARQUBE CODE ANALYSIS'

                echo '============================================'


                script {

                    def scannerHome =
                        tool 'SonarScanner'


                    withSonarQubeEnv('SonarQube') {

                        bat """

                            "${scannerHome}\\bin\\sonar-scanner.bat"

                        """
                    }
                }
            }
        }


        // ======================================================
        // 10 - SONARQUBE QUALITY GATE
        // ======================================================

        stage('10 - SonarQube Quality Gate') {

            agent {
                label 'built-in'
            }

            steps {

                echo '============================================'

                echo 'WAITING FOR SONARQUBE QUALITY GATE'

                echo '============================================'


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


        // ======================================================
        // 11 - DOCKER BUILD
        // ======================================================

        stage('11 - Docker Build') {

            agent {
                label 'built-in'
            }

            steps {

                echo '============================================'

                echo "BUILDING IMAGE: ${FULL_IMAGE}"

                echo '============================================'


                bat """

                    docker version


                    docker build ^
                      --pull ^
                      -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ^
                      -t ${DOCKER_IMAGE}:latest ^
                      .


                    echo.
                    echo ===== CREATED IMAGES =====


                    docker images ${DOCKER_IMAGE}

                """
            }
        }


        // ======================================================
        // 12 - DOCKER TEST
        // ======================================================

        stage('12 - Docker Container Test') {

            agent {
                label 'built-in'
            }

            steps {

                bat """

                    echo ===== REMOVE OLD TEST CONTAINER =====


                    docker rm -f ecommerce-test 2>NUL || exit 0


                    echo ===== START TEST CONTAINER =====


                    docker run -d ^
                      --name ecommerce-test ^
                      -p 8090:80 ^
                      ${DOCKER_IMAGE}:${BUILD_NUMBER}


                    timeout /t 8 /nobreak


                    echo ===== HEALTH CHECK =====


                    curl.exe -f http://localhost:8090/health


                    echo ===== TEST SUCCESS =====


                    docker rm -f ecommerce-test

                """
            }
        }


        // ======================================================
        // 13 - TRIVY
        // ======================================================

        stage('13 - Trivy Security Scan') {

            agent {
                label 'built-in'
            }

            steps {

                echo '============================================'

                echo "TRIVY SCANNING: ${FULL_IMAGE}"

                echo '============================================'


                bat """

                    trivy image ^
                      --severity HIGH,CRITICAL ^
                      --ignore-unfixed ^
                      --exit-code 1 ^
                      ${DOCKER_IMAGE}:${BUILD_NUMBER}

                """
            }
        }


        // ======================================================
        // 14 - DOCKER HUB PUSH
        // ======================================================

        stage('14 - Docker Hub Push') {

            agent {
                label 'built-in'
            }

            steps {

                echo '============================================'

                echo "PUSHING: ${FULL_IMAGE}"

                echo '============================================'


                withCredentials([

                    usernamePassword(

                        credentialsId:
                        "${DOCKERHUB_CREDENTIALS}",

                        usernameVariable:
                        'DOCKER_USERNAME',

                        passwordVariable:
                        'DOCKER_PASSWORD'
                    )

                ]) {

                    bat """

                        docker login ^
                          -u %DOCKER_USERNAME% ^
                          -p %DOCKER_PASSWORD%


                        echo.
                        echo ===== PUSH BUILD TAG =====


                        docker push ^
                          ${DOCKER_IMAGE}:${BUILD_NUMBER}


                        echo.
                        echo ===== PUSH LATEST =====


                        docker push ^
                          ${DOCKER_IMAGE}:latest


                        docker logout

                    """
                }
            }
        }


        // ======================================================
        // 15 - EKS LOGIN
        // ======================================================

        stage('15 - Connect to AWS EKS') {

            agent {
                label 'built-in'
            }

            steps {

                withCredentials([

                    [
                        $class:
                        'AmazonWebServicesCredentialsBinding',

                        credentialsId:
                        "${AWS_CREDENTIALS}",

                        accessKeyVariable:
                        'AWS_ACCESS_KEY_ID',

                        secretKeyVariable:
                        'AWS_SECRET_ACCESS_KEY'
                    ]

                ]) {

                    bat """

                        echo ===== AWS IDENTITY =====


                        aws sts get-caller-identity


                        echo.
                        echo ===== UPDATE KUBECONFIG =====


                        aws eks update-kubeconfig ^
                          --region ${AWS_DEFAULT_REGION} ^
                          --name ${EKS_CLUSTER_NAME}


                        echo.
                        echo ===== EKS NODES =====


                        kubectl get nodes

                    """
                }
            }
        }


        // ======================================================
        // 16 - METRICS SERVER
        // ======================================================

        stage('16 - Metrics Server') {

            agent {
                label 'built-in'
            }

            steps {

                bat '''

                    helm repo add metrics-server ^
                    https://kubernetes-sigs.github.io/metrics-server/


                    helm repo update


                    helm upgrade --install metrics-server ^
                    metrics-server/metrics-server ^
                    --namespace kube-system ^
                    --set args[0]=--kubelet-insecure-tls

                '''
            }
        }


        // ======================================================
        // 17 - KUBERNETES NAMESPACE
        // ======================================================

        stage('17 - Kubernetes Namespace') {

            agent {
                label 'built-in'
            }

            steps {

                bat '''

                    kubectl apply ^
                    -f k8s/namespace.yaml

                '''
            }
        }


        // ======================================================
        // 18 - KUBERNETES RESOURCES
        // ======================================================

        stage('18 - Kubernetes Resources') {

            agent {
                label 'built-in'
            }

            steps {

                bat """

                    kubectl apply ^
                      -f k8s/deployment.yaml


                    kubectl apply ^
                      -f k8s/service.yaml


                    kubectl apply ^
                      -f k8s/hpa.yaml


                    kubectl apply ^
                      -f k8s/ingress.yaml

                """
            }
        }


        // ======================================================
        // 19 - KUBERNETES IMAGE UPDATE
        // ======================================================

        stage('19 - Kubernetes Rolling Update') {

            agent {
                label 'built-in'
            }

            steps {

                echo '============================================'

                echo "DEPLOYING IMAGE: ${FULL_IMAGE}"

                echo '============================================'


                bat """

                    kubectl set image ^
                      deployment/${K8S_DEPLOYMENT} ^
                      ${K8S_CONTAINER}=${DOCKER_IMAGE}:${BUILD_NUMBER} ^
                      --namespace ${K8S_NAMESPACE}


                    echo.
                    echo ===== ROLLOUT STATUS =====


                    kubectl rollout status ^
                      deployment/${K8S_DEPLOYMENT} ^
                      --namespace ${K8S_NAMESPACE} ^
                      --timeout=5m

                """
            }
        }


        // ======================================================
        // 20 - MONITORING
        // ======================================================

        stage('20 - Prometheus Grafana Alertmanager') {

            agent {
                label 'built-in'
            }

            steps {

                echo '''
                ============================================

                KUBERNETES MONITORING

                Prometheus
                Grafana
                Alertmanager

                ============================================
                '''


                bat '''

                    helm repo add prometheus-community ^
                    https://prometheus-community.github.io/helm-charts


                    helm repo update


                    helm upgrade --install monitoring ^
                    prometheus-community/kube-prometheus-stack ^
                    --namespace monitoring ^
                    --create-namespace ^
                    --set grafana.service.type=ClusterIP ^
                    --set prometheus.prometheusSpec.retention=7d ^
                    --set alertmanager.enabled=true

                '''
            }
        }


        // ======================================================
        // 21 - FINAL VERIFICATION
        // ======================================================

        stage('21 - Final Verification') {

            agent {
                label 'built-in'
            }

            steps {

                bat """

                    echo.
                    echo ============================================
                    echo DOCKER IMAGE
                    echo ============================================


                    echo ${FULL_IMAGE}


                    echo.
                    echo ============================================
                    echo APPLICATION PODS
                    echo ============================================


                    kubectl get pods ^
                      --namespace ${K8S_NAMESPACE}


                    echo.
                    echo ============================================
                    echo SERVICES
                    echo ============================================


                    kubectl get services ^
                      --namespace ${K8S_NAMESPACE}


                    echo.
                    echo ============================================
                    echo HPA
                    echo ============================================


                    kubectl get hpa ^
                      --namespace ${K8S_NAMESPACE}


                    echo.
                    echo ============================================
                    echo INGRESS
                    echo ============================================


                    kubectl get ingress ^
                      --namespace ${K8S_NAMESPACE}


                    echo.
                    echo ============================================
                    echo MONITORING
                    echo ============================================


                    kubectl get pods ^
                      --namespace monitoring


                    echo.
                    echo ============================================
                    echo PIPELINE SUCCESSFULLY COMPLETED
                    echo ============================================

                """
            }
        }
    }


    // ==========================================================
    // POST ACTIONS
    // ==========================================================

    post {

        success {

            echo """

            ================================================

            CI/CD PIPELINE SUCCESS

            BUILD NUMBER:
            ${BUILD_NUMBER}

            DOCKER IMAGE:
            ${FULL_IMAGE}

            ================================================

            GitLab
                 ↓
            Terraform
                 ↓
            Ansible
                 ↓
            SonarQube
                 ↓
            Docker
                 ↓
            Trivy
                 ↓
            Docker Hub
                 ↓
            EKS
                 ↓
            Kubernetes
                 ↓
            Helm
                 ↓
            Prometheus
            Grafana
            Alertmanager

            ================================================

            """

        }


        failure {

            echo """

            ================================================

            CI/CD PIPELINE FAILED

            BUILD NUMBER:
            ${BUILD_NUMBER}

            CHECK JENKINS CONSOLE OUTPUT

            ================================================

            """

        }


        always {

            echo "============================================"

            echo "JOB NAME    : ${JOB_NAME}"

            echo "BUILD NUMBER: ${BUILD_NUMBER}"

            echo "IMAGE       : ${FULL_IMAGE}"

            echo "============================================"
        }
    }
}