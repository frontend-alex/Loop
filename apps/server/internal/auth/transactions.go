package auth

import (
	"context"
	"log/slog"

	"gorm.io/gorm"
	"loop.com/server/internal/onboarding"
	"loop.com/server/internal/user"
)

type Transactions struct {
	db     *gorm.DB
	logger *slog.Logger
}

func NewTransactions(db *gorm.DB, logger *slog.Logger) *Transactions {
	return &Transactions{
		db:     db,
		logger: logger,
	}
}

func (t *Transactions) Run(
	ctx context.Context,
	fn func(*user.Repository, *onboarding.Repository) error,
) error {
	return t.db.WithContext(ctx).Transaction(
		func(tx *gorm.DB) error {
			users := user.NewRepository(tx, t.logger)
			onboarding := onboarding.NewRepository(tx, t.logger)

			return fn(users, onboarding)
		},
	)
}
