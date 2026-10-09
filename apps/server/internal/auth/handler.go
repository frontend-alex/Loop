package auth

import (
	"net/http"
	"net/url"

	"github.com/go-chi/chi/v5"
	"github.com/markbates/goth/gothic"
	"loop.com/server/internal/httpx"
	"loop.com/server/internal/user"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) Begin(w http.ResponseWriter, r *http.Request) {
	gothic.BeginAuthHandler(w, withProvider(r))
}

func (h *Handler) Callback(w http.ResponseWriter, r *http.Request) {
	data, err := gothic.CompleteUserAuth(w, withProvider(r))

	if err != nil {
		httpx.Error(
			w,
			http.StatusUnauthorized,
			"authentication_failed",
			err.Error(),
		)
		return
	}

	identity := user.AuthIdentity{
		Provider:       data.Provider,
		ProviderUserID: data.UserID,
	}

	user := user.User{
		Email:     data.Email,
		Name:      data.FirstName + data.LastName,
		AvatarURL: data.AvatarURL,
	}

	token, err := h.service.Authenticate(
		r.Context(),
		identity,
		user,
	)
	if err != nil {
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"authentication_failed",
			err.Error(),
		)
		return
	}

	callbackUrl := url.URL{
		Scheme: "loop",
		Host:   "auth",
		Path:   "/callback",
		RawQuery: url.Values{
			"token": []string{token},
		}.Encode(),
	}

	http.Redirect(
		w,
		r,
		callbackUrl.String(),
		http.StatusFound,
	)
}

func withProvider(r *http.Request) *http.Request {
	provider := chi.URLParam(r, "provider")
	request := r.Clone(r.Context())
	query := request.URL.Query()
	query.Set("provider", provider)
	request.URL.RawQuery = query.Encode()

	return request
}
