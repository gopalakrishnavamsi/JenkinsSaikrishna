pipeline {
    //agent { label 'jenkins-slave-mono-1' }
    agent any
    stages {
        stage('Install SFDX') {
            steps { 

                echo 'Installing SFDX'
                echo "${WORKSPACE}"
                sh "${WORKSPACE}/etc/scripts/installsfdx.sh"

            }
        }
    } 

}