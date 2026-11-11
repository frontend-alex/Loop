package alarm

import "net/http"

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{
		service: service,
	}
}

func (h *Handler) CreateAlarm(w http.ResponseWriter, r *http.Request) {

}

func (h *Handler) UpdateAlarm(w http.ResponseWriter, r *http.Request) {

}

func (h *Handler) GetAlarms(w http.ResponseWriter, r *http.Request) {

}

func (h *Handler) DeleteAlarm(w http.ResponseWriter, r *http.Request) {

}
