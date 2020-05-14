FROM jboss/wildfly:18.0.1.Final

ENV WILDFLY_HOME /opt/jboss/wildfly
ENV DEPLOY_DIR ${WILDFLY_HOME}/standalone/deployments/

# setup timezone
ENV TZ=Europe/Rome
USER root
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
USER jboss

ENV DATASOURCE_NAME RedEvoDataSource
ENV DATASOURCE_JNDI java:/RedEvoDataSource

ENV DB_HOST rede-db-stolon-rede-proxy
ENV DB_PORT 5432
ENV DB_USER postgres
ENV DB_PASS yazw4Wb4FE
ENV DB_NAME postgres

# create temporary deployment dir, because wars can deploy after the datasource is created
RUN mkdir /tmp/deploments
ENV DEPLOY_DIR /tmp/deploments

RUN mkdir /tmp/jboss-cli
ENV CLI_DIR /tmp/jboss-cli

COPY startWithPostgres.sh $WILDFLY_HOME/bin

USER root
RUN chown jboss:jboss $WILDFLY_HOME/bin/startWithPostgres.sh
RUN chmod 755 $WILDFLY_HOME/bin/startWithPostgres.sh
USER jboss

COPY postgresql-42.2.12.jar /tmp

RUN /bin/sh -c '$WILDFLY_HOME/bin/standalone.sh &' && \
  echo ----- Waiting for server && \
  sleep 10 && \
  echo ----- Adding Module org.postgres && \
  $WILDFLY_HOME/bin/jboss-cli.sh --connect --command="module add --name=org.postgres --resources=/tmp/postgresql-42.2.12.jar --dependencies=javax.api,javax.transaction.api" && \
  echo ----- Subsystem && \
  $WILDFLY_HOME/bin/jboss-cli.sh --connect --command="/subsystem=datasources/jdbc-driver=postgres:add(driver-name=\"postgres\",driver-module-name=\"org.postgres\",driver-class-name=org.postgresql.Driver)" && \
  #$WILDFLY_HOME/bin/jboss-cli.sh --connect \
  #--command="data-source add \
  #--jndi-name=$DATASOURCE_JNDI \
  #--name=$DATASOURCE_NAME \
  #--connection-url=jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_NAME \
  #--driver-name=postgres \
  #--user-name=$DB_USER \
  #--password=$DB_PASS \
  #--check-valid-connection-sql='SELECT 1' \
  #--background-validation=true \
  #--background-validation-millis=6000 \
  #--flush-strategy=IdleConnections \
  #--min-pool-size=10 --max-pool-size=100  --pool-prefill=false" && \
  echo ----- Deleting && \
  $WILDFLY_HOME/bin/jboss-cli.sh --connect --command=:shutdown && \
  rm -rf $WILDFLY_HOME/standalone/configuration/standalone_xml_history/ $WILDFLY_HOME/standalone/log/* && \
  rm -rf /tmp/postgresql-*.jar

# Add the datasource

#$WILDFLY_HOME/bin/jboss-cli.sh --connect --command="deploy /tmp/postgresql-42.2.12.jar" && \
#$WILDFLY_HOME/bin/jboss-cli.sh --connect --command="xa-data-source add --name=$DATASOURCE_NAME --jndi-name=java:/jdbc/datasources/campsturDS --user-name=${DB_USER} --password=${DB_PASS} --driver-name=postgresql-9.4-1201-jdbc41.jar --xa-datasource-class=org.postgresql.xa.PGXADataSource --xa-datasource-properties=ServerName=${DB_HOST},PortNumber=5432,DatabaseName=${DB_NAME} --valid-connection-checker-class-name=org.jboss.jca.adapters.jdbc.extensions.postgres.PostgreSQLValidConnectionChecker --exception-sorter-class-name=org.jboss.jca.adapters.jdbc.extensions.postgres.PostgreSQLExceptionSorter" && \
#$WILDFLY_HOME/bin/jboss-cli.sh --connect --command=:shutdown && \
#rm -rf $WILDFLY_HOME/standalone/configuration/standalone_xml_history/ $WILDFLY_HOME/standalone/log/* && \
#rm -rf /tmp/postgresql-*.jar

CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-c", "standalone.xml"]
