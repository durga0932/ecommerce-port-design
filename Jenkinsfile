
pipeline {

    agent { label 'windows' }

    parameters {
        string(name: 'AWS_REGION', defaultValue: 'ap-south-1')
        string(name: 'EKS_CLUSTER_NAME', defaultValue: 'ecommerce-eks')
        string(name: 'AWS_KEYPAIR_NAME', defaultValue: 'ecommerce-devops-key')
        string(name: 'ADMIN_CIDR', defaultValue: 'YOUR_PUBLIC_IP/32')
    }

    environment {
        GITLAB_REPO = 'https://github.com/durga0932/ecommerce-port-design.git'
        GITLAB_BRANCH = 'main'

        AWS_DEFAULT_REGION = "${params.AWS_REGION}"

        DOCKER_IMAGE = 'shivsoftapp/ecommerce-port-design'
        FULL_IMAGE = "shivsoftapp/ecommerce-port-design:${BUILD_NUMBER}"

        K8S_NAMESPACE = 'ecommerce'
        K8S_DEPLOYMENT = 'ecommerce-port-design'
        K8S_CONTAINER = 'ecommerce-port-design'

        GITLAB_CREDENTIALS = 'gitlab-credentials'
        AWS_CREDENTIALS = 'aws-credentials'
        DOCKERHUB_CREDENTIALS = 'dockerhub-credentials'
        EC2_SSH_CREDENTIALS = 'ec2-ssh-key'
    }

    options {
        disableConcurrentBuilds()
        timestamps()
        skipDefaultCheckout(true)
        timeout(time: 120, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        stage('01 - GitLab Checkout') {
            steps {
                git(
                    url: "${GITLAB_REPO}",
                    branch: "${GITLAB_BRANCH}",
                    credentialsId: "${GITLAB_CREDENTIALS}"
                )

                bat 'git log -1 --oneline'
            }
        }

        stage('02 - Build Information') {
            steps {
                echo "Build: ${BUILD_NUMBER}"
                echo "Image: ${FULL_IMAGE}"
                echo "AWS Region: ${AWS_DEFAULT_REGION}"
                echo "EKS Cluster: ${EKS_CLUSTER_NAME}"
            }
        }

        stage('03 - Terraform Validate') {
            steps {
                dir('terraform') {
                    bat '''
                        terraform version
                        terraform init -input=false
                        terraform fmt -check
                        terraform validate
                    '''
                }
            }
        }

        stage('04 - Terraform Plan') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS}",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    dir('terraform') {
                        bat '''
                            aws sts get-caller-identity

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

        stage('05 - Terraform Apply') {
            steps {
                input message: 'Approve AWS infrastructure creation?'

                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS}",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    dir('terraform') {
                        bat 'terraform apply -input=false tfplan'
                    }
                }
            }
        }

        stage('06 - AWS Outputs') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS}",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    dir('terraform') {
                        bat '''
                            terraform output ec2_public_ip
                            terraform output ec2_private_ip
                            terraform output eks_cluster_name
                            terraform output eks_cluster_endpoint
                        '''
                    }
                }
            }
        }

        stage('07 - Ansible Configuration') {
            steps {
                script {
                    def ec2Ip = bat(
                        script: '@echo off\r\ncd terraform && terraform output -raw ec2_public_ip',
                        returnStdout: true
                    ).trim()

                    if (!ec2Ip) {
                        error('EC2 public IP not found.')
                    }

                    withCredentials([
                        sshUserPrivateKey(
                            credentialsId: "${EC2_SSH_CREDENTIALS}",
                            keyFileVariable: 'EC2_KEY_FILE',
                            usernameVariable: 'EC2_USER'
                        )
                    ]) {
                        withEnv(["EC2_HOST=${ec2Ip}"]) {
                            powershell '''
                                $ErrorActionPreference = "Stop"

                                try {
                                    $wslWorkspace = (
                                        wsl.exe -d Ubuntu -- wslpath -a "$env:WORKSPACE"
                                    ).Trim()

                                    $wslKey = (
                                        wsl.exe -d Ubuntu -- wslpath -a "$env:EC2_KEY_FILE"
                                    ).Trim()

                                    if (!$wslWorkspace -or !$wslKey) {
                                        throw "Unable to locate WSL workspace or SSH key."
                                    }

                                    wsl.exe -d Ubuntu -- bash -lc `
                                      "cp '$wslKey' /tmp/jenkins-ec2-key.pem && chmod 600 /tmp/jenkins-ec2-key.pem"

                                    if ($LASTEXITCODE -ne 0) {
                                        throw "SSH key copy failed."
                                    }

                                    $inventory = @"
[servers]
ecommerce-server ansible_host=$env:EC2_HOST ansible_user=$env:EC2_USER ansible_ssh_private_key_file=/tmp/jenkins-ec2-key.pem
"@

                                    Set-Content "$env:WORKSPACE\\ansible\\inventory.ini" $inventory

                                    wsl.exe -d Ubuntu -- bash -lc `
                                      "cd '$wslWorkspace' && ansible -i ansible/inventory.ini servers -m ping"

                                    if ($LASTEXITCODE -ne 0) {
                                        throw "Ansible connectivity failed."
                                    }

                                    wsl.exe -d Ubuntu -- bash -lc `
                                      "cd '$wslWorkspace' && ansible-playbook -i ansible/inventory.ini ansible/playbook.yml"

                                    if ($LASTEXITCODE -ne 0) {
                                        throw "Ansible playbook failed."
                                    }
                                }
                                finally {
                                    wsl.exe -d Ubuntu -- bash -lc "rm -f /tmp/jenkins-ec2-key.pem"
                                }
                            '''
                        }
                    }
                }
            }
        }

        stage('08 - SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'

                    withSonarQubeEnv('SonarQube') {
                        bat "\"${scannerHome}\\bin\\sonar-scanner.bat\""
                    }
                }
            }
        }

        stage('09 - SonarQube Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('10 - Docker Build') {
            steps {
                bat '''
                    docker version

                    docker build --pull ^
                      -t %DOCKER_IMAGE%:%BUILD_NUMBER% ^
                      -t %DOCKER_IMAGE%:latest .
                '''
            }
        }

        stage('11 - Docker Test') {
            steps {
                bat '''
                    docker rm -f ecommerce-test 2>NUL

                    docker run -d ^
                      --name ecommerce-test ^
                      -p 8090:80 ^
                      %DOCKER_IMAGE%:%BUILD_NUMBER%

                    timeout /t 10 /nobreak

                    curl.exe -f http://localhost:8090/

                    docker rm -f ecommerce-test
                '''
            }
        }

        stage('12 - Trivy Security Scan') {
            steps {
                bat '''
                    trivy image ^
                      --severity HIGH,CRITICAL ^
                      --ignore-unfixed ^
                      --exit-code 1 ^
                      %DOCKER_IMAGE%:%BUILD_NUMBER%
                '''
            }
        }

        stage('13 - Docker Hub Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: "${DOCKERHUB_CREDENTIALS}",
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    bat '''
                        @echo off
                        docker login -u "%DOCKER_USERNAME%" --password-stdin <<< "%DOCKER_PASSWORD%"
                        docker push %DOCKER_IMAGE%:%BUILD_NUMBER%
                        docker push %DOCKER_IMAGE%:latest
                        docker logout
                    '''
                }
            }
        }

        stage('14 - Connect to AWS EKS') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS}",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    bat '''
                        aws sts get-caller-identity

                        aws eks update-kubeconfig ^
                          --region %AWS_DEFAULT_REGION% ^
                          --name %EKS_CLUSTER_NAME%

                        kubectl get nodes
                    '''
                }
            }
        }

        stage('15 - Kubernetes Deployment') {
            steps {
                bat '''
                    kubectl apply -f k8s/namespace.yaml
                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml
                    kubectl apply -f k8s/hpa.yaml
                    kubectl apply -f k8s/ingress.yaml
                '''
            }
        }

        stage('16 - Kubernetes Rolling Update') {
            steps {
                bat '''
                    kubectl set image ^
                      deployment/%K8S_DEPLOYMENT% ^
                      %K8S_CONTAINER%=%DOCKER_IMAGE%:%BUILD_NUMBER% ^
                      -n %K8S_NAMESPACE%

                    kubectl rollout status ^
                      deployment/%K8S_DEPLOYMENT% ^
                      -n %K8S_NAMESPACE% ^
                      --timeout=5m
                '''
            }
        }

        stage('17 - Kubernetes Verification') {
            steps {
                bat '''
                    kubectl get pods -n %K8S_NAMESPACE%
                    kubectl get svc -n %K8S_NAMESPACE%
                    kubectl get hpa -n %K8S_NAMESPACE%
                    kubectl get ingress -n %K8S_NAMESPACE%
                '''
            }
        }

        stage('18 - Install Monitoring') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'grafana-admin-password',
                        variable: 'GRAFANA_ADMIN_PASSWORD'
                    )
                ]) {
                    bat '''
                        helm repo add prometheus-community ^
                          https://prometheus-community.github.io/helm-charts

                        helm repo update

                        kubectl create namespace monitoring ^
                          --dry-run=client -o yaml | kubectl apply -f -

                        helm upgrade --install monitoring ^
                          prometheus-community/kube-prometheus-stack ^
                          -n monitoring ^
                          -f k8s/monitoring-values.yaml ^
                          --set grafana.adminPassword="%GRAFANA_ADMIN_PASSWORD%" ^
                          --wait --timeout 10m

                        kubectl get pods -n monitoring
                    '''
                }
            }
        }

        stage('19 - Final Verification') {
            steps {
                bat '''
                    kubectl get deployments -n ecommerce
                    kubectl get pods -n ecommerce
                    kubectl get svc -n ecommerce
                    kubectl get ingress -n ecommerce
                    kubectl get pods -n monitoring
                    helm list -n monitoring
                '''
            }
        }
    }

    post {
        success {
            echo "PIPELINE SUCCESS: ${FULL_IMAGE}"
        }

        failure {
            echo "PIPELINE FAILED. Check Jenkins Console Output."
        }

        always {
            echo "JOB: ${JOB_NAME}"
            echo "BUILD: ${BUILD_NUMBER}"
        }
    }
}
