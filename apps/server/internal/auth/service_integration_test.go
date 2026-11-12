package auth_test

import (
	"context"
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/require"
	"loop.com/server/internal/onboarding"
	"loop.com/server/internal/testutil"
	"loop.com/server/internal/user"
)

func TestAuthenticateCreatesAccountAndOnboarding(t *testing.T) {
	db, service, jwt := testutil.AuthFixture(t)

	// Act: let Authenticate create the records itself.
	rawToken, err := service.Authenticate(
		context.Background(),
		user.AuthIdentity{
			Provider:       "google",
			ProviderUserID: "test-google-id",
		},
		user.User{
			Email: "test@example.com",
			Name:  "Test User",
		},
	)
	require.NoError(t, err)

	// Assert: the user was saved.
	var account user.User
	require.NoError(t,
		db.Where("email = ?", "test@example.com").First(&account).Error,
	)
	require.NotZero(t, account.ID)

	// The provider identity belongs to that user.
	var identity user.AuthIdentity
	require.NoError(t,
		db.Where("provider = ? AND provider_user_id = ?", "google", "test-google-id").
			First(&identity).Error,
	)
	require.NotZero(t, identity.ID)
	require.Equal(t, account.ID, identity.UserID)

	//Incomplete onbaording belongs to the same user
	var record onboarding.Onboarding
	require.NoError(t,
		db.Where("user_id = ?", account.ID).First(&record).Error,
	)
	require.Nil(t, record.CompletedAt)

	//The returned token identifies the user
	token, err := jwt.ValidateToken(rawToken)
	require.NoError(t, err)

	userID, err := jwt.ExtractUserID(token)
	require.NoError(t, err)
	require.Equal(t, account.ID, userID)

}

func TestAuthenticateRollsBackWhenOnboardingFails(t *testing.T) {
	db, service, _ := testutil.AuthFixture(t)

	//Forcing DB to reject omboarding inserts so it fails ....
	// :( no happy scenario

	require.NoError(t, db.Exec(`
		ALTER TABLE onboardings
		ADD CONSTRAINT test_reject_onboarding CHECK (false)
	`).Error)

	token, err := service.Authenticate(
		context.Background(),
		user.AuthIdentity{
			Provider:       "google",
			ProviderUserID: "rollback-test",
		},
		user.User{
			Email: "rollback@example.com",
			Name:  "John the useless fuck",
		},
	)

	require.ErrorContains(t, err, "test_reject_onboarding")
	require.Empty(t, token)

	for _, model := range []any{
		&user.User{},
		&user.AuthIdentity{},
		&onboarding.Onboarding{},
	} {
		var count int64
		require.NoError(t, db.Model(model).Count(&count).Error)
		require.Zero(t, count, "Unexpected saved rows for %T", model)
	}
}

func TestReturningUserKeepsAccountAndOnboarding(t *testing.T) {
	db, service, jwt := testutil.AuthFixture(t)
	ctx := context.Background()

	identity := user.AuthIdentity{
		Provider:       "google",
		ProviderUserID: "returning-user",
	}
	profile := user.User{
		Email: "return@example.com",
		Name:  "Test User",
	}

	//Arange: first sign in creates the account
	firstToken, err := service.Authenticate(ctx, identity, profile)
	require.NoError(t, err)

	var account user.User
	require.NoError(t,
		db.Where("email = ?", profile.Email).First(&account).Error,
	)

	//Give the esisting onboarding progress
	answers := map[string]json.RawMessage{
		"goal": json.RawMessage(`"sleep better"`),
	}
	require.NoError(t,
		db.Model(&onboarding.Onboarding{}).
			Where("user_id = ?", account.ID).
			Updates(onboarding.Onboarding{
				CurrentStep: 2,
				Answers:     answers,
			}).Error,
	)

	//Act: sign in again with the same provider identity
	secondToken, err := service.Authenticate(ctx, identity, profile)
	require.NoError(t, err)

	//Assert: both tokens identity the original account
	for _, rawToken := range []string{firstToken, secondToken} {
		token, err := jwt.ValidateToken(rawToken)
		require.NoError(t, err)

		userID, err := jwt.ExtractUserID(token)
		require.NoError(t, err)
		require.Equal(t, account.ID, userID)
	}

	// No duplicate user authIdentity or onboarding was created
	for _, model := range []any{
		&user.User{},
		&user.AuthIdentity{},
		&onboarding.Onboarding{},
	} {
		var count int64
		require.NoError(t, db.Model(model).Count(&count).Error)
		require.EqualValues(t, 1, count, "unexptected count for %T", model)
	}

	//Exisitng onboarding progress
	var saved onboarding.Onboarding
	require.NoError(t,
		db.Where("user_id = ?", account.ID).First(&saved).Error,
	)
	require.Equal(t, 2, saved.CurrentStep)
	require.Equal(t, answers, saved.Answers)

}
