pipeline {
    agent {
        label 'jenkins-agent'
    }
    
    environment {
        AWS_ACCOUNT_ID = '319998871902'
        AWS_REGION = 'us-east-1'
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/user-management"
        CLUSTER_NAME = 'comic-website-prod'
        KUBE_NAMESPACE = 'user-management'
        DOCKER_IMAGE = "${ECR_REPO}:${env.BUILD_NUMBER}"
        APP_NAME = "user-management-system"
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }
    
    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['dev', 'prod'],
            description: '选择部署环境'
        )
        booleanParam(
            name: 'RUN_TESTS',
            defaultValue: true,
            description: '是否运行测试'
        )
        booleanParam(
            name: 'SKIP_DEPLOY',
            defaultValue: false,
            description: '跳过部署'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh '''
                    echo "代码仓库: ${GIT_URL}"
                    echo "当前分支: ${GIT_BRANCH}"
                    echo "Commit: ${GIT_COMMIT}"
                    git log -1 --oneline
                '''
            }
        }
        
        stage('Build') {
            steps {
                sh '''
                    echo "开始构建应用..."
                    mvn clean package -DskipTests=true
                    echo "构建完成!"
                '''
            }
        }
        
        stage('Unit Tests') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                sh '''
                    echo "运行单元测试..."
                    mvn test
                '''
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'target/site/jacoco',
                        reportFiles: 'index.html',
                        reportName: '代码覆盖率报告'
                    ])
                }
            }
        }
        
        stage('Code Quality') {
            steps {
                sh '''
                    echo "运行代码质量检查..."
                    mvn checkstyle:checkstyle
                    mvn spotbugs:spotbugs
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'target/site/checkstyle.html',
                        reportFiles: 'index.html',
                        reportName: '代码规范检查'
                    ])
                }
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    echo "构建 Docker 镜像: ${DOCKER_IMAGE}"
                    docker.build("${DOCKER_IMAGE}")
                }
            }
        }
        
        stage('Docker Push to ECR') {
            steps {
                script {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'dev-user-aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        sh """
                            echo "登录到 ECR..."
                            aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_REPO}
                            
                            echo "推送镜像: ${DOCKER_IMAGE}"
                            docker push ${DOCKER_IMAGE}
                            
                            echo "标记为 latest 并推送..."
                            docker tag ${DOCKER_IMAGE} ${ECR_REPO}:latest
                            docker push ${ECR_REPO}:latest
                            
                            echo "镜像推送完成!"
                        """
                    }
                }
            }
        }
        
        stage('Deploy to EKS') {
            when {
                expression { params.SKIP_DEPLOY == false }
            }
            steps {
                script {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'dev-user-aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        // 更新 kubeconfig
                        sh """
                            echo "配置 EKS kubeconfig..."
                            aws eks update-kubeconfig \
                                --region ${AWS_REGION} \
                                --name ${CLUSTER_NAME}
                            
                            echo "当前 Kubernetes 上下文:"
                            kubectl config current-context
                        """
                        
                        // 检查命名空间是否存在，不存在则创建
                        sh """
                            if ! kubectl get namespace ${KUBE_NAMESPACE} > /dev/null 2>&1; then
                                echo "创建命名空间: ${KUBE_NAMESPACE}"
                                kubectl apply -f k8s/namespace.yaml
                            else
                                echo "命名空间 ${KUBE_NAMESPACE} 已存在"
                            fi
                        """
                        
                        // 部署数据库（如果不存在）
                        sh """
                            echo "检查数据库部署..."
                            if ! kubectl get statefulset postgresql -n ${KUBE_NAMESPACE} > /dev/null 2>&1; then
                                echo "部署 PostgreSQL..."
                                kubectl apply -f k8s/database/ -n ${KUBE_NAMESPACE}
                                
                                echo "等待数据库就绪..."
                                kubectl wait --for=condition=ready pod -l app=postgresql \
                                    -n ${KUBE_NAMESPACE} --timeout=300s
                            else
                                echo "数据库已部署"
                            fi
                        """
                        
                        // 部署应用配置
                        sh """
                            echo "部署应用配置..."
                            kubectl apply -f k8s/application/ -n ${KUBE_NAMESPACE}
                            kubectl apply -f k8s/networking/ -n ${KUBE_NAMESPACE}
                        """
                        
                        // 更新应用镜像
                        sh """
                            echo "更新应用部署..."
                            kubectl set image deployment/user-management-app \
                                user-management-app=${DOCKER_IMAGE} \
                                -n ${KUBE_NAMESPACE} --record
                        """
                        
                        // 等待部署完成
                        sh """
                            echo "等待部署完成..."
                            kubectl rollout status deployment/user-management-app \
                                -n ${KUBE_NAMESPACE} --timeout=600s
                        """
                        
                        // 检查部署状态
                        sh """
                            echo "=== 部署状态 ==="
                            kubectl get pods -n ${KUBE_NAMESPACE} -l app=user-management-app
                            echo ""
                            kubectl get service -n ${KUBE_NAMESPACE}
                            echo ""
                            kubectl get ingress -n ${KUBE_NAMESPACE}
                        """
                    }
                }
            }
        }
        
        stage('Smoke Test') {
            when {
                expression { params.SKIP_DEPLOY == false }
            }
            steps {
                script {
                    timeout(time: 5, unit: 'MINUTES') {
                        waitUntil {
                            try {
                                // 获取 ALB 地址
                                def albUrl = sh(
                                    script: """
                                        kubectl get ingress user-management-ingress \
                                        -n ${KUBE_NAMESPACE} \
                                        -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo ""
                                    """,
                                    returnStdout: true
                                ).trim()
                                
                                if (albUrl) {
                                    echo "测试应用健康检查: http://${albUrl}/actuator/health"
                                    def responseCode = sh(
                                        script: """
                                            curl -s -o /dev/null -w "%{http_code}" \
                                            http://${albUrl}/actuator/health || echo "000"
                                        """,
                                        returnStdout: true
                                    ).trim()
                                    
                                    if (responseCode == "200") {
                                        echo "✅ 健康检查通过!"
                                        return true
                                    } else {
                                        echo "❌ 健康检查失败，状态码: ${responseCode}"
                                        return false
                                    }
                                } else {
                                    echo "ALB 地址未就绪，等待..."
                                    return false
                                }
                            } catch (Exception e) {
                                echo "健康检查异常: ${e.message}"
                                sleep 30
                                return false
                            }
                        }
                    }
                }
            }
        }
        
        stage('Integration Test') {
            when {
                expression { params.RUN_TESTS == true && params.SKIP_DEPLOY == false }
            }
            steps {
                script {
                    def albUrl = sh(
                        script: """
                            kubectl get ingress user-management-ingress \
                            -n ${KUBE_NAMESPACE} \
                            -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
                        """,
                        returnStdout: true
                    ).trim()
                    
                    sh """
                        echo "运行集成测试..."
                        echo "API 地址: http://${albUrl}"
                        
                        # 测试健康检查
                        curl -f http://${albUrl}/actuator/health
                        
                        # 测试用户 API
                        curl -f http://${albUrl}/api/users
                        
                        echo "集成测试完成!"
                    """
                }
            }
        }
    }
    
    post {
        always {
            script {
                // 清理工作空间
                cleanWs()
                
                // 记录构建信息
                currentBuild.description = "Build #${env.BUILD_NUMBER} - ${params.DEPLOY_ENV}"
            }
        }
        success {
            script {
                def albUrl = sh(
                    script: """
                        kubectl get ingress user-management-ingress \
                        -n ${KUBE_NAMESPACE} \
                        -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "N/A"
                    """,
                    returnStdout: true
                ).trim()
                
                // Slack 通知
                slackSend(
                    channel: '#deployments',
                    message: """✅ 用户管理系统部署成功!
环境: ${params.DEPLOY_ENV}
构建: ${env.BUILD_NUMBER}
分支: ${env.GIT_BRANCH}
Commit: ${env.GIT_COMMIT.take(8)}
应用地址: http://${albUrl}
Swagger文档: http://${albUrl}/swagger-ui.html"""
                )
            }
        }
        failure {
            script {
                // 失败通知
                slackSend(
                    channel: '#deployments',
                    message: """❌ 用户管理系统部署失败!
环境: ${params.DEPLOY_ENV}
构建: ${env.BUILD_NUMBER}
分支: ${env.GIT_BRANCH}
构建日志: ${env.BUILD_URL}"""
                )
            }
        }
        unstable {
            script {
                slackSend(
                    channel: '#deployments',
                    message: """⚠️ 用户管理系统构建不稳定!
构建: ${env.BUILD_NUMBER}
分支: ${env.GIT_BRANCH}
构建日志: ${env.BUILD_URL}"""
                )
            }
        }
    }
}