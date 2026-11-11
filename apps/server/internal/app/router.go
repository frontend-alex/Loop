package app

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"loop.com/server/internal/auth"
	"loop.com/server/internal/docs"
	"loop.com/server/internal/health"
	"loop.com/server/internal/httpx"
	"loop.com/server/internal/onboarding"
	"loop.com/server/internal/user"
)

func (app *Application) Router() http.Handler {
	r := chi.NewRouter()

	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Recoverer)

	r.Use(httpx.RequestLogger(app.logger))

	r.Use(middleware.Timeout(30 * time.Second))

	health.RegisterRoutes(r, app.healthHandler)
	if app.config.Environment == "development" {
		docs.RegisterRoutes(r)
	}

	if app.config.Environment == "development" {
		docs.RegisterRoutes(r)
	}

	r.Route("/api/v1", func(r chi.Router) {
		auth.RegisterRoutes(r, app.authHandler)
		user.RegisterRoutes(r, app.userHandler, app.jwtService)
		onboarding.RegisterRoutes(r, app.onboardingHandler, app.jwtService)
	})

	return r
}
