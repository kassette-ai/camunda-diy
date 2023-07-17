FROM openjdk:17.0-jdk
ARG JAR_FILE=target/self-service-restaurant-0.0.1-SNAPSHOT.jar

RUN groupadd -r camunda -g 433 && \
    useradd -u 431 -r -g camunda -s /sbin/nologin -c "Docker image user" camunda

RUN mkdir -p /opt/app
WORKDIR /opt/app
COPY $JAR_FILE /opt/app/app.jar
COPY scripts/run.sh /opt/app/
RUN chmod 0755 /opt/app/run.sh
RUN chown -R camunda:camunda /opt/app
USER camunda
ENTRYPOINT ["/opt/app/run.sh"]

