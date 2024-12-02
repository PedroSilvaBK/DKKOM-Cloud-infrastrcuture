pipeline {
    agent any
    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Choose whether to apply or destroy infrastructure')
    }
    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('GCP_KEY') // Use the ID from the stored credentials
    }
    stages {
        stage('Authenticate with Google Cloud') {
            steps {
                script {
                    sh 'echo $GOOGLE_APPLICATION_CREDENTIALS > gcloud-key.json'
                    sh '''
                        gcloud auth activate-service-account --key-file=gcloud-key.json
                    '''
                }
            }
        }
        stage('Terraform Init') {
            steps {
                echo 'Initializing Terraform'
                sh 'terraform init'
            }
        }
        stage('Terraform Plan') {
            steps {
                echo 'Planning Terraform'
                sh 'terraform plan'
            }
        }
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                echo 'Applying Terraform'
                sh 'terraform apply -auto-approve'
            }
        }
        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                echo 'Destroying Terraform infrastructure'
                sh 'terraform destroy -auto-approve'
            }
        }
        stage('Get Cluster Credentials') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                sh 'gcloud container clusters get-credentials dcom-cluster --zone europe-west1-b --project d-com-437216'
            }
        }
        stage('Install Ingress') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                sh 'helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace'
            }
        }
        stage('Create Service Account for Cluster to Access Secret Manager') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                sh '''
                    kubectl create serviceaccount app-access
                    gcloud secrets add-iam-policy-binding service-principal-app \
                        --role=roles/secretmanager.secretAccessor \
                        --member=principal://iam.googleapis.com/projects/737764647544/locations/global/workloadIdentityPools/d-com-437216.svc.id.goog/subject/ns/default/sa/app-access
                '''
            }
        }
        stage('Deploy Kafka and ScyllaDB') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                sh 'kubectl apply -f kafka.yaml'
                sh 'kubectl apply -f message-service.schylladb.yaml'
            }
        }
    }
    post {
        always {
            echo 'Cleaning up temporary files'
            sh 'rm -f gcloud-key.json'
        }
    }
}
