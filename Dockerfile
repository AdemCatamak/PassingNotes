
# Use the official golang image as a parent image
FROM golang:1.22-alpine
ENV PORT=80
ENV REDIS_HOST='127.0.0.1'
ENV REDIS_PASS=''

# Set the working directory in the container
WORKDIR /app

# Copy the go.mod and go.sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the rest of the application source code
COPY . .

# Build the application
RUN go build -o main .

EXPOSE 80

# Command to run the container
CMD ["./main"]