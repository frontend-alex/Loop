package app

import (
	"log/slog"

	"gorm.io/gorm"
	"loop.com/server/internal/auth"
	"loop.com/server/internal/config"
	"loop.com/server/internal/health"
	"loop.com/server/internal/onboarding"
	platformAuth "loop.com/server/internal/platform/auth"
	"loop.com/server/internal/user"
)

func newApplication(
	cfg config.Config,
	logger *slog.Logger,
	db *gorm.DB,
) *Application {
	
	// Repositories: database access for each feature.
	userRepository := user.NewRepository(db, logger)
	onboardingRepository := onboarding.NewRepository(db, logger)

	// Authentication infrastructure: JWT handling and transactional account setup.
	jwtService := platformAuth.NewJWTService(cfg.JWT)
	transactions := auth.NewTransactions(db, logger)

	// Services: feature behaviour and orchestration using the dependencies above.
	userService := user.NewService(userRepository)
	authService := auth.NewService(userService, transactions, jwtService)
	onboardingService := onboarding.NewService(onboardingRepository)

	return &Application{
		// Shared application dependencies.
		config: cfg,
		logger: logger,
		db:     db,

		// HTTP handlers: process requests using their feature dependencies.
		healthHandler:     health.NewHandler(db),
		authHandler:       auth.NewHandler(authService),
		userHandler:       user.NewHandler(userService),
		onboardingHandler: onboarding.NewHandler(onboardingService),

		// JWT dependency used to protect routes during router registration.
		jwtService: jwtService,
	}
}
