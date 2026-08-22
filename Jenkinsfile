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

                echo "Admin CIDR           : AUTO-DETECTED IN STAGE 03"
            }
        }


        // ======================================================
        // 03 - DETECT PUBLIC IP
        // ======================================================

        stage('03 - Detect Public IP') {

            agent {
                label 'built-in'
            }

            steps {

                script {

                    echo '============================================'
                    echo 'DETECTING CURRENT PUBLIC IP'
                    echo '============================================'

                    def publicIp = bat(
                        script: '''
                            @echo off
                            powershell -NoProfile -Command "(Invoke-RestMethod 'https://api.ipify.org').Trim()"
                        ''',
                        returnStdout: true
                    ).trim()

                    def ipv4Pattern = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/

                    if (!publicIp || !(publicIp ==~ ipv4Pattern)) {
                        error("Unable to detect a valid IPv4 public IP. Detected: ${publicIp}")
                    }

                    def validOctets = publicIp.tokenize('.').every { octet ->
                        octet.isInteger() && octet.toInteger() >= 0 && octet.toInteger() <= 255
                    }

                    if (!validOctets) {
                        error("Invalid IPv4 address detected: ${publicIp}")
                    }

                    env.ADMIN_CIDR = "${publicIp}/32"

                    echo '============================================'
                    echo "ADMIN_CIDR: ${env.ADMIN_CIDR}"
                    echo '============================================'
                }
            }
        }


        // ======================================================
        // 04 - TERRAFORM INIT + VALIDATE
        // ======================================================

        stage('04 - Terraform Validate') {

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
        // 05 - TERRAFORM PLAN
        // ======================================================

        
        stage('05 - Terraform Plan') {

            agent {
                label 'built-in'
            }

            steps {

                withCredentials([

                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: "${AWS_CREDENTIALS}",
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]

                ]) {

                    dir('terraform') {

                        bat '''

                            echo.
                            echo ============================================
                            echo TERRAFORM CLEAN PLAN
                            echo ============================================

                            if exist tfplan del /f /q tfplan


                            echo.
                            echo ============================================
                            echo TERRAFORM INIT
                            echo ============================================

                            terraform init -input=false -upgrade


                            echo.
                            echo ============================================
                            echo TERRAFORM VALIDATE
                            echo ============================================

                            terraform validate

                            IF %ERRORLEVEL% NEQ 0 (
                                echo TERRAFORM VALIDATION FAILED
                                exit /b 1
                            )


                            echo.
                            echo ============================================
                            echo TERRAFORM PLAN
                            echo ============================================

                            terraform plan ^
                            -input=false ^
                            -var="aws_region=%AWS_DEFAULT_REGION%" ^
                            -var="cluster_name=%EKS_CLUSTER_NAME%" ^
                            -var="key_name=%AWS_KEYPAIR_NAME%" ^
                            -var="admin_cidr=%ADMIN_CIDR%" ^
                            -out=tfplan

                            IF %ERRORLEVEL% NEQ 0 (
                                echo TERRAFORM PLAN FAILED
                                exit /b 1
                            )


                            echo.
                            echo ============================================
                            echo TERRAFORM PLAN CREATED
                            echo ============================================

                            terraform show -no-color tfplan

                        '''
                    }
                }
            }
        }
       // ======================================================
            // 06 - TERRAFORM APPLY
       // ======================================================
    
       stage('06 - Terraform Apply') {

            agent {
                label 'built-in'
            }

            steps {

                withCredentials([

                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: "${AWS_CREDENTIALS}",
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]

                ]) {

                    dir('terraform') {

                        bat '''

                            echo.
                            echo ============================================
                            echo TERRAFORM APPLY
                            echo ============================================

                            echo.
                            echo AWS REGION:
                            echo %AWS_DEFAULT_REGION%

                            echo.
                            echo EKS CLUSTER:
                            echo %EKS_CLUSTER_NAME%


                            echo.
                            echo ============================================
                            echo TERRAFORM APPLY STARTED
                            echo ============================================

                            terraform apply ^
                            -input=false ^
                            -auto-approve ^
                            tfplan


                            IF %ERRORLEVEL% EQU 0 (

                                echo.
                                echo ============================================
                                echo TERRAFORM APPLY SUCCESSFUL
                                echo ============================================

                                echo.
                                echo ============================================
                                echo VERIFY AWS ACCOUNT
                                echo ============================================

                                aws sts get-caller-identity

                                echo.
                                echo ============================================
                                echo VERIFY EKS CLUSTER
                                echo ============================================

                                aws eks describe-cluster ^
                                --region %AWS_DEFAULT_REGION% ^
                                --name %EKS_CLUSTER_NAME% ^
                                --query "cluster.{name:name,status:status,version:version}" ^
                                --output table

                                exit /b 0
                            )


                            echo.
                            echo ============================================
                            echo TERRAFORM APPLY FAILED
                            echo EKS DIAGNOSTICS STARTED
                            echo ============================================


                            echo.
                            echo ============================================
                            echo AWS REGION
                            echo ============================================

                            echo %AWS_DEFAULT_REGION%


                            echo.
                            echo ============================================
                            echo AWS ACCOUNT / IDENTITY
                            echo ============================================

                            aws sts get-caller-identity


                            echo.
                            echo ============================================
                            echo EKS CLUSTER STATUS
                            echo ============================================

                            aws eks describe-cluster ^
                            --region %AWS_DEFAULT_REGION% ^
                            --name %EKS_CLUSTER_NAME% ^
                            --query "cluster.{name:name,status:status,version:version,endpoint:endpoint}" ^
                            --output table


                            echo.
                            echo ============================================
                            echo EKS NODE GROUPS
                            echo ============================================

                            aws eks list-nodegroups ^
                            --region %AWS_DEFAULT_REGION% ^
                            --cluster-name %EKS_CLUSTER_NAME% ^
                            --output table


                            echo.
                            echo ============================================
                            echo NODE GROUP DETAILS
                            echo ============================================

                            for /f "delims=" %%N in ('aws eks list-nodegroups --region %AWS_DEFAULT_REGION% --cluster-name %EKS_CLUSTER_NAME% --query "nodegroups[]" --output text') do (

                                echo.
                                echo --------------------------------------------
                                echo NODE GROUP: %%N
                                echo --------------------------------------------

                                aws eks describe-nodegroup ^
                                --region %AWS_DEFAULT_REGION% ^
                                --cluster-name %EKS_CLUSTER_NAME% ^
                                --nodegroup-name "%%N" ^
                                --query "nodegroup.{name:nodegroupName,status:status,ami:amiType,instanceTypes:instanceTypes,capacityType:capacityType,desired:scalingConfig.desiredSize,min:scalingConfig.minSize,max:scalingConfig.maxSize,issues:health.issues}" ^
                                --output json

                            )


                            echo.
                            echo ============================================
                            echo EC2 INSTANCES
                            echo ============================================

                            aws ec2 describe-instances ^
                            --region %AWS_DEFAULT_REGION% ^
                            --filters "Name=tag:eks:nodegroup-name,Values=ecommerce-node-group" ^
                            --query "Reservations[].Instances[].{InstanceId:InstanceId,State:State.Name,PrivateIP:PrivateIpAddress,PublicIP:PublicIpAddress,InstanceType:InstanceType}" ^
                            --output table


                            echo.
                            echo ============================================
                            echo EKS NODE GROUP HEALTH ISSUES
                            echo ============================================

                            for /f "delims=" %%N in ('aws eks list-nodegroups --region %AWS_DEFAULT_REGION% --cluster-name %EKS_CLUSTER_NAME% --query "nodegroups[]" --output text') do (

                                echo.
                                echo --------------------------------------------
                                echo HEALTH CHECK: %%N
                                echo --------------------------------------------

                                aws eks describe-nodegroup ^
                                --region %AWS_DEFAULT_REGION% ^
                                --cluster-name %EKS_CLUSTER_NAME% ^
                                --nodegroup-name "%%N" ^
                                --query "nodegroup.health.issues" ^
                                --output json

                            )


                            echo.
                            echo ============================================
                            echo TERRAFORM APPLY FAILED
                            echo ============================================

                            exit /b 1

                        '''
                    }
                }
            }
        }


        // ======================================================
        // 07 - AWS OUTPUTS
        // ======================================================

        stage('07 - AWS Infrastructure Output') {

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
        // 08 - ANSIBLE
        // ======================================================

          stage('08 - Ansible Configuration') {

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

                                Write-Host "============================================"
                                Write-Host "===== ANSIBLE VERSION ====="
                                Write-Host "============================================"

                                wsl.exe -d Ubuntu -- bash -lc "ansible --version"

                                if ($LASTEXITCODE -ne 0) {
                                    throw "Ansible is not available inside WSL2 Ubuntu."
                                }


                                Write-Host "============================================"
                                Write-Host "===== EC2 IP ====="
                                Write-Host "============================================"

                                $ec2Ip = (
                                    terraform -chdir=terraform output -raw ec2_public_ip
                                ).Trim()

                                if ([string]::IsNullOrWhiteSpace($ec2Ip)) {
                                    throw "EC2 Public IP was not returned by Terraform."
                                }

                                Write-Host "EC2 IP: $ec2Ip"


                                Write-Host "============================================"
                                Write-Host "===== WSL WORKSPACE ====="
                                Write-Host "============================================"

                                $windowsWorkspace = $env:WORKSPACE

                                if ([string]::IsNullOrWhiteSpace($windowsWorkspace)) {
                                    throw "Jenkins WORKSPACE variable is empty."
                                }

                                Write-Host "Windows Workspace: $windowsWorkspace"


                                # Get Windows drive letter
                                $drive = $windowsWorkspace.Substring(0,1).ToLower()


                                # Remove C: / D: etc.
                                # Convert Windows backslash character (ASCII 92)
                                # to Linux forward slash (ASCII 47)

                                $pathWithoutDrive = $windowsWorkspace.Substring(2).Replace([char]92, [char]47)


                                # Build WSL path

                                $wslWorkspace = "/mnt/$drive$pathWithoutDrive"


                                Write-Host "WSL Workspace: $wslWorkspace"


                                Write-Host "===== VERIFY WSL WORKSPACE ====="

                                wsl.exe -d Ubuntu -- bash -lc "test -d '$wslWorkspace'"

                                if ($LASTEXITCODE -ne 0) {
                                    throw "WSL workspace does not exist: $wslWorkspace"
                                }

                                Write-Host "WSL workspace verified successfully."


                                Write-Host "============================================"
                                Write-Host "===== COPY SSH KEY TO WSL ====="
                                Write-Host "============================================"


                                $windowsKeyPath = $env:EC2_KEY_FILE

                                if ([string]::IsNullOrWhiteSpace($windowsKeyPath)) {
                                    throw "EC2_KEY_FILE variable is empty."
                                }


                                Write-Host "Windows SSH Key: $windowsKeyPath"


                                # SSH key drive

                                $keyDrive = $windowsKeyPath.Substring(0,1).ToLower()


                                # Convert Windows SSH path to WSL path

                                $keyPathWithoutDrive = $windowsKeyPath.Substring(2).Replace([char]92, [char]47)


                                $wslKeySource = "/mnt/$keyDrive$keyPathWithoutDrive"


                                Write-Host "WSL SSH Key: $wslKeySource"


                                Write-Host "===== VERIFY SSH KEY ====="


                                wsl.exe -d Ubuntu -- bash -lc "test -f '$wslKeySource'"

                                if ($LASTEXITCODE -ne 0) {
                                    throw "SSH private key was not found: $wslKeySource"
                                }

                                Write-Host "SSH private key found successfully."


                                Write-Host "===== COPY SSH KEY INTO WSL ====="


                                wsl.exe -d Ubuntu -- bash -lc "cp '$wslKeySource' /tmp/jenkins-ec2-key.pem && chmod 600 /tmp/jenkins-ec2-key.pem"

                                if ($LASTEXITCODE -ne 0) {
                                    throw "Failed to copy SSH private key into WSL2."
                                }

                                Write-Host "SSH private key copied successfully."


                                Write-Host "============================================"
                                Write-Host "===== CREATE ANSIBLE INVENTORY ====="
                                Write-Host "============================================"


                                $inventory = @(
                                    "[servers]"
                                    "server ansible_host=$ec2Ip ansible_user=$env:EC2_USER ansible_ssh_private_key_file=/tmp/jenkins-ec2-key.pem"
                                ) -join "`r`n"


                                $ansibleDirectory = Join-Path $env:WORKSPACE "ansible"


                                if (-not (Test-Path $ansibleDirectory)) {
                                    throw "Ansible directory does not exist: $ansibleDirectory"
                                }


                                $inventoryPath = Join-Path $ansibleDirectory "inventory"


                                Set-Content `
                                    -Path $inventoryPath `
                                    -Value $inventory `
                                    -Encoding UTF8


                                Write-Host "Ansible inventory created successfully."
                                Write-Host "Inventory path: $inventoryPath"


                                Write-Host "============================================"
                                Write-Host "===== TEST SSH THROUGH ANSIBLE ====="
                                Write-Host "============================================"


                                wsl.exe -d Ubuntu -- bash -lc "cd '$wslWorkspace' && export ANSIBLE_CONFIG=ansible/ansible.cfg && ansible -i ansible/inventory servers -m ping"


                                if ($LASTEXITCODE -ne 0) {
                                    throw "Ansible SSH connectivity test failed."
                                }


                                Write-Host "============================================"
                                Write-Host "===== ANSIBLE SSH CONNECTION SUCCESSFUL ====="
                                Write-Host "============================================"


                                Write-Host "============================================"
                                Write-Host "===== RUN ANSIBLE PLAYBOOK ====="
                                Write-Host "============================================"


                                wsl.exe -d Ubuntu -- bash -lc "cd '$wslWorkspace' && export ANSIBLE_CONFIG=ansible/ansible.cfg && ansible-playbook -i ansible/inventory ansible/playbook.yml"


                                if ($LASTEXITCODE -ne 0) {
                                    throw "Ansible playbook execution failed."
                                }


                                Write-Host "============================================"
                                Write-Host "===== ANSIBLE COMPLETED SUCCESSFULLY ====="
                                Write-Host "============================================"

                            }


                            finally {

                                Write-Host "============================================"
                                Write-Host "===== REMOVE TEMP SSH KEY ====="
                                Write-Host "============================================"


                                wsl.exe -d Ubuntu -- bash -lc "rm -f /tmp/jenkins-ec2-key.pem"


                                if ($LASTEXITCODE -eq 0) {
                                    Write-Host "Temporary SSH key removed successfully."
                                }

                            }

                        '''
                    }
                }
            }
        }
        

        // ======================================================
        // ======================================================
        // 09 - SONARQUBE ANALYSIS
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

                    def scannerHome = tool 'SonarScanner'

                    echo "SonarScanner Home: ${scannerHome}"

                    withSonarQubeEnv('SonarQube') {

                        bat """
                            @echo off

                            echo ============================================
                            echo SONARQUBE ENVIRONMENT
                            echo ============================================

                            echo SONAR_HOST_URL=%SONAR_HOST_URL%

                            echo.
                            echo ============================================
                            echo SONAR SCANNER VERSION
                            echo ============================================

                            "${scannerHome}\\bin\\sonar-scanner.bat" --version

                            if %ERRORLEVEL% NEQ 0 (
                                echo SonarScanner failed to start.
                                exit /b %ERRORLEVEL%
                            )

                            echo.
                            echo ============================================
                            echo STARTING SONARQUBE ANALYSIS
                            echo ============================================

                            "${scannerHome}\\bin\\sonar-scanner.bat" ^
                                -Dsonar.projectKey=ecommerce-port-design ^
                                -Dsonar.projectName=ecommerce-port-design ^
                                -Dsonar.sources=. ^
                                -Dsonar.host.url=%SONAR_HOST_URL%

                            if %ERRORLEVEL% NEQ 0 (
                                echo ============================================
                                echo SONARQUBE ANALYSIS FAILED
                                echo ============================================
                                exit /b %ERRORLEVEL%
                            )

                            echo.
                            echo ============================================
                            echo SONARQUBE ANALYSIS COMPLETED
                            echo ============================================
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
                echo 'SONARQUBE QUALITY GATE'
                echo '============================================'


                timeout(
                    time: 10,
                    unit: 'MINUTES'
                ) {

                    script {

                        def qualityGate = waitForQualityGate(
                            abortPipeline: false
                        )


                        echo "SonarQube Quality Gate Status: ${qualityGate.status}"


                        if (qualityGate.status != 'OK') {

                            error(
                                "SonarQube Quality Gate failed with status: ${qualityGate.status}"
                            )
                        }


                        echo '============================================'
                        echo 'SONARQUBE QUALITY GATE PASSED'
                        echo '============================================'
                    }
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
        // 12 - DOCKER CONTAINER TEST
        // ======================================================

        stage('12 - Docker Test') {

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
        // 13 - TRIVY SECURITY SCAN
        // ======================================================

        stage('13 - Trivy Security Scan') {

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
        // 14 - DOCKER HUB PUSH
        // ======================================================

        stage('14 - Docker Hub Push') {

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


                        echo %DOCKER_PASSWORD% | docker login ^
                          -u %DOCKER_USERNAME% ^
                          --password-stdin


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
        // 15 - CONNECT EKS
        // ======================================================
         

            stage('15 - Connect to AWS EKS') {

            agent {
                label 'built-in'
            }

            steps {

                withCredentials([

                    [
                        $class: 'AmazonWebServicesCredentialsBinding',

                        credentialsId: "${AWS_CREDENTIALS}",

                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',

                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]

                ]) {

                    bat """

                        echo.
                        echo ============================================
                        echo AWS IDENTITY
                        echo ============================================

                        aws sts get-caller-identity


                        echo.
                        echo ============================================
                        echo AWS REGION
                        echo ============================================

                        echo %AWS_DEFAULT_REGION%

                        aws configure get region


                        echo.
                        echo ============================================
                        echo EKS CLUSTER
                        echo ============================================

                        echo Cluster Name:
                        echo ${params.EKS_CLUSTER_NAME}

                        echo Region:
                        echo %AWS_DEFAULT_REGION%


                        echo.
                        echo ============================================
                        echo EKS CLUSTER STATUS
                        echo ============================================

                        aws eks describe-cluster ^
                        --region %AWS_DEFAULT_REGION% ^
                        --name ${params.EKS_CLUSTER_NAME} ^
                        --query "cluster.{Name:name,Status:status,Version:version,Endpoint:endpoint}" ^
                        --output table


                        IF %ERRORLEVEL% NEQ 0 (

                            echo.
                            echo ============================================
                            echo EKS CLUSTER CHECK FAILED
                            echo ============================================

                            exit /b 1
                        )


                        echo.
                        echo ============================================
                        echo UPDATE KUBECONFIG
                        echo ============================================

                        aws eks update-kubeconfig ^
                        --region %AWS_DEFAULT_REGION% ^
                        --name ${params.EKS_CLUSTER_NAME}


                        IF %ERRORLEVEL% NEQ 0 (

                            echo.
                            echo ============================================
                            echo KUBECONFIG UPDATE FAILED
                            echo ============================================

                            exit /b 1
                        )


                        echo.
                        echo ============================================
                        echo KUBERNETES CLIENT VERSION
                        echo ============================================

                        kubectl version --client


                        echo.
                        echo ============================================
                        echo EKS NODES
                        echo ============================================

                        kubectl get nodes -o wide


                        IF %ERRORLEVEL% NEQ 0 (

                            echo.
                            echo ============================================
                            echo KUBERNETES NODE CHECK FAILED
                            echo ============================================

                            exit /b 1
                        )


                        echo.
                        echo ============================================
                        echo KUBERNETES CLUSTER INFO
                        echo ============================================

                        kubectl cluster-info


                        IF %ERRORLEVEL% NEQ 0 (

                            echo.
                            echo ============================================
                            echo KUBERNETES CONNECTION FAILED
                            echo ============================================

                            exit /b 1
                        )


                        echo.
                        echo ============================================
                        echo EKS CONNECTION SUCCESSFUL
                        echo ============================================

                    """
                }
            }
        }



        // ======================================================
        // 16 - KUBERNETES NAMESPACE
        // ======================================================

        stage('16 - Kubernetes Namespace') {

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
        // 17 - KUBERNETES DEPLOYMENT
        // ======================================================

        stage('17 - Kubernetes Deployment') {

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
        // 18 - KUBERNETES IMAGE UPDATE
        // ======================================================

        stage('18 - Kubernetes Rolling Update') {

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
        // 19 - VERIFY KUBERNETES
        // ======================================================

        stage('19 - Kubernetes Verification') {

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
        // 20 - INSTALL MONITORING
        // ======================================================

        stage('20 - Install Monitoring') {

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
        // 21 - MONITORING VERIFICATION
        // ======================================================

        stage('21 - Monitoring Verification') {

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
        // 22 - FINAL VERIFICATION
        // ======================================================

        stage('22 - Final Verification') {

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