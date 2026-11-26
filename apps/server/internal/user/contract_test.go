package user_test

import (
	"encoding/json"
	"os"
	"testing"

	"github.com/stretchr/testify/require"
	"go.yaml.in/yaml/v3"
	"loop.com/server/internal/user"
)

func TestCurrentAccountDocumentationMatchesResponse(t *testing.T) {
	data, err := os.ReadFile("../../api/openapi.yaml")
	
	require.NoError(t, err)

	var spec struct {
		Components struct {
			Schemas map[string]struct {
				Properties map[string]struct {
					Required   []string
					Properties map[string]any
				}
			}
		}
	}

	require.NoError(t, yaml.Unmarshal(data, &spec))

	documented := spec.Components.Schemas["UserResponse"].Properties["data"]
	encoded, err := json.Marshal(user.FindUserResponse{User: &user.User{ID: 1}, RequiredOnboarding: true})
	require.NoError(t, err)

	var response map[string]json.RawMessage
	require.NoError(t, json.Unmarshal(encoded, &response))
	require.Len(t, documented.Properties, len(response))

	for field := range response {
		require.Contains(t, documented.Properties, field)
		require.Contains(t, documented.Required, field)
	}
}
