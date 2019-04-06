#!/usr/bin/env groovy

import java.util.Date
import groovy.json.*

def isMaster = env.BRANCH_NAME == 'master'
def isStaging = env.BRANCH_NAME == 'staging'
def start = new Date()
def err = null

String jobInfoShort = "${env.JOB_NAME} ${env.BUILD_DISPLAY_NAME}"
String jobInfo = "${env.JOB_NAME} ${env.BUILD_DISPLAY_NAME} \n${env.BUILD_URL}"
String buildStatus
String timeSpent

currentBuild.result = "SUCCESS"

try {
    node {
        deleteDir()

        stage ('Checkout') {
            checkout scm
        }

        if(isMaster || isStaging){
            def tag = isMaster ? "latest" : "staging"
            stage ('Build Docker Image') {
                sh "docker build -t hydeenoble/turing-react:${tag} ."
            }
            stage ('Push Docker to Docker hub') {
                echo HYDEE_DOCKER_PASS
                sh "\$(${HYDEE_DOCKER_PASS} | docker login --username hydeenoble --password-stdin)"
                sh "docker push hydeenoble/turing-react:${tag}"
            }

            stage ('Deploy to Kubernetes') {
                redeploy(deploymentName, tag)
            }

            stage('Clean up'){
                sh "docker rmi hydeenoble/turing-react:${tag}"
            }
        }
    }
} catch (caughtError) {
    throw caughtError
    currentBuild.result = "FAILURE"
}

def redeploy(deploymentName, tag){
    try{
        withKubeConfig([credentialsId: 'KubeCliCredentialsId',
        serverUrl: K8S_SERVER_URL,
        clusterName: K8S_CLUSTER_NAME]){1
            def patchArg = "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"\$(date +'%s')\"}}}}}"
            def output = JsonOutput.toJson(patchArg)
            sh "kubectl patch deployment ${deploymentName} -n test -p ${output}"
        }
    }
    catch(error){
        throw error
    }
}
