FROM openjdk:8-jdk

MAINTAINER Bo Wang "bo.wang@albumprinter.com"

RUN df -h

RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    openssh-client ssh-askpass\
    ca-certificates \
    curl \
    git \
    tar zip unzip \
  && rm -rf /var/lib/apt/lists/*

#========================================
# Install Python 3.7.3
#========================================
USER root
ENV PYTHON_VERSION="3.7.3"

#Install core packages
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get install -y build-essential checkinstall libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev

# Install Python 3.7.3
RUN  wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
    && tar xvf Python-${PYTHON_VERSION}.tgz \
    && rm -rf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-optimizations \
    && make altinstall \
    && rm -rf Python-${PYTHON_VERSION} \
    && cd

RUN apt-get update
RUN apt-get install -y python3-pil

# Install pip
RUN apt-get update
RUN apt-get install -y python3-pip python3-lxml
RUN pip3 install -U pytest boto3 six nose nose-allure-plugin

#========================================
# OCTO
#========================================
USER root

RUN apt-get update \
  && apt-get install -y libunwind8 apt-transport-https dirmngr \
  && rm -rf /var/lib/apt/lists/*

ENV OCTOPUS_VERSION 4.38.1

RUN mkdir /usr/octopus/ \
    && curl -fsSL https://download.octopusdeploy.com/octopus-tools/$OCTOPUS_VERSION/OctopusTools.$OCTOPUS_VERSION.debian.8-x64.tar.gz | tar xzf - -C /usr/octopus/

ENV PATH="/usr/octopus:${PATH}"

#========================================
# PROGET CONFIG
#========================================
ARG PROGET_USERNAME
ARG PROGET_PASSWORD

ENV PROGET_USERNAME=$PROGET_USERNAME
ENV PROGET_PASSWORD=$PROGET_PASSWORD

COPY NuGet.Config /

#========================================
# Add normal user with passwordless sudo
#========================================
USER root
RUN useradd jenkins --shell /bin/bash --create-home \
  && usermod -a -G sudo jenkins \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'jenkins:secret' | chpasswd


USER root
#====================================
# Add local maven repository setting file
#
#====================================
ADD settings.xml /home/jenkins/.m2/settings.xml
RUN chmod 777 /home/jenkins/.m2/settings.xml

#COPY credentials /home/jenkins/.aws/credentials
#RUN chmod 777 /home/jenkins/.aws/credentials
#COPY config /home/jenkins/.aws/config
#RUN chmod 777 /home/jenkins/.aws/config


#====================================
# Setup Jenkins Slave
#
#====================================

ARG VERSION=3.18

RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar

COPY jenkins-slave /usr/local/bin/jenkins-slave

RUN chmod a+rwx /home/jenkins
RUN chmod a+rwx /home/jenkins/.m2
WORKDIR /home/jenkins
USER jenkins

ENTRYPOINT ["/usr/local/bin/jenkins-slave"]
