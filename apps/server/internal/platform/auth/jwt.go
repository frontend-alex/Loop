package auth

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
	"loop.com/server/internal/config"
)

type JWTService struct {
	secret     []byte
	Expiration time.Duration
}

func NewJWTService(cfg config.JWTConfig) *JWTService {
	return &JWTService{
		secret:     []byte(cfg.Secret),
		Expiration: cfg.Expiration,
	}
}

func (s *JWTService) GenerateToken(userID uint) (string, error) {
	claims := jwt.MapClaims{
		"user_id": userID,
		"exp":     time.Now().Add(s.Expiration).Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	return token.SignedString(s.secret)
}

func (s *JWTService) ValidateToken(tokenString string) (*jwt.Token, error) {
	return jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return s.secret, nil
	})
}

func (s *JWTService) ExtractUserID(token *jwt.Token) (uint, error) {
	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		if userID, ok := claims["user_id"].(float64); ok {
			return uint(userID), nil
		}
	}
	return 0, jwt.ErrInvalidKey
}

func (s *JWTService) RefreshToken(tokenString string) (string, error) {
	token, err := s.ValidateToken(tokenString)

	if err != nil {
		return "", err
	}

	userID, err := s.ExtractUserID(token)

	if err != nil {
		return "", err
	}

	return s.GenerateToken(userID)
}
