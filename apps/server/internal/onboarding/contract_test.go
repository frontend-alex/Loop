package onboarding

import (
	"encoding/json"
	"os"
	"regexp"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
	"go.yaml.in/yaml/v3"
)

func TestHardcodedQuestionsMatchIOS(t *testing.T) {
	data, err := os.ReadFile("../../../ios/loop/Features/Onboarding/Onboarding.swift")

	require.NoError(t, err)
	source := string(data)

	wakeTime := regexp.MustCompile(`wakeTimeID = "([^"]+)"`).FindStringSubmatch(source)
	
	require.Len(t, wakeTime, 2)
	blocks := strings.Split(source, "\n        Question(")[1:]
	require.Len(t, blocks, len(currentQuestions), "Keep the fixed backend questionnaire in sync with iOS")

	for _, block := range blocks {
		idMatch := regexp.MustCompile(`id: ("([^"]+)"|wakeTimeID),`).FindStringSubmatch(block)
		require.Len(t, idMatch, 3)
		id := idMatch[2]
		if id == "" {
			id = wakeTime[1]
		}
		rule, exists := currentQuestions[id]
		require.True(t, exists, "Question %s is missing from backend validation", id)

		if strings.Contains(block, "body: .time(") {
			require.Equal(t, "time", rule.kind)
			continue
		}
		require.Equal(t, "single", rule.kind)
		require.ElementsMatch(t, rule.options, iosOptionIDs(block), "Choices differ for %s", id)
	}
}

func iosOptionIDs(block string) []string {
	// These are fixed QuestionOption declarations, not a runtime Swift parser.
	matches := regexp.MustCompile(`QuestionOption\(id: "([^"]+)"`).FindAllStringSubmatch(block, -1)
	options := make([]string, 0, len(matches))
	for _, match := range matches {
		options = append(options, match[1])
	}
	return options
}

func TestDocumentedOnboardingExamplesMatchValidation(t *testing.T) {
	data, err := os.ReadFile("../../api/openapi.yaml")
	if err != nil {
		t.Fatal(err)
	}
	var spec struct {
		Paths map[string]struct {
			Patch struct {
				RequestBody struct {
					Content map[string]struct {
						Examples map[string]struct {
							Value map[string]any
						}
					}
				} `yaml:"requestBody"`
			}
		}
	}
	if err := yaml.Unmarshal(data, &spec); err != nil {
		t.Fatal(err)
	}
	for _, operation := range []string{"update", "complete"} {
		path := "/api/v1/onboarding/" + operation
		examples := spec.Paths[path].Patch.RequestBody.Content["application/json"].Examples
		if len(examples) == 0 {
			t.Fatalf("no documented examples for %s", path)
		}
		for name, example := range examples {
			t.Run(operation+"/"+name, func(t *testing.T) {
				encoded, err := json.Marshal(example.Value)
				if err != nil {
					t.Fatal(err)
				}
				var request OnboardingRequest
				if err := json.Unmarshal(encoded, &request); err != nil {
					t.Fatal(err)
				}
				if err := validateRequest(request, operation == "complete"); err != nil {
					t.Fatalf("documented example is rejected: %v", err)
				}
			})
		}
	}
}
