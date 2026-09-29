package app

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"loop.com/server/internal/auth"
	"loop.com/server/internal/health"
	"loop.com/server/internal/httpx"
)

func (app *Application) Router() http.Handler {
	r := chi.NewRouter()

	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Recoverer)

	r.Use(httpx.RequestLogger(app.logger))

	r.Use(middleware.Timeout(30 * time.Second))

	health.RegisterRoutes(r, app.healthHandler)

	r.Route("/api/v1", func(r chi.Router) {
		auth.RegisterRoutes(r, app.authHandler)
	})

	return r
}
