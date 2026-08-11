
# Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Install git for fetch dependencies
RUN apk add --no-cache git

# Copy the source from the current directory to the Working Directory inside the container
COPY . .

# Generate go.sum and download dependencies
RUN go mod tidy && go mod download

# Build the Go app
RUN CGO_ENABLED=0 GOOS=linux go build -o management-api .

# Final stage
FROM alpine:latest

WORKDIR /root/

# Copy the Pre-built binary file from the previous stage
COPY --from=builder /app/management-api .

# Expose port 8081 to the outside world
EXPOSE 8081

# Command to run the executable
CMD ["./management-api"]
