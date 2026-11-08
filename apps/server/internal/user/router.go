package user

import (
	"github.com/go-chi/chi/v5"
	platformAuth "loop.com/server/internal/platform/auth"
)

func RegisterRoutes(r chi.Router, handler *Handler, jwtService *platformAuth.JWTService) {
	r.With(jwtService.Middleware).Route("/users", func(r chi.Router) {
		r.Get("/me", handler.FindUser)
	})
}
