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

type FindUserResponse struct {
	User               *User
	RequiredOnboarding bool `json:"requiresOnboarding"`
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

	completed, err := h.service.HasCompletedOnboarding(r.Context(), userID)

	if err != nil {
		httpx.Error(w, http.StatusInternalServerError,
			"onboarding_lookup_failed", "Could not load onboarding status")
		return
	}

	w.Header().Set("Cache-Control", "no-store")

	httpx.JSON(w, http.StatusOK, FindUserResponse{
		User:               user,
		RequiredOnboarding: !completed,
	})
}
