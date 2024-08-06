package stores

import (
	"PassingNotes/notes/models"
	"PassingNotes/shared"
	"context"
	"encoding/json"
	"errors"
	"github.com/redis/go-redis/v9"
	"time"
)

type IStore interface {
	Add(ctx context.Context, note models.Note) error
	Get(ctx context.Context, id string) (*models.Note, error)
	Delete(ctx context.Context, id string) error
}

func NewStore() IStore {
	redisClient := shared.NewRedisClient()
	store := Store{
		redisClient: redisClient,
	}
	return store
}

type Store struct {
	redisClient *redis.Client
}

func (store Store) Add(ctx context.Context, note models.Note) error {
	data, err := json.Marshal(note)
	if err != nil {
		return err
	}
	err = store.redisClient.Set(ctx, note.Id, data, 5*time.Minute).Err()
	return err
}

func (store Store) Get(ctx context.Context, id string) (*models.Note, error) {
	result, err := store.redisClient.Get(ctx, id).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return nil, nil
		}

		return nil, err
	}

	var note models.Note
	err = json.Unmarshal([]byte(result), &note)
	if err != nil {
		return nil, err
	}
	return &note, nil
}

func (store Store) Delete(ctx context.Context, id string) error {
	err := store.redisClient.Del(ctx, id).Err()
	return err
}
