package auth

import (
	"context"
	"net/http"
	"strings"

	"loop.com/server/internal/httpx"
)

type UserIDKey struct{}

func UserIDFromContext(ctx context.Context) (uint, bool) {
	userID, ok := ctx.Value(UserIDKey{}).(uint)

	return userID, ok
}

func (s *JWTService) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		header := strings.Fields(r.Header.Get("Authorization"))

		if len(header) != 2 || !strings.EqualFold(header[0], "Bearer") {
			httpx.Error(w, http.StatusUnauthorized,
				"unauthorized", "Bearer token required")
			return
		}

		token, err := s.ValidateToken(header[1])
		if err != nil {
			httpx.Error(w, http.StatusUnauthorized,
				"unauthorized", "Invalid or expired token")
			return
		}

		userID, err := s.ExtractUserID(token)
		if err != nil || userID == 0 {
			httpx.Error(w, http.StatusUnauthorized,
				"unauthorized", "Invalid user ID")
			return
		}

		ctx := context.WithValue(r.Context(), UserIDKey{}, userID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}
