FROM debian:10

RUN apt-get update -y && apt-get install -y curl xmlstarlet bsdtar unzip && apt-get clean all
RUN mkdir -p /opt/jboss && chmod 755 /opt/jboss
WORKDIR /opt/jboss

RUN apt-get install -y openjdk-11-jdk && apt-get clean all
ENV JAVA_HOME=/usr/bin/java

ENV WILDFLY_VERSION 18.0.1.Final
ENV WILDFLY_SHA1 ef0372589a0f08c36b15360fe7291721a7e3f7d9
ENV JBOSS_HOME /opt/jboss/wildfly

RUN cd $HOME \
  && curl -O https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
  && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
  && tar xf wildfly-$WILDFLY_VERSION.tar.gz \
  && mv $HOME/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
  && rm wildfly-$WILDFLY_VERSION.tar.gz

ENV DATASOURCE_NAME RedEvoDataSource
ENV DATASOURCE_JNDI java:/RedEvoDataSource

ENV JBOSS_HOME=/opt/jboss/wildfly
ENV DB_HOST rede-db-stolon-rede-proxy
ENV DB_PORT 5432
ENV DB_USER postgres
ENV DB_PASS yazw4Wb4FE
ENV DB_NAME postgres

COPY postgresql-42.2.12.jar /tmp

ENV JAVA_HOME=/usr

RUN /bin/sh -c '$JBOSS_HOME/bin/standalone.sh &' && \
  echo ----- Waiting for server && \
  sleep 10 && \
  echo && \
  $JBOSS_HOME/bin/jboss-cli.sh --connect --command="/subsystem=deployment-scanner/scanner=default:write-attribute(name=auto-deploy-exploded,value=true)" && \
  echo ----- Adding Module org.postgres && \
  $JBOSS_HOME/bin/jboss-cli.sh --connect --command="module add --name=org.postgres --resources=/tmp/postgresql-42.2.12.jar --dependencies=javax.api,javax.transaction.api" && \
  echo ----- Subsystem && \
  $JBOSS_HOME/bin/jboss-cli.sh --connect --command="/subsystem=datasources/jdbc-driver=postgres:add(driver-name=\"postgres\",driver-module-name=\"org.postgres\",driver-class-name=org.postgresql.Driver)" && \
  $JBOSS_HOME/bin/jboss-cli.sh --connect \
  --command="data-source add \
  --jndi-name=$DATASOURCE_JNDI \
  --name=$DATASOURCE_NAME \
  --connection-url=jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_NAME \
  --driver-name=postgres \
  --user-name=$DB_USER \
  --password=$DB_PASS \
  --check-valid-connection-sql='SELECT 1' \
  --background-validation=true \
  --background-validation-millis=6000 \
  --flush-strategy=IdleConnections \
  --min-pool-size=10 --max-pool-size=100  --pool-prefill=false" && \
  echo ----- Shutdown && \
  $JBOSS_HOME/bin/jboss-cli.sh --connect --command=:shutdown

RUN chmod -R 555 /opt/jboss/wildfly/standalone

RUN $JBOSS_HOME/bin/add-user.sh admin -p admin -s

CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
