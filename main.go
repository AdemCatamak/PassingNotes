package main

import (
	"PassingNotes/notes"
	"errors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"log"
)

func init() {

	err := godotenv.Load()
	if err != nil {
		e := errors.Join(err, errors.New("error loading .env file"))
		panic(e)
	}

}

func main() {

	g := gin.Default()
	g.Use(gin.Recovery())

	api := g.Group("/api")
	notes.Register(api.Group("/notes"))

	log.Fatal(g.Run())

}
