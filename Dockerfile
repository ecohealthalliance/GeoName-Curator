FROM ubuntu:14.04.3

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Set debconf to run non-interactively
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

#Install apt package dependencies
RUN echo "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) main universe" >> /etc/apt/sources.list
RUN echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
RUN apt-get clean all && apt-get update && \
    apt-get -y install wget curl python make g++ git mongodb-org supervisor && \
    apt-get clean all

# Install nodejs
RUN wget https://nodejs.org/download/release/v4.4.7/node-v4.4.7-linux-x64.tar.gz && \
    tar -zxf node-v4.4.7-linux-x64.tar.gz && \
    rm node-v4.4.7-linux-x64.tar.gz
ENV PATH $PATH:/node-v4.4.7-linux-x64/bin

# Install MeteorJS
ENV METEOR_VERSION_TAG release/METEOR@1.4.0.1
RUN git clone https://github.com/meteor/meteor.git --depth 1 --branch $METEOR_VERSION_TAG --single-branch
RUN cd meteor && git checkout -b $METEOR_VERSION_TAG
ENV PATH $PATH:/meteor

# Add the application files
ADD ./build/bundle /eidr-connect
ADD supervisor-mongod.conf /etc/supervisor/conf.d/mongod.conf
ADD supervisor-eidr-connect.conf /etc/supervisor/conf.d/eidr-connect.conf
ADD eidr-connect.sh /eidr-connect.sh
ADD run.sh /run.sh

# Prepare for production
LABEL app="eidr-connect"
EXPOSE 3000
VOLUME /shared

# Start application
CMD /bin/bash /run.sh
