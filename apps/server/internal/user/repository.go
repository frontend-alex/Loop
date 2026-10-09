package user

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

func (r *Repository) FindAuthIdentity(
	ctx context.Context,
	provider string,
	providerUserID string,
) (*AuthIdentity, error) {
	var identity AuthIdentity

	err := r.db.WithContext(ctx).
		Preload("User").
		Where("provider = ? AND provider_user_id = ?", provider, providerUserID).
		First(&identity).Error

	if err != nil {
		return nil, err
	}

	return &identity, nil
}

func (r *Repository) CreateUserWithIdentity(
	ctx context.Context,
	identity AuthIdentity,
	user User,
) (*User, error) {
	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&user).Error; err != nil {
			return err
		}

		identity.UserID = user.ID

		if err := tx.Create(&identity).Error; err != nil {
			return err
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return &user, nil
}
