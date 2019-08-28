FROM jenkins/jnlp-slave

MAINTAINER Bo Wang "bo.wang@albumprinter.com"

RUN df -h
USER root
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

USER jenkins

ENTRYPOINT ["/usr/local/bin/jenkins-slave"]
