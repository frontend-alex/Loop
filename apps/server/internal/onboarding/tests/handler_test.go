package tests

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"loop.com/server/internal/onboarding"
)

func TestCompleteOnboardingWithoutAuthentication(t *testing.T) {
	// Arrange: no service is needed because unauthenticated requests return early.
	handler := onboarding.NewHandler(nil)
	request := httptest.NewRequest(http.MethodPatch, "/api/v1/onboarding/complete", nil)
	response := httptest.NewRecorder()

	// Act: call the real handler without an authenticated user in the context.
	handler.CompleteOnboarding(response, request)

	// Assert: the handler must reject the request with 401 Unauthorized.
	if response.Code != http.StatusUnauthorized {
		t.Fatalf("expected status 401, got %d", response.Code)
	}
}
