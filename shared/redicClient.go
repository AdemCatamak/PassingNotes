package shared

import (
	"github.com/redis/go-redis/v9"
	"os"
)

func NewRedisClient() *redis.Client {
	redisUrl := os.Getenv("REDIS_HOST")

	opts, err := redis.ParseURL(redisUrl)
	if err != nil {
		panic(err)
	}

	client := redis.NewClient(opts)
	return client
}
