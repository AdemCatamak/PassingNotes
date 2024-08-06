package endpoints

import (
	"PassingNotes/notes/models"
	"PassingNotes/notes/stores"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"net/http"
)

type CreateNoteReq struct {
	Text string `json:"text" binding:"required"`
}

type CreateNoteResp struct {
	Id string `json:"id"`
}

func CreateNote(context *gin.Context) {

	var req CreateNoteReq
	err := context.ShouldBindJSON(&req)
	if err != nil {
		context.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	note := models.Note{
		Id:   uuid.New().String(),
		Text: req.Text,
	}
	store := stores.NewStore()
	err = store.Add(context, note)
	if err != nil {
		context.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	res := CreateNoteResp{
		Id: note.Id,
	}
	context.JSON(http.StatusCreated, res)
}
