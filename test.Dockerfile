FROM dannyanko/meteor-headless-testing:latest

# Create the working directory
RUN mkdir /home/meteor/eidr-connect
WORKDIR /home/meteor/eidr-connect

# Add package.json to cache npm install
COPY package.json package.json

USER meteor

# Install npm dependencies
RUN meteor npm install

# native bcrypt for faster encryption
RUN npm install --save bcrypt

USER root
# Copy project files
COPY . .

# Admin chores
RUN cp /usr/bin/meteor /usr/local/bin/meteor
RUN chown -R meteor:meteor /home/meteor/

USER meteor

# Setup github
RUN git config user.email "ecohealth-automation@users.noreply.github.com" && \
  git config user.name "ecohealth-automation"
RUN git remote set-url origin https://github.com/ecohealthalliance/eidr-connect.git

CMD /bin/bash
