package auth_test

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"loop.com/server/internal/config"
	"loop.com/server/internal/platform/auth"
)

// The expired token is created with an expiry in the past—no waiting or sleep.
// Rejected requests must not execute protected code.
// /private is a dummy handler, not a real Loop endpoint. This tests middleware, not the complete application.

type TestResponse struct {
	Name   string `json:"name"`
	Header string `json:"header"`
	Status int    `json:"status"`
}

func TestAuthenticationMiddleware(t *testing.T) {

	service := auth.NewJWTService(config.JWTConfig{
		Secret:     "real-test-only-secret",
		Expiration: time.Hour,
	})

	// Helper: generate real tokens with different settings
	makeToken := func(secret string, lifetime time.Duration) string {
		t.Helper()

		issuer := auth.NewJWTService(config.JWTConfig{
			Secret:     secret,
			Expiration: lifetime,
		})

		token, err := issuer.GenerateToken(67)
		if err != nil {
			t.Fatal(err)
		}

		return token
	}

	valid := makeToken("real-test-only-secret", time.Hour)
	expired := makeToken("real-test-only-secret", -time.Hour)
	forged := makeToken("fake-test-only-secret", time.Hour)

	tests := []TestResponse{
		{"missing token", "", http.StatusUnauthorized},
		{"malformed token", "Bearer invalid", http.StatusUnauthorized},
		{"wrong signing key", "Bearer " + forged, http.StatusUnauthorized},
		{"expired token", "Bearer " + expired, http.StatusUnauthorized},
		{"valid token", "Bearer " + valid, http.StatusNoContent},
	}

	for _, tt := range tests {
		t.Run(tt.Name, func(t *testing.T) {
			// Arrange: record whether protected code runs.
			called := false

			protected := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				called = true

				userID, ok := auth.UserIDFromContext(r.Context())

				if !ok || userID != 67 {
					t.Error("Expected authenticated user 67")
				}

				w.WriteHeader(http.StatusNoContent)
			})

			request := httptest.NewRequest(http.MethodGet, "/auth-required", nil)
			request.Header.Set("Authorization", tt.Header)
			response := httptest.NewRecorder()

			//Act
			service.Middleware(protected).ServeHTTP(response, request)

			if response.Code != tt.Status {
				t.Fatalf("Expected statys %d, got %d", tt.Status, response.Code)
			}

			wantCalled := tt.Status == http.StatusNoContent
			if called != wantCalled {
				t.Fatalf("Protected handler called: got %v, want %v", called, wantCalled)
			}
		})
	}

}
