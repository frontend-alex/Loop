package main

import (
	"log/slog"
	"os"

	"loop.com/server/internal/app"
	"loop.com/server/internal/config"
	"loop.com/server/internal/platform/database"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		slog.Error("Configuration failed", "error", err)
		os.Exit(1)
	}

	logger := slog.New(
		slog.NewTextHandler(os.Stdout, nil),
	)

	db, err := database.Open(cfg.Database)
	if err != nil {
		logger.Error("Database connection failed", "error", err)
		os.Exit(1)
	}

	defer database.Close(db)

	application := app.New(
		cfg,
		logger,
		db,
	)

	if err := application.Run(); err != nil {
		logger.Error("Application failed", "error", err)
		os.Exit(1)
	}
}
