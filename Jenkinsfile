pipeline {

    /*
     * ============================================================
     * ECOMMERCE PORT DESIGN
     * COMPLETE CI/CD PIPELINE
     *
     * GitLab
     *    ↓
     * Jenkins - Windows
     *    ↓
     * Terraform
     *    ↓
     * AWS VPC + EC2 + EKS
     *    ↓
     * Ansible - WSL2 Ubuntu
     *    ↓
     * SonarQube
     *    ↓
     * Docker Build
     *    ↓
     * Docker Test
     *    ↓
     * Trivy
     *    ↓
     * Docker Hub
     *    ↓
     * EKS
     *    ↓
     * Kubernetes
     *    ↓
     * Prometheus
     * Grafana
     * Alertmanager
     * ============================================================
     */

    agent none


    // ==========================================================
    // PARAMETERS
    // ==========================================================

    parameters {

        string(
            name: 'AWS_REGION',
            defaultValue: 'ap-south-1',
            description: 'AWS Region'
        )

        string(
            name: 'EKS_CLUSTER_NAME',
            defaultValue: 'ecommerce-eks',
            description: 'EKS Cluster Name'
        )

        string(
            name: 'AWS_KEYPAIR_NAME',
            defaultValue: 'ecommerce-devops-key',
            description: 'AWS EC2 Key Pair name'
        )

        string(
            name: 'ADMIN_CIDR',
            defaultValue: 'YOUR_PUBLIC_IP/32',
            description: 'Public IP allowed to SSH into EC2'
        )
    }


    // ==========================================================
    // ENVIRONMENT
    // ==========================================================

    environment {

        // ------------------------------------------------------
        // GITLAB
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


        // ------------------------------------------------------
        // DOCKER
        // ------------------------------------------------------

        DOCKER_IMAGE =
            'shivsoftapp/ecommerce-port-design'

        IMAGE_TAG =
            "${BUILD_NUMBER}"

        FULL_IMAGE =
            "shivsoftapp/ecommerce-port-design:${BUILD_NUMBER}"


        // ------------------------------------------------------
        // KUBERNETES
        // ------------------------------------------------------

        K8S_NAMESPACE =
            'ecommerce'

        K8S_DEPLOYMENT =
            'ecommerce-port-design'

        K8S_CONTAINER =
            'ecommerce-port-design'


        // ------------------------------------------------------
        // JENKINS CREDENTIALS
        // ------------------------------------------------------

        GITLAB_CREDENTIALS =
            'gitlab-credentials'

        AWS_CREDENTIALS =
            'aws-credentials'

        DOCKERHUB_CREDENTIALS =
            'dockerhub-credentials'

        SONARQUBE_CREDENTIALS =
            'sonarqube-token'

        EC2_SSH_CREDENTIALS =
            'ec2-ssh-key'
    }


    // ==========================================================
    // OPTIONS
    // ==========================================================

    options {

        disableConcurrentBuilds()

        timestamps()

        skipDefaultCheckout(true)

        timeout(
            time: 120,
            unit: 'MINUTES'
        )

        buildDiscarder(
            logRotator(
                numToKeepStr: '10'
            )
        )
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
                echo 'GITLAB CHECKOUT'
                echo '============================================'

                git(
                    url: "${GITLAB_REPO}",
                    branch: "${GITLAB_BRANCH}",
                    credentialsId: "${GITLAB_CREDENTIALS}"
                )

                bat '''
                    echo.
                    echo ===== BRANCH =====
                    git branch

                    echo.
                    echo ===== COMMIT =====
                    git log -1 --oneline

                    echo.
                    echo ===== REMOTE =====
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

                echo "Jenkins Build Number : ${BUILD_NUMBER}"

                echo "Docker Image         : ${FULL_IMAGE}"

                echo "GitLab Branch        : ${GITLAB_BRANCH}"

                echo "AWS Region           : ${AWS_DEFAULT_REGION}"

                echo "EKS Cluster          : ${EKS_CLUSTER_NAME}"

                echo "AWS Key Pair         : ${params.AWS_KEYPAIR_NAME}"

                echo "Admin CIDR           : ${params.ADMIN_CIDR}"
            }
        }


        // ======================================================
        // 03 - TERRAFORM INIT + VALIDATE
        // ======================================================

        stage('03 - Terraform Validate') {

            agent {
                label 'built-in'
            }

            steps {

                dir('terraform') {

                    bat '''
                        echo ===== TERRAFORM VERSION =====

                        terraform version


                        echo ===== TERRAFORM INIT =====

                        terraform init -input=false


                        echo ===== TERRAFORM FORMAT =====

                        terraform fmt -check


                        echo ===== TERRAFORM VALIDATE =====

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

                            echo ===== AWS ACCOUNT =====

                            aws sts get-caller-identity


                            echo ===== TERRAFORM PLAN =====


                            terraform plan ^
                              -input=false ^
                              -var="aws_region=%AWS_DEFAULT_REGION%" ^
                              -var="cluster_name=%EKS_CLUSTER_NAME%" ^
                              -var="key_name=%AWS_KEYPAIR_NAME%" ^
                              -var="admin_cidr=%ADMIN_CIDR%" ^
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
        // 06 - AWS OUTPUTS
        // ======================================================

        stage('06 - AWS Infrastructure Output') {

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
                            echo ========================================
                            echo EC2 PUBLIC IP
                            echo ========================================

                            terraform output ec2_public_ip


                            echo.
                            echo ========================================
                            echo EC2 PRIVATE IP
                            echo ========================================

                            terraform output ec2_private_ip


                            echo.
                            echo ========================================
                            echo EKS CLUSTER
                            echo ========================================

                            terraform output eks_cluster_name


                            echo.
                            echo ========================================
                            echo EKS ENDPOINT
                            echo ========================================

                            terraform output eks_cluster_endpoint

                        '''
                    }
                }
            }
        }


        // ======================================================
        // 07 - ANSIBLE
        // ======================================================

        stage('07 - Ansible Configuration') {

            agent {
                label 'built-in'
            }

            steps {

                script {

                    def ec2Output = bat(
                        script: '''
                            @echo off
                            cd terraform
                            terraform output -raw ec2_public_ip
                        ''',
                        returnStdout: true
                    ).trim()


                    if (!ec2Output) {

                        error(
                            'Terraform did not return ec2_public_ip. Ansible cannot continue.'
                        )
                    }


                    echo '============================================'
                    echo 'EC2 FOUND'
                    echo "EC2 PUBLIC IP: ${ec2Output}"
                    echo 'STARTING ANSIBLE'
                    echo '============================================'


                    withCredentials([

                        sshUserPrivateKey(
                            credentialsId: "${EC2_SSH_CREDENTIALS}",
                            keyFileVariable: 'EC2_KEY_FILE',
                            usernameVariable: 'EC2_USER'
                        )

                    ]) {

                        powershell '''

                            $ErrorActionPreference = "Stop"


                            try {

                                Write-Host "===== ANSIBLE VERSION ====="

                                wsl.exe -d Ubuntu -- bash -lc "ansible --version"

                                if ($LASTEXITCODE -ne 0) {
                                    throw "Ansible is not available inside WSL2 Ubuntu."
                                }


                                Write-Host "===== EC2 IP ====="

                                $ec2Ip = (
                                    terraform -chdir=terraform output -raw ec2_public_ip
                                ).Trim()

                                if ([string]::IsNullOrWhiteSpace($ec2Ip)) {
                                    throw "EC2 Public IP was not returned by Terraform."
                                }

                                Write-Host "EC2 IP: $ec2Ip"


                                Write-Host "===== WSL WORKSPACE ====="

                                $wslWorkspace = (
                                    wsl.exe -d Ubuntu -- wslpath -a "$env:WORKSPACE"
                                ).Trim()

                                if ([string]::IsNullOrWhiteSpace($wslWorkspace)) {
                                    throw "Could not convert Jenkins workspace to WSL path."
                                }

                                Write-Host "WSL Workspace: $wslWorkspace"


                                Write-Host "===== COPY SSH KEY TO WSL ====="

                                $wslKeySource = (
                                    wsl.exe -d Ubuntu -- wslpath -a "$env:EC2_KEY_FILE"
                                ).Trim()

                                wsl.exe -d Ubuntu -- bash -lc `
                                "cp '$wslKeySource' /tmp/jenkins-ec2-key.pem && chmod 600 /tmp/jenkins-ec2-key.pem"

                                if ($LASTEXITCODE -ne 0) {
                                    throw "Failed to copy SSH private key into WSL2."
                                }


                                Write-Host "===== CREATE ANSIBLE INVENTORY ====="

                                $inventory = @"
        [servers]
        jenkins-agent ansible_host=$ec2Ip ansible_user=$env:EC2_USER ansible_ssh_private_key_file=/tmp/jenkins-ec2-key.pem
        "@

                                Set-Content `
                                    -Path "$env:WORKSPACE\ansible\inventory.ini" `
                                    -Value $inventory


                                Write-Host "===== TEST SSH THROUGH ANSIBLE ====="

                                wsl.exe -d Ubuntu -- bash -lc `
                                "cd '$wslWorkspace' && ansible -i ansible/inventory.ini servers -m ping"

                                if ($LASTEXITCODE -ne 0) {
                                    throw "Ansible SSH connectivity test failed."
                                }


                                Write-Host "===== RUN ANSIBLE PLAYBOOK ====="

                                wsl.exe -d Ubuntu -- bash -lc `
                                "cd '$wslWorkspace' && ansible-playbook -i ansible/inventory.ini ansible/playbook.yml"

                                if ($LASTEXITCODE -ne 0) {
                                    throw "Ansible playbook execution failed."
                                }


                                Write-Host "===== ANSIBLE COMPLETED SUCCESSFULLY ====="

                            }

                            finally {

                                Write-Host "===== REMOVE TEMP SSH KEY ====="

                                wsl.exe -d Ubuntu -- bash -lc `
                                "rm -f /tmp/jenkins-ec2-key.pem"

                            }

                        '''
                    }
                }
            }
        }


        // ======================================================
        // 08 - SONARQUBE
        // ======================================================

        stage('08 - SonarQube Analysis') {

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
        // 09 - SONARQUBE QUALITY GATE
        // ======================================================

        stage('09 - SonarQube Quality Gate') {

            agent {
                label 'built-in'
            }

            steps {

                echo '============================================'
                echo 'SONARQUBE QUALITY GATE'
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
        // 10 - DOCKER BUILD
        // ======================================================

        stage('10 - Docker Build') {

            agent {
                label 'built-in'
            }

            steps {

                echo "BUILDING: ${FULL_IMAGE}"


                bat """

                    docker version


                    docker build ^
                      --pull ^
                      -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ^
                      -t ${DOCKER_IMAGE}:latest ^
                      .


                    echo.
                    echo ===== IMAGE CREATED =====


                    docker images ${DOCKER_IMAGE}

                """
            }
        }


        // ======================================================
        // 11 - DOCKER CONTAINER TEST
        // ======================================================

        stage('11 - Docker Test') {

            agent {
                label 'built-in'
            }

            steps {

                bat """

                    echo ===== REMOVE OLD TEST CONTAINER =====


                    docker rm -f ecommerce-test 2>NUL || exit /b 0


                    echo ===== START CONTAINER =====


                    docker run -d ^
                      --name ecommerce-test ^
                      -p 8090:80 ^
                      ${DOCKER_IMAGE}:${BUILD_NUMBER}


                    echo ===== WAITING FOR CONTAINER =====


                    timeout /t 8 /nobreak


                    echo ===== WEBSITE TEST =====


                    curl.exe -f http://localhost:8090/


                    echo ===== CONTAINER TEST PASSED =====


                    docker rm -f ecommerce-test

                """
            }
        }


        // ======================================================
        // 12 - TRIVY SECURITY SCAN
        // ======================================================

        stage('12 - Trivy Security Scan') {

            agent {
                label 'built-in'
            }

            steps {

                echo '============================================'
                echo "TRIVY SCAN: ${FULL_IMAGE}"
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
        // 13 - DOCKER HUB PUSH
        // ======================================================

        stage('13 - Docker Hub Push') {

            agent {
                label 'built-in'
            }

            steps {

                echo "PUSHING IMAGE: ${FULL_IMAGE}"


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

                        echo ===== DOCKER LOGIN =====


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


                        echo.
                        echo ===== DOCKER LOGOUT =====


                        docker logout

                    """
                }
            }
        }


        // ======================================================
        // 14 - CONNECT EKS
        // ======================================================

        stage('14 - Connect to AWS EKS') {

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
        // 15 - KUBERNETES NAMESPACE
        // ======================================================

        stage('15 - Kubernetes Namespace') {

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
        // 16 - KUBERNETES DEPLOYMENT
        // ======================================================

        stage('16 - Kubernetes Deployment') {

            agent {
                label 'built-in'
            }

            steps {

                bat '''

                    kubectl apply ^
                      -f k8s/deployment.yaml


                    kubectl apply ^
                      -f k8s/service.yaml


                    kubectl apply ^
                      -f k8s/hpa.yaml


                    kubectl apply ^
                      -f k8s/ingress.yaml

                '''
            }
        }


        // ======================================================
        // 17 - KUBERNETES IMAGE UPDATE
        // ======================================================

        stage('17 - Kubernetes Rolling Update') {

            agent {
                label 'built-in'
            }

            steps {

                echo "DEPLOYING: ${FULL_IMAGE}"


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
        // 18 - VERIFY KUBERNETES
        // ======================================================

        stage('18 - Kubernetes Verification') {

            agent {
                label 'built-in'
            }

            steps {

                bat """

                    echo.
                    echo ============================================
                    echo PODS
                    echo ============================================


                    kubectl get pods ^
                      -n ${K8S_NAMESPACE}


                    echo.
                    echo ============================================
                    echo SERVICES
                    echo ============================================


                    kubectl get svc ^
                      -n ${K8S_NAMESPACE}


                    echo.
                    echo ============================================
                    echo HPA
                    echo ============================================


                    kubectl get hpa ^
                      -n ${K8S_NAMESPACE}


                    echo.
                    echo ============================================
                    echo INGRESS
                    echo ============================================


                    kubectl get ingress ^
                      -n ${K8S_NAMESPACE}

                """
            }
        }


        // ======================================================
        // 19 - INSTALL MONITORING
        // ======================================================

        stage('19 - Install Monitoring') {

            agent {
                label 'built-in'
            }

            steps {

                withCredentials([
                    string(
                        credentialsId: 'grafana-admin-password',
                        variable: 'GRAFANA_ADMIN_PASSWORD'
                    )
                ]) {

                    bat '''

                        echo ============================================
                        echo ADD PROMETHEUS COMMUNITY HELM REPOSITORY
                        echo ============================================

                        helm repo add prometheus-community ^
                        https://prometheus-community.github.io/helm-charts

                        helm repo update


                        echo ============================================
                        echo CREATE MONITORING NAMESPACE
                        echo ============================================

                        kubectl create namespace monitoring ^
                        --dry-run=client ^
                        -o yaml ^
                        | kubectl apply -f -


                        echo ============================================
                        echo INSTALL / UPGRADE MONITORING
                        echo ============================================

                        helm upgrade --install monitoring ^
                        prometheus-community/kube-prometheus-stack ^
                        --namespace monitoring ^
                        --values k8s/monitoring-values.yaml ^
                        --set grafana.adminPassword="%GRAFANA_ADMIN_PASSWORD%" ^
                        --wait ^
                        --timeout 10m


                        echo ============================================
                        echo HELM RELEASE
                        echo ============================================

                        helm list ^
                        --namespace monitoring


                        echo ============================================
                        echo MONITORING PODS
                        echo ============================================

                        kubectl get pods ^
                        --namespace monitoring

                    '''
                }
            }
        }


        // ======================================================
        // 20 - MONITORING VERIFICATION
        // ======================================================

        stage('19 - Monitoring Verification') {

            agent {
                label 'built-in'
            }

            steps {

                echo '''
                ============================================

                PROMETHEUS
                GRAFANA
                ALERTMANAGER

                ============================================
                '''


                bat '''

                    echo ===== MONITORING NAMESPACE =====


                    kubectl get pods ^
                      -n monitoring


                    echo.


                    echo ===== MONITORING SERVICES =====


                    kubectl get svc ^
                      -n monitoring

                '''
            }
        }


        // ======================================================
        // 21 - FINAL VERIFICATION
        // ======================================================

        stage('20 - Final Verification') {

            agent {
                label 'built-in'
            }

            steps {

                bat """

                    echo.
                    echo ============================================
                    echo FINAL CI/CD VERIFICATION
                    echo ============================================


                    echo.
                    echo DOCKER IMAGE:


                    echo ${FULL_IMAGE}


                    echo.
                    echo APPLICATION:


                    kubectl get deployment ^
                      ${K8S_DEPLOYMENT} ^
                      -n ${K8S_NAMESPACE}


                    echo.
                    echo APPLICATION PODS:


                    kubectl get pods ^
                      -n ${K8S_NAMESPACE}


                    echo.
                    echo APPLICATION SERVICE:


                    kubectl get svc ^
                      -n ${K8S_NAMESPACE}


                    echo.
                    echo APPLICATION INGRESS:


                    kubectl get ingress ^
                      -n ${K8S_NAMESPACE}


                    echo.
                    echo MONITORING:


                    kubectl get pods ^
                      -n monitoring


                    echo.
                    echo ============================================
                    echo PIPELINE COMPLETED SUCCESSFULLY
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

            ==================================================

            CI/CD PIPELINE SUCCESS

            GitLab:
            ${GITLAB_REPO}

            Branch:
            ${GITLAB_BRANCH}

            Build:
            ${BUILD_NUMBER}

            Docker Image:
            ${FULL_IMAGE}

            ==================================================

            FLOW:

            GitLab
               ↓
            Jenkins
               ↓
            Terraform
               ↓
            AWS VPC + EC2 + EKS
               ↓
            Ansible / WSL2
               ↓
            SonarQube
               ↓
            Quality Gate
               ↓
            Docker Build
               ↓
            Docker Test
               ↓
            Trivy
               ↓
            Docker Hub
               ↓
            EKS
               ↓
            Kubernetes
               ↓
            Monitoring

            ==================================================

            """

        }


        failure {

            echo """

            ==================================================

            CI/CD PIPELINE FAILED

            Build:
            ${BUILD_NUMBER}

            Docker Image:
            ${FULL_IMAGE}

            Check Jenkins Console Output.

            ==================================================

            """

        }


        always {

            echo "============================================"

            echo "JOB       : ${JOB_NAME}"

            echo "BUILD     : ${BUILD_NUMBER}"

            echo "IMAGE     : ${FULL_IMAGE}"

            echo "============================================"
        }
    }
}