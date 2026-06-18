package handler

import (
	"net/http"

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

	result, err := h.scanService.ProcessScan(c.Request.Context(), &req)
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
			ID:   "placeholder-user-id",
			Name: "Demo Student",
			Email: "demo@edutech.id",
			Role: "student",
		},
	})
}
