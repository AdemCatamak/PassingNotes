package shared

import (
	"github.com/redis/go-redis/v9"
	"log"
	"os"
)

func NewRedisClient() *redis.Client {
	redisUrl := os.Getenv("REDIS_HOST")
	redisPass := os.Getenv("REDIS_PASS")

	log.Printf("REDIS HOST => %s", redisUrl)

	redisOpt := &redis.Options{
		Addr:     redisUrl,
		Password: redisPass,
		DB:       0,
	}

	client := redis.NewClient(redisOpt)
	return client
}
