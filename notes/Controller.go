package notes

import (
	"PassingNotes/notes/endpoints"
	"github.com/gin-gonic/gin"
)

func Register(group *gin.RouterGroup) {
	group.POST("", endpoints.CreateNote)
	group.DELETE("/:id", endpoints.DeleteNote)
}
