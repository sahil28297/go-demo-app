# syntax=docker/dockerfile:1

FROM golang:1.13

# Set destination for COPY
WORKDIR /app

# Download Go modules
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code
COPY main.go ./

# Declare env vars to be used in app
ENV DEMO_APP_ADDR 8080
ENV DEMO_REDIS_ADDR redis:6379

# Build
RUN CGO_ENABLED=0 go build -o /zerodha-demo-app -ldflags="-X 'main.version=${VERSION}'"

# Expose app address
EXPOSE ${DEMO_APP_ADDR}

# Run
CMD ["/zerodha-demo-app"]