# Passing Notes

## Overview
This project is a simple, passing notes application built using Go. It leverages Redis as a data storage backend and is containerized using Docker for easy deployment and testing. The application provides a RESTful API with two primary endpoints:

* _**POST /api/notes**_ Accepts a text message as input and stores it in Redis for a maximum of 5 minutes.
* _**DELETE /api/notes/:id**_ Searches for a note based on a provided key. If found, the note is returned to the user and then deleted from Redis. This ensures a one-time read message system.

## Run Application

### DevContainer (Recommended)

If you choose this method, you will need:

- Docker
- An IDE that supports DevContainers (e.g., VS Code, GoLand)

Upon launching the DevContainer, a Redis instance will be provisioned. The Redis connection string will be stored as an Environment Variable. This ensures a smooth connection when you run the application. The DevContainer will redirect incoming requests on port 8080 of your local machine to port 80 within the container. This is the port where your application is configured to listen.

### Local Execution

If you choose this method, you'll need:

- Go 1.22 or later version
- Redis instance
- An IDE that you love

You need to create an .env file in the root directory of the project. Inside this file, you need to place the connection string for your Redis instance in the REDIS_HOST key and the corresponding value.

Sample Value:
```
REDIS_HOST=localhost:6379
```

Once you've made these changes, you can compile and run your Go project using your preferred build tool or IDE. This could involve using commands like go run main.go or go build followed by executing the generated binary.
