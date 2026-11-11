package alarm

import "github.com/go-chi/chi/v5"

func RegisterRoutes(r chi.Router, handler *Handler) {
	r.Route("/alarm", func(r chi.Router) {
		r.Get("/", handler.GetAlarms)
		r.Post("/", handler.CreateAlarm)
		r.Patch("/", handler.UpdateAlarm)
		r.Delete("/", handler.DeleteAlarm)
	})
}
