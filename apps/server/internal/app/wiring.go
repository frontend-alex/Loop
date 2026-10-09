package app

import (
	"log/slog"

	"gorm.io/gorm"
	"loop.com/server/internal/auth"
	"loop.com/server/internal/config"
	"loop.com/server/internal/health"
	platformAuth "loop.com/server/internal/platform/auth"
	"loop.com/server/internal/user"
)

func newApplication(
	cfg config.Config,
	logger *slog.Logger,
	db *gorm.DB,
) *Application {

	userRepository := user.NewRepository(db, logger)
	userService := user.NewService(userRepository)
	jwtService := platformAuth.NewJWTService(cfg.JWT)
	authService := auth.NewService(userService, jwtService)

	return &Application{
		config:        cfg,
		logger:        logger,
		db:            db,
		healthHandler: health.NewHandler(db),
		authHandler:   auth.NewHandler(authService),
		userHandler:   user.NewHandler(userService),
		jwtService:    jwtService,
	}
}
