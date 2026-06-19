package handler

import (
	"encoding/base64"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/edutech-lidm/backend/internal/model"
	"github.com/edutech-lidm/backend/internal/service"
	"github.com/gin-gonic/gin"
)

type ScanHandler struct {
	scanService *service.ScanService
}

func NewScanHandler(scanService *service.ScanService) *ScanHandler {
	return &ScanHandler{scanService: scanService}
}

// RegisterRoutes sets up all API v1 routes
func (h *ScanHandler) RegisterRoutes(r *gin.Engine) {
	api := r.Group("/api/v1")
	{
		api.POST("/scan", h.CreateScan)
		api.POST("/scan/upload", h.UploadAndScan)
		api.POST("/scan/chat", h.ChatScoped)
		api.GET("/scan/:id", h.GetScan)
		api.GET("/users/me", h.GetUserProfile)
	}
}

// CreateScan handles POST /api/v1/scan
func (h *ScanHandler) CreateScan(c *gin.Context) {
	var req model.ScanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{
			Success: false,
			Message: "Invalid request body: " + err.Error(),
		})
		return
	}

	if req.UserID == "" || req.ImageURL == "" {
		c.JSON(http.StatusBadRequest, model.APIResponse{
			Success: false,
			Message: "user_id and image_url are required",
		})
		return
	}

	result, err := h.scanService.ProcessScan(c.Request.Context(), &req, "", "")
	if err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{
			Success: false,
			Message: "Failed to process scan: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Success: true,
		Data:    result,
	})
}

// GetScan handles GET /api/v1/scan/:id
func (h *ScanHandler) GetScan(c *gin.Context) {
	id := c.Param("id")

	result, err := h.scanService.GetScan(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, model.APIResponse{
			Success: false,
			Message: "Scan not found",
		})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Success: true,
		Data:    result,
	})
}

// GetUserProfile handles GET /api/v1/users/me (placeholder)
func (h *ScanHandler) GetUserProfile(c *gin.Context) {
	// Placeholder — auth middleware will provide user context later
	c.JSON(http.StatusOK, model.APIResponse{
		Success: true,
		Data: model.User{
			ID:    "placeholder-user-id",
			Name:  "Demo Student",
			Email: "demo@edutech.id",
			Role:  "student",
		},
	})
}

// UploadAndScan handles multipart form POST /api/v1/scan/upload
func (h *ScanHandler) UploadAndScan(c *gin.Context) {
	file, err := c.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{
			Success: false,
			Message: "Gagal menerima berkas gambar: " + err.Error(),
		})
		return
	}

	userID := c.DefaultPostForm("user_id", "demo-user")
	subjectContext := c.PostForm("context")
	language := c.DefaultPostForm("language", "id")

	uploadsDir := "./uploads"
	if err := os.MkdirAll(uploadsDir, os.ModePerm); err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{
			Success: false,
			Message: "Gagal membuat direktori unggahan: " + err.Error(),
		})
		return
	}

	// Generate unique filename with timestamp
	filename := fmt.Sprintf("%d_%s", time.Now().UnixNano(), file.Filename)
	filepathDst := filepath.Join(uploadsDir, filename)

	if err := c.SaveUploadedFile(file, filepathDst); err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{
			Success: false,
			Message: "Gagal menyimpan berkas gambar: " + err.Error(),
		})
		return
	}

	// Build public url
	scheme := "http"
	if c.Request.TLS != nil {
		scheme = "https"
	}
	host := c.Request.Host
	imageURL := fmt.Sprintf("%s://%s/uploads/%s", scheme, host, filename)

	// Read the saved image file and encode as base64 for direct transfer to AI service
	imageData, err := os.ReadFile(filepathDst)
	if err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{
			Success: false,
			Message: "Gagal membaca berkas gambar: " + err.Error(),
		})
		return
	}
	imageBase64 := base64.StdEncoding.EncodeToString(imageData)

	// Detect MIME type from extension
	mimeType := "image/jpeg"
	ext := filepath.Ext(filename)
	switch ext {
	case ".png":
		mimeType = "image/png"
	case ".webp":
		mimeType = "image/webp"
	case ".gif":
		mimeType = "image/gif"
	}

	req := model.ScanRequest{
		UserID:   userID,
		ImageURL: imageURL,
		Context:  subjectContext,
		Language: language,
	}

	result, err := h.scanService.ProcessScan(c.Request.Context(), &req, imageBase64, mimeType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{
			Success: false,
			Message: "Gagal memproses pemindaian gambar: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Success: true,
		Data:    result,
	})
}

// ChatScoped handles POST /api/v1/scan/chat
func (h *ScanHandler) ChatScoped(c *gin.Context) {
	var req model.ChatRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{
			Success: false,
			Message: "Invalid request body: " + err.Error(),
		})
		return
	}

	if req.Topic == "" || req.Message == "" {
		c.JSON(http.StatusBadRequest, model.APIResponse{
			Success: false,
			Message: "topic and message are required",
		})
		return
	}

	result, err := h.scanService.ChatScoped(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{
			Success: false,
			Message: "Gagal memproses obrolan AI: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Success: true,
		Data:    result,
	})
}
