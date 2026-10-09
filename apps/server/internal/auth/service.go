package auth

import (
	"context"

	platformAuth "loop.com/server/internal/platform/auth"
	"loop.com/server/internal/user"
)

type Service struct {
	users *user.Service
	jwt   *platformAuth.JWTService
}

func NewService(users *user.Service, jwt *platformAuth.JWTService) *Service {
	return &Service{
		users: users,
		jwt:   jwt,
	}
}

func (s *Service) Authenticate(
	ctx context.Context,
	identity user.AuthIdentity,
	user user.User,
) (string, error) {
	account, err := s.users.FindOrCreateFromOAuth(
		ctx,
		identity,
		user,
	)

	if err != nil {
		return "", err
	}

	return s.jwt.GenerateToken(account.ID)
}
