# Stage 1: Build Flutter Web
FROM ubuntu:22.04 AS builder

RUN apt update && apt install -y curl git unzip xz-utils zip libglu1-mesa
WORKDIR /app

# Cài Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable
ENV PATH="$PATH:/app/flutter/bin"

COPY . .
RUN flutter config --enable-web
RUN flutter build web

# Stage 2: Serve bằng Nginx
FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
