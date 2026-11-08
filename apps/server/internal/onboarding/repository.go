package onboarding

import (
	"context"
	"log/slog"

	"gorm.io/gorm"
)

type Repository struct {
	db     *gorm.DB
	logger *slog.Logger
}

func NewRepository(db *gorm.DB, logger *slog.Logger) *Repository {
	return &Repository{
		db:     db,
		logger: logger,
	}
}

func (r *Repository) Create(ctx context.Context, onboarding *Onboarding) error {
	return r.db.WithContext(ctx).Create(onboarding).Error
}
