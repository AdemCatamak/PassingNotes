package endpoints

import (
	"PassingNotes/notes/stores"
	"github.com/gin-gonic/gin"
	"log"
	"net/http"
)

type DeleteNoteRes struct {
	Text string `json:"text"`
}

func DeleteNote(context *gin.Context) {
	id := context.Param("id")

	store := stores.NewStore()
	note, err := store.Get(context, id)
	if err != nil {
		context.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if note == nil {
		context.JSON(http.StatusNotFound, gin.H{"error": "note not found"})
		return
	}

	err = store.Delete(context, id)
	if err != nil {
		log.Print(err)
	}

	res := DeleteNoteRes{
		Text: note.Text,
	}
	context.JSON(http.StatusOK, res)
}
