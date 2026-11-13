package onboarding_test

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/stretchr/testify/require"
	"loop.com/server/internal/onboarding"
	"loop.com/server/internal/testutil"
	"loop.com/server/internal/user"
)

func TestCompleteOnboardingOnlyChangesAuthenticatedUser(t *testing.T) {
	db, _, jwt := testutil.AuthFixture(t)

	//Arrange: two accounts with incomplete onboarding.
	//Creating these directly is fine: account creation isn't under test here.
	accounts := []user.User{
		{Email: "a@example.com", Name: "User A"},
		{Email: "b@example.com", Name: "User B"},
	}
	require.NoError(t, db.Create(&accounts).Error)

	records := []onboarding.Onboarding{
		{UserID: accounts[0].ID},
		{
			UserID:      accounts[1].ID,
			CurrentStep: 2,
			Answers: map[string]json.RawMessage{
				"goal": json.RawMessage(`"reduce screen time"`),
			},
		},
	}
	require.NoError(t, db.Create(&records).Error)

	// Save B's full persisted state so even unintended timestamp changes are caught.
	var originalB onboarding.Onboarding
	require.NoError(t,
		db.Where("user_id = ?", accounts[1].ID).First(&originalB).Error,
	)

	service := onboarding.NewService(
		onboarding.NewRepository(db, slog.Default()),
	)

	handler := onboarding.NewHandler(service)

	router := chi.NewRouter()
	router.Route("/api/v1", func(r chi.Router) {
		onboarding.RegisterRoutes(r, handler, jwt)
	})

	tokenA, err := jwt.GenerateToken(accounts[0].ID)
	require.NoError(t, err)

	//Act: compelete onboarding using A's token.
	request := httptest.NewRequest(
		http.MethodPatch,
		"/api/v1/onboarding/complete",
		strings.NewReader(`{
			"answers": {"goal": "sleep better"},
			"currentStep": 3
		}`),
	)

	request.Header.Set("Authorization", "Bearer "+tokenA)
	request.Header.Set("Content-Type", "application/json")

	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	require.Equal(t, http.StatusNoContent, response.Code, response.Body.String())

	//Assert: A's changes were saved
	var savedA onboarding.Onboarding
	require.NoError(t,
		db.Where("user_id = ?", accounts[0].ID).First(&savedA).Error,
	)
	require.NotNil(t, savedA.CompletedAt)
	require.Equal(t, 3, savedA.CurrentStep)
	require.JSONEq(t, `"sleep better"`, string(savedA.Answers["goal"]))

	//B's onboarding remains untouched
	var savedB onboarding.Onboarding
	require.NoError(t,
		db.Where("user_id = ?", accounts[1].ID).First(&savedB).Error,
	)
	require.Equal(t, originalB, savedB, "user A's request must not change user B's onboarding")
}
