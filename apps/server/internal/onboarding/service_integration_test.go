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

	// Invalid completion must be a client error and must not change persisted state.
	var originalA onboarding.Onboarding
	require.NoError(t, db.Where("user_id = ?", accounts[0].ID).First(&originalA).Error)
	for _, body := range []string{
		`{"answers":{},"currentStep":8}`,
		`{"answers":{"morning-goal":{"single":{"_0":"invalid"}}},"currentStep":8}`,
		`{"answers":{"unexpected":"value"},"currentStep":8}`,
	} {
		invalid := httptest.NewRequest(http.MethodPatch, "/api/v1/onboarding/complete", strings.NewReader(body))
		invalid.Header.Set("Authorization", "Bearer "+tokenA)
		invalid.Header.Set("Content-Type", "application/json")
		rejected := httptest.NewRecorder()
		router.ServeHTTP(rejected, invalid)
		require.Equal(t, http.StatusBadRequest, rejected.Code, rejected.Body.String())
		require.Contains(t, rejected.Body.String(), "invalid_onboarding_data")
		var unchanged onboarding.Onboarding
		require.NoError(t, db.Where("user_id = ?", accounts[0].ID).First(&unchanged).Error)
		require.Equal(t, originalA, unchanged)
	}

	const validCompletion = `{
        "answers": {
            "morning-goal": {"single":{"_0":"build-routine"}},
            "workday-wake-time": {"time":{"_0":815900400}},
            "waking-style": {"single":{"_0":"first-alarm"}},
            "first-phone-use": {"single":{"_0":"within-10-min"}},
            "morning-time-available": {"single":{"_0":"15-30-min"}}
        },
        "currentStep": 8
    }`

	// Act: complete onboarding using A's token and the current client contract.
	request := httptest.NewRequest(
		http.MethodPatch,
		"/api/v1/onboarding/complete",
		strings.NewReader(validCompletion),
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
	require.Equal(t, 8, savedA.CurrentStep)
	require.JSONEq(t, `{"single":{"_0":"build-routine"}}`, string(savedA.Answers["morning-goal"]))

	// Repeated valid completion preserves the first final snapshot and timestamps.
	retry := httptest.NewRequest(http.MethodPatch, "/api/v1/onboarding/complete",
		strings.NewReader(strings.ReplaceAll(validCompletion, "build-routine", "feel-awake")))
	retry.Header.Set("Authorization", "Bearer "+tokenA)
	retry.Header.Set("Content-Type", "application/json")
	retried := httptest.NewRecorder()
	router.ServeHTTP(retried, retry)
	require.Equal(t, http.StatusNoContent, retried.Code, retried.Body.String())
	var afterRetry onboarding.Onboarding
	require.NoError(t, db.Where("user_id = ?", accounts[0].ID).First(&afterRetry).Error)
	require.Equal(t, savedA, afterRetry)

	//B's onboarding remains untouched
	var savedB onboarding.Onboarding
	require.NoError(t,
		db.Where("user_id = ?", accounts[1].ID).First(&savedB).Error,
	)
	require.Equal(t, originalB, savedB, "user A's request must not change user B's onboarding")
}
