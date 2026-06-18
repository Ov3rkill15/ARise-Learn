package model

import "time"

// User represents a registered user (student or lecturer)
type User struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Email     string    `json:"email"`
	Role      string    `json:"role"` // "student" | "lecturer"
	CreatedAt time.Time `json:"created_at"`
}

// ScanRequest represents an incoming scan submission
type ScanRequest struct {
	UserID   string `json:"user_id"`
	ImageURL string `json:"image_url"`
	Context  string `json:"context,omitempty"` // optional subject/course context
}

// ScanResult represents the AI-generated explanation from a scan
type ScanResult struct {
	ID            string    `json:"id"`
	UserID        string    `json:"user_id"`
	ImageURL      string    `json:"image_url"`
	Explanation   string    `json:"explanation"`
	Asset3DURL    string    `json:"asset_3d_url,omitempty"`
	Confidence    float64   `json:"confidence"`
	SubjectTopic  string    `json:"subject_topic"`
	CreatedAt     time.Time `json:"created_at"`
}

// Asset3D represents a 3D model metadata for AR rendering
type Asset3D struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	ModelURL    string    `json:"model_url"` // URL to .glb/.usdz file
	SubjectTopic string   `json:"subject_topic"`
	CreatedAt   time.Time `json:"created_at"`
}

// AnalyzeRequest is the payload sent to the AI service
type AnalyzeRequest struct {
	ImageURL string `json:"image_url"`
	Context  string `json:"context,omitempty"`
}

// AnalyzeResponse is the response from the AI service
type AnalyzeResponse struct {
	Explanation  string  `json:"explanation"`
	SubjectTopic string  `json:"subject_topic"`
	Confidence   float64 `json:"confidence"`
	Asset3DHint  string  `json:"asset_3d_hint,omitempty"`
}

// APIResponse is a generic API response wrapper
type APIResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Message string      `json:"message,omitempty"`
}

// ChatRequest is the payload sent to the chat API
type ChatRequest struct {
	Topic   string           `json:"topic"`
	Message string           `json:"message"`
	History []map[string]any `json:"history,omitempty"`
}

// ChatResponse is the response from the chat API
type ChatResponse struct {
	Reply string `json:"reply"`
}
