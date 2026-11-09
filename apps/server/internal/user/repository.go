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

func (r *Repository) Create(
	ctx context.Context,
	user *User,
) error {
	return r.db.WithContext(ctx).Create(user).Error
}

func (r *Repository) CreateAuthIdentity(
	ctx context.Context,
	identity *AuthIdentity,
) error {
	return r.db.WithContext(ctx).Create(identity).Error
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

func (r *Repository) FindById(ctx context.Context, id uint) (*User, error) {
	var user User

	err := r.db.WithContext(ctx).Where("id = ?", id).First(&user).Error

	if err != nil {
		return nil, err
	}

	return &user, nil
}
