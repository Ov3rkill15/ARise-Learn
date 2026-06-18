package service

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/edutech-lidm/backend/internal/model"
	"github.com/edutech-lidm/backend/internal/repository"
)

type ScanService struct {
	repo         *repository.ScanRepository
	aiServiceURL string
	httpClient   *http.Client
}

func NewScanService(repo *repository.ScanRepository, aiServiceURL string) *ScanService {
	return &ScanService{
		repo:         repo,
		aiServiceURL: aiServiceURL,
		httpClient:   &http.Client{Timeout: 60 * time.Second},
	}
}

// ProcessScan sends the image to the AI service, stores the result, and returns it
func (s *ScanService) ProcessScan(ctx context.Context, req *model.ScanRequest) (*model.ScanResult, error) {
	// Forward to AI service
	analyzeReq := model.AnalyzeRequest{
		ImageURL: req.ImageURL,
		Context:  req.Context,
	}

	body, err := json.Marshal(analyzeReq)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	resp, err := s.httpClient.Post(
		s.aiServiceURL+"/api/v1/analyze",
		"application/json",
		bytes.NewReader(body),
	)
	if err != nil {
		return nil, fmt.Errorf("AI service request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("AI service returned status %d", resp.StatusCode)
	}

	var analyzeResp model.AnalyzeResponse
	if err := json.NewDecoder(resp.Body).Decode(&analyzeResp); err != nil {
		return nil, fmt.Errorf("failed to decode AI response: %w", err)
	}

	// Build and persist scan result
	result := &model.ScanResult{
		UserID:       req.UserID,
		ImageURL:     req.ImageURL,
		Explanation:  analyzeResp.Explanation,
		Asset3DURL:   analyzeResp.Asset3DHint,
		Confidence:   analyzeResp.Confidence,
		SubjectTopic: analyzeResp.SubjectTopic,
	}

	if err := s.repo.CreateScan(ctx, result); err != nil {
		// Log but still return the result even if DB write fails
		fmt.Printf("Warning: failed to persist scan result: %v\n", err)
	}

	return result, nil
}

// GetScan retrieves a stored scan result by ID
func (s *ScanService) GetScan(ctx context.Context, id string) (*model.ScanResult, error) {
	return s.repo.GetScanByID(ctx, id)
}

// ChatScoped forwards the Q&A request to the Python AI service
func (s *ScanService) ChatScoped(ctx context.Context, req *model.ChatRequest) (*model.ChatResponse, error) {
	body, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	resp, err := s.httpClient.Post(
		s.aiServiceURL+"/api/v1/chat",
		"application/json",
		bytes.NewReader(body),
	)
	if err != nil {
		return nil, fmt.Errorf("AI chat request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("AI service returned status %d", resp.StatusCode)
	}

	var chatResp model.ChatResponse
	if err := json.NewDecoder(resp.Body).Decode(&chatResp); err != nil {
		return nil, fmt.Errorf("failed to decode AI chat response: %w", err)
	}

	return &chatResp, nil
}
