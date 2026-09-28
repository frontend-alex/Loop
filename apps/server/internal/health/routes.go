package health

import "github.com/go-chi/chi/v5"

func RegisterRoutes(r chi.Router, handler *Handler) {
	r.Get("/health/live", handler.Live)
	r.Get("/health/ready", handler.Ready)
}
