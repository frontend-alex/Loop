package onboarding

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

func (s *Service) UpdateOnboarding(ctx context.Context, userID uint, data OnboardingRequest) error {
	return s.repo.Update(
		ctx,
		userID,
		data.Answers,
		data.CurrentStep,
	)
}

func (s *Service) CompleteOnboarding(ctx context.Context, userID uint, data OnboardingRequest) error {
	return s.repo.Complete(
		ctx,
		userID,
		data.Answers,
		data.CurrentStep,
	)
}
