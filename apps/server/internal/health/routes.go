package health

import "github.com/go-chi/chi/v5"

func RegisterRoutes(r chi.Router, handler *Handler) {
	r.Route("/health", func(r chi.Router) {
		r.Get("/live", handler.Live)
		r.Get("/ready", handler.Ready)
	})
}
