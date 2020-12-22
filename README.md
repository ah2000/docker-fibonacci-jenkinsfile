[![](https://images.microbadger.com/badges/image/hoto/jenkinsfile-examples.svg)](https://microbadger.com/images/hoto/jenkinsfile-examples "Get your own image badge on microbadger.com")
# Jenkinsfiles lamdba test deployment Examples

Extension of hoto/jenkins-example to unit test and deploy a [apigateway endpoint - python lambda](https://github.com/ah2000/fibonacci-lambda-apigateway-demo) 
![](./.images/001.png)

### Why

[Jenkinsfile](https://jenkins.io/doc/book/pipeline/jenkinsfile/) documentation lacks in examples when it comes to more advanced features.  
I needed working examples of various Jenkinsfiles which I could then modify in my local text editor and automatically convert them into Jenkins jobs.
Unfortunately the best way to test a Jenkinsfile is to run it in a Jenkins instance.  
This project takes away the manual process of copying and pasting a Jenkinsfile into a Jenkins job configuration.
By design job has to be run manually.

### Dependencies

[jenkinsfile-loader](https://github.com/hoto/jenkinsfile-loader) container uses Jenkins REST API to create Jenkins jobs directly from Jenkinsfiles located in `jenkinsfiles` directory.
It also monitors any change in that folder and will update, create or remove jobs accordingly.  
All files must be named `<job_name>.groovy` where `<job_name>` will be used for the Jenkins job name.
There is no auto-refresh, so after adding or removing files Jenkins page needs to be refreshed manually to reflect changes.

### Run

This will pull and start latest docker images

ensure you have copied or set a symbolic link from your .aws to uses default profile on AWS commands

    docker-compose pull
    docker-compose up
   
If you have problem with mounting `/var/run/docker.sock` then remove it from `docker-compose.yml` but you won't be able to run jobs which use docker as an agent.

In the terminal you should see:

    $ docker-compose-up
    ...
    jenkinsfile-loader_1  | 21:27:33 Waiting for Jenkins at http://jenkins:8080/api/json...
    jenkins_1             | INFO: Jenkins is fully up and running
    ...
    jenkinsfile-loader_1  | 21:27:46 Connection to Jenkins established...
    jenkinsfile-loader_1  | 21:27:46 Creating job 001-stages-declarative-style...
    ...


Wait for Jenkins to boot up. Authentication is disabled. Open a browser and go to:

    localhost:8080
    
If you don't see any jobs refresh the browser and check the `docker-compose` logs.

To stop press `CTRL+C` in terminal.  

To remove all containers with all of its data run:

    docker-compose down

---

        
### Components:
  - [terraform] - for deploying 
  - [sonarqube] - for doing static security testing
  - [pylint] - for python linting of code
  - [jenkins](https://hub.docker.com/_/jenkins/ ) - Customized with pre-installed plugins and disabled authentication.
  - [jenkinsfile-loader](https://github.com/hoto/jenkinsfile-loader) - Uses Jenkins API and creates jobs directly from Jenkinsfiles.
  
