FROM docker.io/jenkins/jenkins:2.141
#seems docker.io/hoto/jenkinsfile-loader:1.1.0 only works with this version jenkins:2.141 

USER root

# taken from https://hub.docker.com/r/zasados/jenkins-python3.6/dockerfile
# Install tools required for compiling Python 3.6.1 and wget for installing pip3
RUN apt-get update -y && \
	apt-get upgrade -y

RUN apt-get install -y \
	build-essential \
	libssl-dev \
	zlib1g-dev \
	libncurses5-dev \
	libncursesw5-dev \
	libreadline-dev \
	libsqlite3-dev \
	libgdbm-dev \
	libdb5.3-dev \
	libbz2-dev \
	libexpat1-dev \
	liblzma-dev \
	tk-dev \
	wget

# Copy sh script responsible for installing Python
COPY source/installpython3.sh /root/tmp/installpython3.sh

# Run the script responsible for installing Python 3.6.1 and link it to /usr/bin/python3
RUN chmod +x /root/tmp/installpython3.sh; sync && \
	./root/tmp/installpython3.sh && \
	rm -rf /root/tmp/installpython3.sh && \
	ln -s /Python-3.6.1/python /usr/bin/python3

# Install pip3 for Python 3.6.1
RUN rm -rf /usr/local/lib/python3.6/site-packages/pip* && \
	wget https://bootstrap.pypa.io/get-pip.py && \
	python3 get-pip.py && \
	rm get-pip.py
#end code https://hub.docker.com/r/zasados/jenkins-python3.6/dockerfile

#remaining code for forked source ie from https://github.com/hoto/jenkinsfile-examples

RUN apt-get update -y && \
    apt-get install -y awscli jq gettext-base tree vim zip

RUN wget https://download.docker.com/linux/static/stable/x86_64/docker-18.06.1-ce.tgz && \
	tar xzvf docker-18.06.1-ce.tgz && \
	cp docker/* /usr/bin/
RUN curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

RUN wget https://releases.hashicorp.com/terraform/0.12.21/terraform_0.12.21_linux_amd64.zip
##install terraform
RUN unzip terraform_0.12.21_linux_amd64.zip && rm terraform_0.12.21_linux_amd64.zip
RUN mv terraform /usr/bin/terraform

#so the project dependencies don't effect the machine
RUN pip3 install virtualenv 

COPY source/jenkins/usr/share/jenkins/plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt

##set bash as default shell
RUN echo 'dash dash/sh boolean false' | debconf-set-selections && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
COPY source/jenkins/ /

COPY source/jenkins/var/jenkins_home/ $JENKINS_HOME/
RUN chmod +rx $JENKINS_HOME/bin/pythonPackageScan.sh
