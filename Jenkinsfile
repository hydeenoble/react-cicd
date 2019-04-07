#!/usr/bin/env groovy

import java.util.Date
import groovy.json.*

def deploymentName = 'react'
def imageName = 'turing-react'
def dockerUser = 'hydeenoble'

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
        env.NODEJS_HOME = "${tool 'Node 6.14.1'}"
        env.PATH = "${env.NODEJS_HOME}/bin:${env.PATH}"

        stage ('checkout') {
            checkout scm
        } 

        if(isMaster || isStaging){
            def tag = isMaster ? "latest" : "staging"
            stage ('Build Docker Image') {
                sh "docker build -t ${dockerUser}/${imageName}:${tag} ."
            }

            stage ('Push Docker to Docker hub') {
                sh "docker login --username ${dockerUser} --password ${HYDEE_DOCKER_PASS}"
                sh "docker push ${dockerUser}/${imageName}:${tag}"
            }

            stage ('Deploy to Kubernetes') {
                redeploy(deploymentName)
            }

            stage('Clean up'){
                sh "docker rmi ${dockerUser}/${imageName}:${tag}"
            }
        }
    }
} catch (caughtError) {
    throw caughtError
    currentBuild.result = "FAILURE"
}

def redeploy(deploymentName){
    try{
        withKubeConfig([credentialsId: 'KubeCliCredentialsId',
        serverUrl: K8S_SERVER_URL,
        clusterName: K8S_CLUSTER_NAME]){
            sh "kubectl apply -f kube.yaml"
            def patchArg = "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"\$(date +'%s')\"}}}}}"
            def output = JsonOutput.toJson(patchArg)
            sh "kubectl patch deployment ${deploymentName} -n test -p ${output}"
        }
    }
    catch(error){
        throw error
    }
}
