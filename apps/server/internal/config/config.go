package config

import (
	"errors"
	"os"
	"time"
)

type Config struct {
	Environment   string
	HTTP          HTTPConfig
	Database      DatabaseConfig
	AuthProviders AuthProvidersConfig
}

type HTTPConfig struct {
	Addr            string
	ReadTimeout     time.Duration
	WriteTimeout    time.Duration
	IdleTimeout     time.Duration
	ShutdownTimeout time.Duration
}

type DatabaseConfig struct {
	DSN             string
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime time.Duration
}

type AuthProvidersConfig struct {
	Key    string
	MaxAge int
	Google GoogleConfig
	Apple  AppleConfig
}

type GoogleConfig struct {
	ClientID     string
	ClientSecret string
	CallbackURL  string
}

type AppleConfig struct {
	ClientID     string
	ClientSecret string
	CallbackURL  string
}

func Load() (Config, error) {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		return Config{}, errors.New("DATABASE_URL is required")
	}

	return Config{
		Environment: getEnv("APP_ENV", "development"),
		HTTP: HTTPConfig{
			Addr:            getEnv("HTTP_ADDR", ":8080"),
			ReadTimeout:     10 * time.Second,
			WriteTimeout:    30 * time.Second,
			IdleTimeout:     time.Minute,
			ShutdownTimeout: 10 * time.Second,
		},
		Database: DatabaseConfig{
			DSN:             dsn,
			MaxOpenConns:    20,
			MaxIdleConns:    5,
			ConnMaxLifetime: 30 * time.Minute,
		},
		AuthProviders: AuthProvidersConfig{
			Key:    getEnv("AUTH_KEY", "development-only-change-me"),
			MaxAge: 86400 * 30,
			Google: GoogleConfig{
				ClientID:     getEnv("GOOGLE_CLIENT_ID", ""),
				ClientSecret: getEnv("GOOGLE_CLIENT_SECRET", ""),
				CallbackURL:  getEnv("GOOGLE_CALLBACK_URL", "http://localhost:8080/auth/google/callback"),
			},
			Apple: AppleConfig{
				ClientID:     getEnv("APPLE_CLIENT_ID", ""),
				ClientSecret: getEnv("APPLE_CLIENT_SECRET", ""),
				CallbackURL:  getEnv("APPLE_CALLBACK_URL", "http://localhost:8080/auth/apple/callback"),
			},
		},
	}, nil
}

func getEnv(key, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}

	return value
}
