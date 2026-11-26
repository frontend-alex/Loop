package onboarding

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"slices"
)

var ErrInvalidRequest = errors.New("invalid onboarding data")

const summaryStep = 8 // Five questions, then alarm, apps, tasks, and summary.

type questionRule struct {
	kind    string
	options []string
}

// Keep the released questionnaire readable while the develop client rolls out.
// Both use Swift's synthesized enum encoding: {"single":{"_0":"option"}}.
var currentQuestions = map[string]questionRule{
	"morning-goal":           {"single", []string{"get-up-on-time", "stop-scrolling", "build-routine", "feel-awake"}},
	"workday-wake-time":      {"time", nil},
	"waking-style":           {"single", []string{"first-alarm", "snooze-1-2", "snooze-3-plus", "several-alarms"}},
	"first-phone-use":        {"single", []string{"in-bed", "within-10-min", "within-30-min", "later"}},
	"morning-time-available": {"single", []string{"under-15-min", "15-30-min", "30-60-min", "over-60-min"}},
}

var legacyQuestions = map[string]questionRule{
	"focus":        {"single", []string{"Low", "Medium", "High"}},
	"distractions": {"multiple", []string{"Social media", "Games", "Messages"}},
	"wake-time":    {"time", nil},
	"goals":        {"multiple", []string{"Focus", "Exercise", "Reading"}},
	"experience":   {"single", []string{"Beginner", "Intermediate", "Advanced"}},
}

func validateRequest(data OnboardingRequest, complete bool) error {
	if data.CurrentStep < 0 || data.CurrentStep > summaryStep {
		return fmt.Errorf("%w: currentStep must be between 0 and %d", ErrInvalidRequest, summaryStep)
	}
	if complete && data.CurrentStep != summaryStep {
		return fmt.Errorf("%w: completion requires the summary step", ErrInvalidRequest)
	}

	questions := questionsFor(data.Answers)
	if complete && len(data.Answers) != len(questions) {
		return fmt.Errorf("%w: all five questionnaire answers are required", ErrInvalidRequest)
	}
	return validateAnswers(data.Answers, questions, complete)
}

// Only needed while the released client still sends the old question IDs.
func questionsFor(answers map[string]json.RawMessage) map[string]questionRule {
	for id := range answers {
		if _, legacy := legacyQuestions[id]; legacy {
			return legacyQuestions
		}
	}
	return currentQuestions
}

func validateAnswers(answers map[string]json.RawMessage, questions map[string]questionRule, complete bool) error {
	for id, answer := range answers {
		rule, ok := questions[id]
		if !ok {
			return fmt.Errorf("%w: unknown or mixed questionnaire field %q", ErrInvalidRequest, id)
		}
		if !validAnswer(answer, rule, complete) {
			return fmt.Errorf("%w: invalid answer for %q", ErrInvalidRequest, id)
		}
	}
	return nil
}

func validAnswer(raw json.RawMessage, rule questionRule, complete bool) bool {
	value := answerValue(raw, rule.kind)
	if value == nil {
		return false
	}
	switch rule.kind {
	case "single":
		var choice string
		return json.Unmarshal(value, &choice) == nil && slices.Contains(rule.options, choice)
	case "time":
		var seconds float64
		// JSON decoding already rejects NaN, infinity, overflow and non-numbers.
		return json.Unmarshal(value, &seconds) == nil
	case "multiple":
		return validMultipleAnswer(value, rule.options, complete)
	}
	return false
}

// Swift encodes an answer as {"single":{"_0":"choice"}} (or "time"/"multiple").
// Reject extra fields and nulls instead of silently ignoring malformed input.
func answerValue(raw json.RawMessage, kind string) json.RawMessage {
	var variant map[string]json.RawMessage
	if json.Unmarshal(raw, &variant) != nil || len(variant) != 1 {
		return nil
	}
	var payload map[string]json.RawMessage
	if json.Unmarshal(variant[kind], &payload) != nil || len(payload) != 1 {
		return nil
	}
	value := payload["_0"]
	if bytes.Equal(bytes.TrimSpace(value), []byte("null")) {
		return nil
	}
	return value
}

// Only the released questionnaire has multi-select answers.
func validMultipleAnswer(raw json.RawMessage, allowed []string, complete bool) bool {
	var choices []string
	if json.Unmarshal(raw, &choices) != nil || (complete && len(choices) == 0) {
		return false
	}
	seen := make(map[string]bool)
	for _, choice := range choices {
		if seen[choice] || !slices.Contains(allowed, choice) {
			return false
		}
		seen[choice] = true
	}
	return true
}
