package testutil

import (
	"log/slog"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	"gorm.io/gorm"
	"loop.com/server/internal/config"
	"loop.com/server/internal/onboarding"
	"loop.com/server/internal/user"

	appAuth "loop.com/server/internal/auth"
	platformAuth "loop.com/server/internal/platform/auth"
)

func AuthFixture(t *testing.T) (*gorm.DB, *appAuth.Service, *platformAuth.JWTService) {
	t.Helper()

	db := NewtDB(t)
	require.NoError(t, db.AutoMigrate(
		&user.User{},
		&user.AuthIdentity{},
		&onboarding.Onboarding{},
	))

	logger := slog.Default()

	users := user.NewService(user.NewRepository(db, logger))

	jwt := platformAuth.NewJWTService(config.JWTConfig{
		Secret:     "real-test-only-secret",
		Expiration: time.Hour,
	})

	service := appAuth.NewService(
		users,
		appAuth.NewTransactions(db, logger),
		jwt,
	)

	return db, service, jwt
}
