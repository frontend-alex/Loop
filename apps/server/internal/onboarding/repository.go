package onboarding

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"time"

	"gorm.io/gorm"
)

var ErrAlreadyCompleted = errors.New("onboarding already completed")

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

func (r *Repository) Update(
	ctx context.Context,
	userID uint,
	answers map[string]json.RawMessage,
	currentStep int,
) error {
	result := r.db.WithContext(ctx).
		Model(&Onboarding{}).
		Where("user_id = ? AND completed_at IS NULL", userID).
		Select("Answers", "CurrentStep", "UpdatedAt").
		Updates(&Onboarding{
			Answers:     answers,
			CurrentStep: currentStep,
		})

	if result.Error != nil {
		return result.Error
	}

	if result.RowsAffected == 0 {
		var existing Onboarding
		if err := r.db.WithContext(ctx).Where("user_id = ?", userID).First(&existing).Error; err != nil {
			return err
		}
		return ErrAlreadyCompleted
	}

	return nil
}

func (r *Repository) Complete(
	ctx context.Context,
	userID uint,
	answers map[string]json.RawMessage,
	currentStep int,
) error {
	now := time.Now().UTC()
	result := r.db.WithContext(ctx).
		Model(&Onboarding{}).
		Where("user_id = ? AND completed_at IS NULL", userID).
		Select("Answers", "CurrentStep", "CompletedAt", "UpdatedAt").
		Updates(&Onboarding{
			Answers:     answers,
			CurrentStep: currentStep,
			CompletedAt: &now,
		})

	if result.Error != nil {
		return result.Error
	}

	if result.RowsAffected == 0 {
		// An existing row means a previous completion won. Preserve it on retries.
		var existing Onboarding
		return r.db.WithContext(ctx).Where("user_id = ?", userID).First(&existing).Error
	}

	return nil
}
