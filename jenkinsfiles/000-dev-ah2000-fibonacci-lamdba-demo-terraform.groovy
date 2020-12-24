node {
   stage ('Check Environment Vars Passed')
   {
     //ensure the environment variables needed to run the terraform and aws cli commands have been passed
     env.CHECK_BUCKET_TERRAFROM_STATE_ENV = sh (returnStdout: true, script: 'echo \$BUCKET_TERRAFORM_STATE').trim() 
     if ("$CHECK_BUCKET_TERRAFROM_STATE_ENV" == "") { error "BUCKET_TERRAFORM_STATE must be set in ENV" }
     env.CHECK_AWS_ACCESS_KEY_ID = sh (returnStdout: true, script: 'echo \$AWS_ACCESS_KEY_ID').trim() 
     if ("$CHECK_AWS_ACCESS_KEY_ID" == "") { error "AWS_ACCESS_KEY_ID must be set in ENV" }
     env.CHECK_AWS_SECRET_ACCESS_KEY = sh (returnStdout: true, script: 'echo \$AWS_SECRET_ACCESS_KEY').trim() 
     if ("$CHECK_AWS_SECRET_ACCESS_KEY" == "") { error "AWS_SECRET_ACCESS_KEY must be set in ENV" }
     env.CHECK_AWS_DEFAULT_REGION = sh (returnStdout: true, script: 'echo \$AWS_DEFAULT_REGION').trim() 
     if ("$CHECK_AWS_DEFAULT_REGION" == "") { error "AWS_DEFAULT_REGION must be set in ENV" }

   }
   stage ('Set TF Variables from Environment  ')
   {
        env.TF_VAR_tf_state_bucket = sh (returnStdout: true, script: 'echo \$BUCKET_TERRAFORM_STATE').trim()
        env.TF_VAR_aws_region = sh (returnStdout: true, script: 'echo \$AWS_DEFAULT_REGION').trim()
        //TODO these should be parameters which are passed in to the Job 
        env.TF_VAR_application = "ah2000-lambda-test"
        env.TF_VAR_environment = "dev"
     
         sh "echo \"bucket=$TF_VAR_tf_state_bucket region=$TF_VAR_aws_region key=$TF_VAR_application/$TF_VAR_environment\""
   }
   stage ('Cleanup Workspace') {
       
        env.WORKSPACE = pwd()
        sh "echo 'clearing workspace' && pwd"
        sh "rm ${env.WORKSPACE}/* -fr"
   }
   stage('scm checkout') { 
      // Get some code from a GitHub repository
      git branch:'feature/lambda1', url:'https://github.com/ah2000/fibonacci-lambda-apigateway-demo' 

   }
   stage('pylint') {
       //treat any output as an error and stop the build
         sh "${env.JENKINS_HOME}/bin/pythonPackageScan.sh -p=pylint -s=${env.WORKSPACE}/python_src/*.py -d=\"numpy;pytest\" -o=\"-E -v\" -e"
   }
   stage('pytest') {
         sh "${env.JENKINS_HOME}/bin/pythonPackageScan.sh -p=pytest -s=${env.WORKSPACE}/python_src -d=\"numpy\""
   }
   stage('TruffleHog') {
       
         sh "${env.JENKINS_HOME}/bin/pythonPackageScan.sh -p=truffleHog3 -s=${env.WORKSPACE} -o=\"--no-history\" -e"
   }
   stage('Build zip') {
       env.TF_VAR_releasezipfile = "${env.WORKSPACE}/${commitID()}.zip"
       sh "cd python_src && zip -D ${TF_VAR_releasezipfile} *.py"
   }
   stage('terraform') {
       
         sh "cd terraform_src && terraform init -backend-config \"bucket=${TF_VAR_tf_state_bucket}\" -backend-config \"region=${TF_VAR_aws_region}\" -backend-config \"key=${TF_VAR_application}/${TF_VAR_environment}\""
         sh "cd terraform_src && terraform plan"
         sh "cd terraform_src && terraform apply --auto-approve"
   }
   stage('apigateway End point Call')
   {
       env.RESOURCE_ID = sh (returnStdout: true, script :'echo \$(cd terraform_src && terraform state show module.hello_post.aws_api_gateway_method.request_method | grep resource_id | tr -d \'[:space:]\' | cut -d= -f2 | tr -d \'\"\')').trim()
       env.API_ID = sh (returnStdout: true, script :'echo \$(cd terraform_src && terraform state show module.hello_post.aws_api_gateway_method.request_method | grep rest_api_id | tr -d \'[:space:]\' | cut -d= -f2 | tr -d \'\"\')').trim()
       writeFile(file: 'echo.json', text: '{ \"fibparam\" : 10 }')
       sh ("aws apigateway test-invoke-method --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method POST --path-with-query-string \"\" --body file://echo.json")
   }
}

def commitID() {

    def commitID = sh (returnStdout: true, script:'git rev-parse HEAD').trim()
    commitID

}
