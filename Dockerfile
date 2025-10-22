FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

COPY target/user-management-system-1.0.0.jar app.jar

RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]