package user

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{
		repo: repo,
	}
}

func (s *Service) FindOrCreateFromOAuth(ctx context.Context, identity AuthIdentity, user User) (*User, error) {
	existing, err := s.repo.FindAuthIdentity(
		ctx,
		identity.Provider,
		identity.ProviderUserID,
	)

	if err == nil {
		return &existing.User, nil
	}

	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}

	return s.repo.CreateUserWithIdentity(ctx, identity, user)
}
