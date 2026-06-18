package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/edutech-lidm/backend/config"
	"github.com/edutech-lidm/backend/internal/handler"
	"github.com/edutech-lidm/backend/internal/middleware"
	"github.com/edutech-lidm/backend/internal/repository"
	"github.com/edutech-lidm/backend/internal/service"
	"github.com/gin-gonic/gin"
)

func main() {
	cfg := config.Load()

	// Connect to PostgreSQL
	ctx := context.Background()
	pool, err := repository.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Printf("Warning: database not available (%v). Running without persistence.", err)
		pool = nil
	}
	defer func() {
		if pool != nil {
			pool.Close()
		}
	}()

	// Initialize layers
	scanRepo := repository.NewScanRepository(pool)
	scanService := service.NewScanService(scanRepo, cfg.AIServiceURL)
	scanHandler := handler.NewScanHandler(scanService)

	// Setup Gin
	r := gin.Default()
	r.Use(middleware.SetupCORS(cfg.CORSOrigin))
	r.Use(middleware.RequestLogger())
	r.Use(middleware.Recovery())

	// Serve static files for uploaded textbook images
	r.Static("/uploads", "./uploads")

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "edutech-backend"})
	})

	// Register API routes
	scanHandler.RegisterRoutes(r)

	// Graceful shutdown
	addr := fmt.Sprintf(":%s", cfg.ServerPort)
	srv := &http.Server{Addr: addr, Handler: r}

	go func() {
		log.Printf("Backend server starting on %s", addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server error: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("Server forced shutdown: %v", err)
	}
	log.Println("Server stopped.")
}
