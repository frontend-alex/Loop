package auth

import (
	"net/http"

	"github.com/gorilla/sessions"
	"github.com/markbates/goth"
	"github.com/markbates/goth/gothic"
	"github.com/markbates/goth/providers/apple"
	"github.com/markbates/goth/providers/google"

	"loop.com/server/internal/config"
)

func NewAuth(cfg config.Config) {
	store := sessions.NewCookieStore([]byte(cfg.AuthProviders.Key))
	store.MaxAge(cfg.AuthProviders.MaxAge)

	// store.Options.Path = "/"
	// store.Options.HttpOnly = true
	// store.Options.Secure = cfg.Environment != "development"

	store.Options.Secure = false                  // Sends cookies only over HTTPS. 
	store.Options.HttpOnly = true                 // Prevents JavaScript cookie access.
	store.Options.Path = "/"                      // Makes cookie available site-wide.
	store.Options.SameSite = http.SameSiteLaxMode // Controls cross-site cookie behavior.

	gothic.Store = store

	if cfg.AuthProviders.Google.ClientID != "" && cfg.AuthProviders.Google.ClientSecret != "" {
		goth.UseProviders(
			google.New(
				cfg.AuthProviders.Google.ClientID,
				cfg.AuthProviders.Google.ClientSecret,
				cfg.AuthProviders.Google.CallbackURL,
			),
			apple.New(
				cfg.AuthProviders.Apple.ClientID,
				cfg.AuthProviders.Apple.ClientSecret,
				cfg.AuthProviders.Apple.CallbackURL,
				nil,
				apple.ScopeName,
				apple.ScopeEmail,
			),
		)
	}
}
