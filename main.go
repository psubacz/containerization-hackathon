package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func main() {
	// Create a Gin router with default middleware (logger and recovery)
	r := gin.Default()

	// Basic route
	r.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Hello, World!",
			"status":  "success",
		})
	})

	// Route with path parameter
	r.GET("/user/:name", func(c *gin.Context) {
		name := c.Param("name")
		c.JSON(http.StatusOK, gin.H{
			"message": "Hello, " + name + "!",
			"user":    name,
		})
	})

	// Route with query parameters
	r.GET("/search", func(c *gin.Context) {
		query := c.DefaultQuery("q", "")
		limit := c.DefaultQuery("limit", "10")

		c.JSON(http.StatusOK, gin.H{
			"query": query,
			"limit": limit,
		})
	})

	// POST route
	r.POST("/data", func(c *gin.Context) {
		var json map[string]interface{}

		if err := c.ShouldBindJSON(&json); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": err.Error(),
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Data received successfully",
			"data":    json,
		})
	})

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
		})
	})

	// Start server on port 8080
	r.Run(":8080")
}
