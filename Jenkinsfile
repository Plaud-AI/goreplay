pipeline {
    agent any
    
    parameters {
        string(name: 'IMAGE_TAG', defaultValue: 'goreplay:latest', description: 'Docker镜像标签')
        string(name: 'IMAGE_NAME', defaultValue: 'goreplay', description: 'Docker镜像名称')
        string(name: 'CONTAINER_NAME', defaultValue: 'goreplay', description: '容器名称')
        
        // GoReplay 参数
        string(name: 'INPUT_RAW', defaultValue: ':8080', description: '输入端口，例如 :8080')
        string(name: 'OUTPUT_HTTP', defaultValue: 'http://localhost:7100', description: '输出HTTP地址')
        
        // 可选参数
        string(name: 'EXTRA_ARGS', defaultValue: '--verbose', description: '额外的GoReplay参数，用空格分隔')
        
        // 部署选项
        booleanParam(name: 'RESTART_CONTAINER', defaultValue: true, description: '是否重启已存在的容器')
    }
    
    environment {
        DOCKER_IMAGE = "${params.IMAGE_NAME}:${params.IMAGE_TAG}"
    }
    
    stages {
        stage('Build') {
            steps {
                script {
                    echo "构建 Docker 镜像: ${env.DOCKER_IMAGE}"
                    sh """
                        docker build -t ${env.DOCKER_IMAGE} .
                    """
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    echo "部署 GoReplay 容器: ${params.CONTAINER_NAME}"
                    
                    // 停止并删除旧容器（如果存在）
                    if (params.RESTART_CONTAINER) {
                        sh """
                            docker stop ${params.CONTAINER_NAME} || true
                            docker rm ${params.CONTAINER_NAME} || true
                        """
                    }
                    
                    // 构建 docker run 命令（模式2：命令行工具方式）
                    def gorArgs = "--input-raw ${params.INPUT_RAW} --output-http ${params.OUTPUT_HTTP}"
                    
                    // 添加额外参数（如果提供）
                    if (params.EXTRA_ARGS?.trim()) {
                        gorArgs += " ${params.EXTRA_ARGS}"
                    }
                    
                    // 执行部署（使用 host 网络模式，需要特殊权限）
                    sh """
                        docker run -d \\
                            --name ${params.CONTAINER_NAME} \\
                            --cap-add=NET_RAW \\
                            --cap-add=NET_ADMIN \\
                            --network host \\
                            --restart unless-stopped \\
                            ${env.DOCKER_IMAGE} \\
                            ${gorArgs}
                    """
                    
                    // 验证容器状态
                    sh """
                        echo "等待容器启动..."
                        sleep 2
                        docker ps | grep ${params.CONTAINER_NAME} || (echo "容器启动失败" && docker logs ${params.CONTAINER_NAME} && exit 1)
                        echo "容器部署成功"
                        docker logs --tail 20 ${params.CONTAINER_NAME}
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "部署成功！"
            echo "容器名称: ${params.CONTAINER_NAME}"
            echo "镜像: ${env.DOCKER_IMAGE}"
            echo "查看日志: docker logs -f ${params.CONTAINER_NAME}"
        }
        failure {
            echo "部署失败！"
            script {
                sh """
                    echo "容器状态:"
                    docker ps -a | grep ${params.CONTAINER_NAME} || true
                    echo "容器日志:"
                    docker logs ${params.CONTAINER_NAME} || true
                """
            }
        }
        always {
            echo "清理临时文件..."
        }
    }
}

