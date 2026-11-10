package user

import (
	"context"
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{
		repo: repo,
	}
}

func (s *Service) FindFromOAuth(ctx context.Context, provider, providerUserID string) (*User, error) {
	existing, err := s.repo.FindAuthIdentity(
		ctx,
		provider,
		providerUserID,
	)

	if err != nil {
		return nil, err
	}

	return &existing.User, nil
}

func (s *Service) FindByID(ctx context.Context, userID uint) (*User, error) {
	existing, err := s.repo.FindById(ctx, userID)

	if err != nil {
		return nil, err
	}

	return existing, nil
}

func (s *Service) HasCompletedOnboarding(ctx context.Context, userID uint) (bool, error) {
	return s.repo.HasCompletedOnboarding(ctx, userID)
}
