package auth

import (
	"context"
	"encoding/json"

	"loop.com/server/internal/onboarding"
	platformAuth "loop.com/server/internal/platform/auth"
	userModel "loop.com/server/internal/user"
)

type Service struct {
	users        *userModel.Service
	transactions *Transactions
	jwt          *platformAuth.JWTService
}

func NewService(users *userModel.Service, transactions *Transactions, jwt *platformAuth.JWTService) *Service {
	return &Service{
		users:        users,
		transactions: transactions,
		jwt:          jwt,
	}
}

func (s *Service) Authenticate(
	ctx context.Context,
	identity userModel.AuthIdentity,
	user userModel.User,
) (string, error) {

	existing, err := s.users.FindFromOAuth(ctx, identity.Provider, identity.ProviderUserID)

	if err == nil {
		return s.jwt.GenerateToken(existing.ID)
	}

	err = s.transactions.Run(ctx, func(
		users *userModel.Repository,
		onboardings *onboarding.Repository,
	) error {
		if err := users.Create(ctx, &user); err != nil {
			return err
		}

		identity.UserID = user.ID

		if err := users.CreateAuthIdentity(ctx, &identity); err != nil {
			return err
		}

		record := onboarding.Onboarding{
			UserID:  user.ID,
			Answers: make(map[string]json.RawMessage),
		}

		if err := onboardings.Create(ctx, &record); err != nil {
			return err
		}

		return nil
	})

	if err != nil {
		return "", err
	}

	return s.jwt.GenerateToken(user.ID)
}
