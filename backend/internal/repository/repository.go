package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/edutech-lidm/backend/internal/model"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type ScanRepository struct {
	pool *pgxpool.Pool
}

func NewScanRepository(pool *pgxpool.Pool) *ScanRepository {
	return &ScanRepository{pool: pool}
}

// CreateScan stores a new scan result in the database
func (r *ScanRepository) CreateScan(ctx context.Context, result *model.ScanResult) error {
	result.ID = uuid.New().String()
	result.CreatedAt = time.Now()

	if r.pool == nil {
		// No DB available — just assign ID and return
		return nil
	}

	query := `
		INSERT INTO scans (id, user_id, image_url, explanation, asset_3d_url, confidence, subject_topic, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`
	_, err := r.pool.Exec(ctx, query,
		result.ID, result.UserID, result.ImageURL, result.Explanation,
		result.Asset3DURL, result.Confidence, result.SubjectTopic, result.CreatedAt,
	)
	return err
}

// GetScanByID retrieves a scan result by its ID
func (r *ScanRepository) GetScanByID(ctx context.Context, id string) (*model.ScanResult, error) {
	if r.pool == nil {
		return nil, fmt.Errorf("database not available")
	}

	result := &model.ScanResult{}
	query := `
		SELECT id, user_id, image_url, explanation, asset_3d_url, confidence, subject_topic, created_at
		FROM scans WHERE id = $1
	`
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&result.ID, &result.UserID, &result.ImageURL, &result.Explanation,
		&result.Asset3DURL, &result.Confidence, &result.SubjectTopic, &result.CreatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("scan not found: %w", err)
	}
	return result, nil
}

// Connect initializes a PostgreSQL connection pool
func Connect(ctx context.Context, dbURL string) (*pgxpool.Pool, error) {
	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return pool, nil
}
