pipeline {
    agent any
    parameters {
        choice(name: 'ACTION', choices: ['create-prod', 'create-staging', 'destroy-prod', 'destroy-staging'], description: 'Choose whether to create or destroy infrastructure')
    }
    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('GCP_KEY')
        GOOGLE_CLIENT_SECRET = credentials('GOOGLE_CLIENT_SECRET')
    }
    stages {
        stage('Authenticate with Google Cloud') {
            steps {
                script {
                    sh 'echo $GOOGLE_APPLICATION_CREDENTIALS > gcloud-key.json'
                    sh 'ls -ls'
                    sh '''
                        gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                    '''
                }
            }
        }
        stage('Terraform Init Production') {
            when {
                expression { params.ACTION == 'create-prod' }
            }
            steps {
                dir("production") {
                    echo 'Initializing Terraform for production'
                    sh 'terraform init -reconfigure'
                }
            }
        }
        stage('Terraform Plan Production') {
            when {
                expression { params.ACTION == 'create-prod' }
            }
            steps {
                dir("production") {
                    echo 'Planning Terraform for production'
                    sh 'terraform plan'
                }
            }
        }
        stage('Terraform Apply Production') {
            when {
                expression { params.ACTION == 'create-prod' }
            }
            steps {
                dir('production') {
                    echo 'Applying Terraform'
                    sh 'terraform apply -auto-approve'

                    // Capture Terraform outputs
                    script {
                        def sqlInstanceIP = sh(script: 'terraform output -raw sql_instance_ip', returnStdout: true).trim()
                        def redisIP = sh(script: 'terraform output -raw redis_ip', returnStdout: true).trim()

                        // Set environment variables for Kubernetes secrets creation
                        env.SQL_INSTANCE_IP = sqlInstanceIP
                        env.REDIS_IP = redisIP
                    }
                }
            }
        }
        stage('Terraform Destroy Production') {
            when {
                expression { params.ACTION == 'destroy-prod' }
            }
            steps {
                dir('production') {
                    echo 'Destroying Terraform for production'
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
        stage('Terraform Init Staging') {
            when {
                expression { params.ACTION == 'create-staging' }
            }
            steps {
                dir("staging") {
                    echo 'Initializing Terraform for Staging'
                    sh 'terraform init -reconfigure'
                }
            }
        }
        stage('Terraform Plan Staging') {
            when {
                expression { params.ACTION == 'create-staging' }
            }
            steps {
                dir("staging") {
                    echo 'Planning Terraform for Staging'
                    sh 'terraform plan'
                }
            }
        }
        stage('Terraform Apply Staging') {
            when {
                expression { params.ACTION == 'create-staging' }
            }
            steps {
                dir('staging') {
                    echo 'Applying Terraform'
                    sh 'terraform apply -auto-approve'

                    // Capture Terraform outputs
                    script {
                        def sqlInstanceIP = sh(script: 'terraform output -raw sql_instance_ip', returnStdout: true).trim()
                        def redisIP = sh(script: 'terraform output -raw redis_ip', returnStdout: true).trim()

                        // Set environment variables for Kubernetes secrets creation
                        env.SQL_INSTANCE_IP = sqlInstanceIP
                        env.REDIS_IP = redisIP
                    }
                }
            }
        }
        stage('Terraform Destroy Staging') {
            when {
                expression { params.ACTION == 'destroy-staging' }
            }
            steps {
                dir('staging') {
                    echo 'Destroying Terraform for Staging'
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
        stage('Get Cluster Credentials') {
            when {
                expression { params.ACTION == 'create-prod' || params.ACTION == 'create-staging' }
            }
            steps {
                sh 'gcloud container clusters get-credentials dcom-cluster --zone europe-west1-b --project dkkom-446515'
            }
        }
        stage('Install Ingress') {
            when {
                expression { params.ACTION == 'create-prod' || params.ACTION == 'create-staging' }
            }
            steps {
                sh '''
                    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
                    helm repo update
                    helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
                '''
            }
        }
        stage('Create Service Account for Cluster to Access Secret Manager') {
            when {
                expression { params.ACTION == 'create-prod' || params.ACTION == 'create-staging' }
            }
            steps {
                sh '''
                    kubectl create serviceaccount app-access
                    gcloud secrets add-iam-policy-binding projects/953454344870/secrets/service-principal-app \
                        --role=roles/secretmanager.secretAccessor \
                        --member=principal://iam.googleapis.com/projects/953454344870/locations/global/workloadIdentityPools/dkkom-446515.svc.id.goog/subject/ns/default/sa/app-access
                '''
                sh '''
                    gcloud secrets add-iam-policy-binding projects/953454344870/secrets/cloud-trace-agent-sa-key \
                        --role=roles/secretmanager.secretAccessor \
                        --member=principal://iam.googleapis.com/projects/953454344870/locations/global/workloadIdentityPools/dkkom-446515.svc.id.goog/subject/ns/default/sa/app-access
                '''
                sh '''
                    gcloud secrets add-iam-policy-binding projects/953454344870/secrets/cloud-profiler-agent-sa-key \
                        --role=roles/secretmanager.secretAccessor \
                        --member=principal://iam.googleapis.com/projects/953454344870/locations/global/workloadIdentityPools/dkkom-446515.svc.id.goog/subject/ns/default/sa/app-access
                '''
            }
        }
        stage('Deploy Kafka and ScyllaDB') {
            when {
                expression { params.ACTION == 'create-prod' || params.ACTION == 'create-staging' }
            }
            steps {
                sh 'kubectl apply -f kafka.yaml'
                sh 'kubectl apply -f message-service-schylladb.yaml'
            }
        }
        stage('Create Kubernetes Secrets') {
            when {
                expression { params.ACTION == 'create-prod' || params.ACTION == 'create-staging' }
            }
            steps {
                sh '''
                    kubectl create secret generic database-ip \
                        --from-literal=DATABASE_IP=${SQL_INSTANCE_IP}
                '''
                sh '''
                    kubectl create secret generic redis-ip \
                        --from-literal=REDIS_IP=${REDIS_IP}
                '''
                sh  'kubectl apply -f app-secrets.yaml'
                sh 'kubectl create secret generic google-client-secret --from-literal=GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}'
            }
        }
        stage('Setup open telemetry collector') {
            when {
                expression { params.ACTION == 'create-prod' || params.ACTION == 'create-staging' }
            }
            steps {
                dir('trace-collector-config-files') {
                    sh 'kubectl apply -f otel-collector-config.yaml'
                    sh 'kubectl apply -f otel-collector-deployment.yaml'
                }
            }
        }
        stage('Delay Stage') {  // This stage will have a delay
            when {
                expression { params.ACTION == 'create-prod' || params.ACTION == 'create-staging' }
            }
            steps {
                echo 'Delaying for 60 seconds'
                script {
                    sleep 60
                }
            }
        }
        stage('setup scylla') {
            when {
                expression { params.ACTION == 'create-prod' || params.ACTION == 'create-staging' }
            }
            steps {
                sh 'kubectl exec -it scylla-0 -- cqlsh -e "CREATE KEYSPACE IF NOT EXISTS message_space WITH REPLICATION = {\'class\': \'SimpleStrategy\', \'replication_factor\': 3};"'
            }
        }
        stage('apply ingress production') {
            when {
                expression { params.ACTION == 'create-prod' }
            }
            steps {
                sh '''
                    helm upgrade --install ingress ./helm \
                        -f ./helm/values.yaml
                    '''
            }
        }
        stage('apply ingress staging') {
            when {
                expression { params.ACTION == 'create-staging' }
            }
            steps {
                sh '''
                    helm upgrade --install ingress-staging ./helm \
                        -f ./helm/values-staging.yaml
                    '''
            }
        }
    }
}
