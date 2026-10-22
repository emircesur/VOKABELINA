FROM dart:stable AS build
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart pub get --offline && dart compile exe bin/server.dart -o bin/server

FROM debian:stable-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/bin/server /app/server
COPY web /app/web
ENV DATA_DIR=/data ADMIN_WEB_DIR=/app/web
EXPOSE 8080
CMD ["/app/server"]
