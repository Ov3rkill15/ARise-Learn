package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	ServerPort    string
	DatabaseURL   string
	AIServiceURL  string
	CORSOrigin    string
}

func Load() *Config {
	// Load .env file if it exists (ignore error in production)
	_ = godotenv.Load()

	cfg := &Config{
		ServerPort:   getEnv("SERVER_PORT", "8080"),
		DatabaseURL:  getEnv("DATABASE_URL", "postgres://edutech:edutech@localhost:5432/edutech?sslmode=disable"),
		AIServiceURL: getEnv("AI_SERVICE_URL", "http://localhost:8000"),
		CORSOrigin:   getEnv("CORS_ORIGIN", "*"),
	}

	log.Printf("Config loaded: server=%s, db=%s, ai=%s", cfg.ServerPort, cfg.DatabaseURL, cfg.AIServiceURL)
	return cfg
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
