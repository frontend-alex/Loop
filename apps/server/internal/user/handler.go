package user

import (
	"net/http"

	"loop.com/server/internal/httpx"
	"loop.com/server/internal/platform/auth"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{
		service: service,
	}
}

func (h *Handler) FindUser(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())

	if !ok {
		httpx.Error(w, http.StatusUnauthorized,
			"unauthorized", "Authentication required")
		return
	}

	user, err := h.service.FindByID(r.Context(), userID)

	if err != nil {
		httpx.Error(w, http.StatusInternalServerError,
			"user_lookup_failed", "Could not load user")
		return
	}

	httpx.JSON(w, http.StatusOK, user)
}
