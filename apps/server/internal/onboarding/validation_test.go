package onboarding

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
)

func currentAnswers() map[string]json.RawMessage {
	return map[string]json.RawMessage{
		"morning-goal":           json.RawMessage(`{"single":{"_0":"build-routine"}}`),
		"workday-wake-time":      json.RawMessage(`{"time":{"_0":815900400}}`),
		"waking-style":           json.RawMessage(`{"single":{"_0":"first-alarm"}}`),
		"first-phone-use":        json.RawMessage(`{"single":{"_0":"within-10-min"}}`),
		"morning-time-available": json.RawMessage(`{"single":{"_0":"15-30-min"}}`),
	}
}

func TestValidateCurrentAndReleasedQuestionnaires(t *testing.T) {
	legacy := map[string]json.RawMessage{
		"focus":        json.RawMessage(`{"single":{"_0":"High"}}`),
		"distractions": json.RawMessage(`{"multiple":{"_0":["Games"]}}`),
		"wake-time":    json.RawMessage(`{"time":{"_0":815900400}}`),
		"goals":        json.RawMessage(`{"multiple":{"_0":["Exercise"]}}`),
		"experience":   json.RawMessage(`{"single":{"_0":"Beginner"}}`),
	}
	for name, answers := range map[string]map[string]json.RawMessage{"current": currentAnswers(), "released": legacy} {
		t.Run(name, func(t *testing.T) {
			if err := validateRequest(OnboardingRequest{Answers: answers, CurrentStep: summaryStep}, true); err != nil {
				t.Fatal(err)
			}
		})
	}
	if err := validateRequest(OnboardingRequest{}, false); err != nil {
		t.Fatalf("empty draft rejected: %v", err)
	}
	if err := validateRequest(OnboardingRequest{
		Answers: map[string]json.RawMessage{"morning-goal": currentAnswers()["morning-goal"]}, CurrentStep: 1,
	}, false); err != nil {
		t.Fatalf("partial draft rejected: %v", err)
	}
}

func TestRejectInvalidCompletionBeforeDatabaseAccess(t *testing.T) {
	tests := []struct {
		name   string
		mutate func(*OnboardingRequest)
	}{
		{"missing answers", func(r *OnboardingRequest) { r.Answers = nil }},
		{"incomplete answers", func(r *OnboardingRequest) { delete(r.Answers, "waking-style") }},
		{"early completion", func(r *OnboardingRequest) { r.CurrentStep = 4 }},
		{"negative step", func(r *OnboardingRequest) { r.CurrentStep = -1 }},
		{"out of range step", func(r *OnboardingRequest) { r.CurrentStep = 9 }},
		{"unknown question", func(r *OnboardingRequest) { r.Answers["unknown"] = json.RawMessage(`"value"`) }},
		{"mixed versions", func(r *OnboardingRequest) { r.Answers["focus"] = json.RawMessage(`{"single":{"_0":"High"}}`) }},
		{"invalid option", func(r *OnboardingRequest) { r.Answers["morning-goal"] = json.RawMessage(`{"single":{"_0":"invalid"}}`) }},
		{"wrong variant", func(r *OnboardingRequest) { r.Answers["morning-goal"] = json.RawMessage(`{"time":{"_0":123}}`) }},
		{"null answer", func(r *OnboardingRequest) { r.Answers["morning-goal"] = json.RawMessage(`null`) }},
		{"null value", func(r *OnboardingRequest) { r.Answers["workday-wake-time"] = json.RawMessage(`{"time":{"_0":null}}`) }},
		{"string time", func(r *OnboardingRequest) {
			r.Answers["workday-wake-time"] = json.RawMessage(`{"time":{"_0":"07:00"}}`)
		}},
		{"overflow time", func(r *OnboardingRequest) { r.Answers["workday-wake-time"] = json.RawMessage(`{"time":{"_0":1e309}}`) }},
		{"extra payload", func(r *OnboardingRequest) {
			r.Answers["morning-goal"] = json.RawMessage(`{"single":{"_0":"build-routine","extra":true}}`)
		}},
		{"extra variant", func(r *OnboardingRequest) {
			r.Answers["morning-goal"] = json.RawMessage(`{"single":{"_0":"build-routine"},"time":{"_0":0}}`)
		}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			request := OnboardingRequest{Answers: currentAnswers(), CurrentStep: summaryStep}
			tt.mutate(&request)
			// A nil repository proves invalid input is rejected before persistence.
			err := NewService(nil).CompleteOnboarding(context.Background(), 1, request)
			if !errors.Is(err, ErrInvalidRequest) {
				t.Fatalf("got %v, want ErrInvalidRequest", err)
			}
		})
	}
}

func TestDraftsRejectInvalidSubmittedValues(t *testing.T) {
	for _, raw := range []string{
		`{"multiple":{"_0":["Games","Games"]}}`,
		`{"multiple":{"_0":["Unknown"]}}`,
		`{"multiple":{"_0":null}}`,
		`{"multiple":{"_0":[null]}}`,
	} {
		request := OnboardingRequest{
			Answers: map[string]json.RawMessage{"distractions": json.RawMessage(raw)},
		}
		if err := NewService(nil).UpdateOnboarding(context.Background(), 1, request); !errors.Is(err, ErrInvalidRequest) {
			t.Fatalf("accepted invalid draft %s: %v", raw, err)
		}
	}
}

func TestAnswerEncodingMustContainExactlyOneValue(t *testing.T) {
	tests := []struct {
		name string
		raw  string
	}{
		{"missing value", `{"single":{}}`},
		{"wrong payload key", `{"single":{"choice":"build-routine"}}`},
		{"null payload", `{"single":null}`},
		{"null value with whitespace", `{"single":{"_0":  null  }}`},
		{"array instead of enum", `["build-routine"]`},
		{"malformed JSON", `{"single":`},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if validAnswer(json.RawMessage(tt.raw), currentQuestions["morning-goal"], false) {
				t.Fatalf("accepted malformed answer: %s", tt.raw)
			}
		})
	}
}
