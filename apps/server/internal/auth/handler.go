package auth

import (
	"fmt"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/markbates/goth/gothic"
	"loop.com/server/internal/httpx"
)

type Handler struct {
	// users *users.Service
}

func NewHandler() *Handler {
	return &Handler{}
}

func (h *Handler) Begin(w http.ResponseWriter, r *http.Request) {
	gothic.BeginAuthHandler(w, withProvider(r))
}

func (h *Handler) Callback(w http.ResponseWriter, r *http.Request) {
	user, err := gothic.CompleteUserAuth(w, withProvider(r))

	if err != nil {
		httpx.Error(
			w,
			http.StatusUnauthorized,
			"authentication_failed",
			err.Error(),
		)
		return
	}

	response := struct {
		Provider string `json:"provider"`
		UserID   string `json:"user_id"`
		Email    string `json:"email"`
		Name     string `json:"name"`
	}{
		Provider: user.Provider,
		UserID:   user.UserID,
		Email:    user.Email,
		Name:     user.Name,
	}

	httpx.JSON(w, http.StatusAccepted, response)

}

func withProvider(r *http.Request) *http.Request {
	provider := chi.URLParam(r, "provider")

	fmt.Printf(provider)

	request := r.Clone(r.Context())
	query := request.URL.Query()
	query.Set("provider", provider)
	request.URL.RawQuery = query.Encode()

	return request
}
