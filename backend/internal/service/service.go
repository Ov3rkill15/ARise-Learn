package service

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
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
func (s *ScanService) ProcessScan(ctx context.Context, req *model.ScanRequest, imageBase64 string, mimeType string) (*model.ScanResult, error) {
	// If base64 is not provided, download the image from URL and encode it
	if imageBase64 == "" && req.ImageURL != "" {
		fmt.Printf("[ProcessScan] Downloading image from URL: %s\n", req.ImageURL)
		dlCtx, cancel := context.WithTimeout(ctx, 15*time.Second)
		defer cancel()
		dlReq, _ := http.NewRequestWithContext(dlCtx, http.MethodGet, req.ImageURL, nil)
		imgResp, err := s.httpClient.Do(dlReq)
		if err != nil {
			fmt.Printf("[ProcessScan] Warning: failed to download image: %v (proceeding without base64)\n", err)
		} else {
			defer imgResp.Body.Close()
			if imgResp.StatusCode == http.StatusOK {
				imgData, err := io.ReadAll(imgResp.Body)
				if err == nil {
					imageBase64 = base64.StdEncoding.EncodeToString(imgData)
					// Detect MIME type from Content-Type header
					ct := imgResp.Header.Get("Content-Type")
					if strings.HasPrefix(ct, "image/") {
						mimeType = ct
					} else {
						mimeType = "image/jpeg"
					}
					fmt.Printf("[ProcessScan] Image downloaded: %d bytes, type: %s\n", len(imgData), mimeType)
				}
			} else {
				fmt.Printf("[ProcessScan] Warning: image URL returned status %d\n", imgResp.StatusCode)
			}
		}
	}

	// Forward to AI service
	analyzeReq := model.AnalyzeRequest{
		ImageURL:    req.ImageURL,
		ImageBase64: imageBase64,
		MimeType:    mimeType,
		Context:     req.Context,
		Language:    req.Language,
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
		respBody, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("AI service returned status %d: %s", resp.StatusCode, string(respBody))
	}

	var analyzeResp model.AnalyzeResponse
	if err := json.NewDecoder(resp.Body).Decode(&analyzeResp); err != nil {
		return nil, fmt.Errorf("failed to decode AI response: %w", err)
	}

	// Build and persist scan result
	result := &model.ScanResult{
		UserID:          req.UserID,
		ImageURL:        req.ImageURL,
		Explanation:     analyzeResp.Explanation,
		Asset3DURL:      analyzeResp.Asset3DHint,
		Confidence:      analyzeResp.Confidence,
		SubjectTopic:    analyzeResp.SubjectTopic,
		Recommendations: analyzeResp.Recommendations,
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
		respBody, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("AI service returned status %d: %s", resp.StatusCode, string(respBody))
	}

	var chatResp model.ChatResponse
	if err := json.NewDecoder(resp.Body).Decode(&chatResp); err != nil {
		return nil, fmt.Errorf("failed to decode AI chat response: %w", err)
	}

	return &chatResp, nil
}
