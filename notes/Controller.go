package notes

import (
	"PassingNotes/notes/endpoints"
	"github.com/gin-gonic/gin"
	"net/http"
)

func Register(g *gin.Engine) {
	g.LoadHTMLFiles("./notes/htmlTemplates/index.html")

	serveIndexHtml := func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", nil)
	}

	g.GET("/", serveIndexHtml)
	g.GET("/index", serveIndexHtml)
	g.GET(":noteId", func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", nil)
	})

	group := g.Group("/api/notes")

	group.POST("", endpoints.CreateNote)
	group.DELETE("/:id", endpoints.DeleteNote)
}
