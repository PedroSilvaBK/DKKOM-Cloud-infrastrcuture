pipeline {
    agent any
    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('GCP_KEY') // Use the ID from the stored credentials
    }
    stages {
        stage('Authenticate with Google Cloud') {
            steps {
                script {
                    sh 'echo $GOOGLE_APPLICATION_CREDENTIALS > gcloud-key.json'
                    sh '''
                        gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                    '''
                }
            }
        }
        stage ("Terraform Init") {
            steps {
                echo 'Initializing Terraform'
                sh 'terraform init'
            }
        }
        stage ("Terraform Plan") {
            steps {
                echo 'Planning Terraform'
                sh 'terraform plan'
            }
        }
        stage ("Terraform Apply") {
            steps {
                echo 'Applying Terraform'
                sh 'terraform apply -auto-approve'
            }
        }
        stage("get cluster credentials"){
            steps {
                sh 'gcloud container clusters get-credentials dcom-cluster --zone europe-west1-b --project d-com-437216'
            }
        }
        stage("install ingress") {
            steps{
                sh 'helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace'
            }
        }
        stage("create service account for cluster to access secret manager")
        {
            steps {
                sh "kubectl create serviceaccount app-access"
                sh "gcloud secrets add-iam-policy-binding service-principal-app --role=roles/secretmanager.secretAccessor --member=principal://iam.googleapis.com/projects/737764647544/locations/global/workloadIdentityPools/d-com-437216.svc.id.goog/subject/ns/default/sa/app-access"
            }
        }
        stage("deploy kafka and schylladb") {
            steps {
                sh 'kubectl apply -f kafka.yaml'
                sh 'kubectl apply -f message-service.schylladb.yaml'
            }
        }
    }
}
