package auth_test

import (
	"testing"
	"time"

	"loop.com/server/internal/config"
	"loop.com/server/internal/platform/auth"
)

func TestValidTokenContainsCorrectUser(t *testing.T) {

	//arange: Use a test-only secret
	service := auth.NewJWTService(config.JWTConfig{
		Secret:     "real-test-only-secret",
		Expiration: time.Hour,
	})

	//act: create and validate token for user 67
	rawToken, err := service.GenerateToken(67)
	if err != nil {
		t.Fatal(err)
	}

	token, err := service.ValidateToken(rawToken)
	if err != nil {
		t.Fatal(err)
	}

	userID, err := service.ExtractUserID(token)
	if err != nil {
		t.Fatal(err)
	}

	if userID != 67 {
		t.Fatalf("Expected user 67, got %d", userID)
	}
}
