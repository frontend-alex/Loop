package auth

import "github.com/go-chi/chi/v5"

func RegisterRoutes(r chi.Router, handler *Handler) {
	r.Route("/auth", func(r chi.Router) {
		r.Get("/{provider}", handler.Begin)
		r.Get("/{provider}/callback", handler.Callback)
	})
}
