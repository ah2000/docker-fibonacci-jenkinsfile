node {
    environment {
        CURRENT_WORKSPACE = pwd()
    }
   stage ('Cleanup Workspace') {
       
        env.WORKSPACE = pwd()
        sh "echo 'clearing workspace' && pwd"
        sh "rm ${env.WORKSPACE}/* -fr"
   }
   stage('scm checkout') { 
      // Get some code from a GitHub repository
      git branch:'feature/brokenTruffleHog', url:'https://github.com/ah2000/fibonacci-lambda-apigateway-demo' 

   }
   stage('pylint') {
       //treat any output as an error and stop the build
         sh "${env.JENKINS_HOME}/bin/pythonPackageScan.sh -p=pylint -s=${env.WORKSPACE}/python_src/*.py -d=\"numpy;pytest\" -o=\"-E -v\" -e"
   }
   stage('pytest') {
         sh "${env.JENKINS_HOME}/bin/pythonPackageScan.sh -p=pytest -s=${env.WORKSPACE}/python_src -d=\"numpy\""
   }
   stage('TruffleHog') {
       
         sh "${env.JENKINS_HOME}/bin/pythonPackageScan.sh -p=truffleHog3 -s=${env.WORKSPACE} -o=\"--no-entropy\" -e"
   }
}
