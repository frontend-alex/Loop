package onboarding

import (
	"encoding/json"
	"errors"
	"net/http"

	"gorm.io/gorm"
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

type OnboardingRequest struct {
	Answers     map[string]json.RawMessage `json:"answers"`
	CurrentStep int                        `json:"currentStep"`
}

func (h *Handler) UpdateOnboarding(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())

	if !ok {
		httpx.Error(w, http.StatusUnauthorized,
			"unauthorized", "Authentication required")
		return
	}

	var data OnboardingRequest

	err := httpx.DecodeJSONBody(w, r, &data)

	if err != nil {
		var malformed *httpx.MalformedRequest

		if errors.As(err, &malformed) {
			httpx.Error(
				w,
				malformed.Status,
				"invalid_request_body",
				malformed.Message,
			)
			return
		}
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"internal_server_error",
			"Could not process request body",
		)
		return
	}

	if err := h.service.UpdateOnboarding(r.Context(), userID, data); err != nil {
		writeOnboardingError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)

}

func (h *Handler) CompleteOnboarding(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())

	if !ok {
		httpx.Error(w, http.StatusUnauthorized,
			"unauthorized", "Authentication required")
		return
	}

	var data OnboardingRequest

	err := httpx.DecodeJSONBody(w, r, &data)

	if err != nil {
		var malformed *httpx.MalformedRequest

		if errors.As(err, &malformed) {
			httpx.Error(
				w,
				malformed.Status,
				"invalid_request_body",
				malformed.Message,
			)
			return
		}
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"internal_server_error",
			"Could not process request body",
		)
		return
	}

	if err := h.service.CompleteOnboarding(r.Context(), userID, data); err != nil {
		writeOnboardingError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)

}

func writeOnboardingError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(w, http.StatusNotFound, "onboarding_not_found", "Onboarding not found")
	case errors.Is(err, ErrAlreadyCompleted):
		httpx.Error(w, http.StatusConflict, "onboarding_completed", "Completed onboarding cannot be updated")
	default:
		httpx.Error(w, http.StatusInternalServerError, "onboarding_save_failed", "Could not save onboarding")
	}
}
