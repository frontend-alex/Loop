package httpx

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
)

type MalformedRequest struct {
	Status  int
	Message string
}

func (mr *MalformedRequest) Error() string {
	return mr.Message
}

func DecodeJSONBody(w http.ResponseWriter, r *http.Request, dst any) error {
	ct := r.Header.Get("Content-Type")

	if ct != "" {
		mediaType := strings.ToLower(strings.TrimSpace(strings.Split(ct, ";")[0]))
		if mediaType != "application/json" {
			Message := "Content-Type header is not application/json"
			return &MalformedRequest{Status: http.StatusUnsupportedMediaType, Message: Message}
		}
	}

	r.Body = http.MaxBytesReader(w, r.Body, 1048576)

	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()

	err := dec.Decode(&dst)

	if err != nil {
		var syntaxError *json.SyntaxError
		var unmarshalTypeError *json.UnmarshalTypeError
		var maxBytesError *http.MaxBytesError

		switch {
		case errors.As(err, &syntaxError):
			Message := fmt.Sprintf("Request body contains badly-formed JSON (at position %d)", syntaxError.Offset)
			return &MalformedRequest{Status: http.StatusBadRequest, Message: Message}

		case errors.Is(err, io.ErrUnexpectedEOF):
			Message := "Request body contains badly-formed JSON"
			return &MalformedRequest{Status: http.StatusBadRequest, Message: Message}

		case errors.As(err, &unmarshalTypeError):
			Message := fmt.Sprintf("Request body contains an invalid value for the %q field (at position %d)", unmarshalTypeError.Field, unmarshalTypeError.Offset)
			return &MalformedRequest{Status: http.StatusBadRequest, Message: Message}

		case strings.HasPrefix(err.Error(), "json: unknown field "):
			fieldName := strings.TrimPrefix(err.Error(), "json: unknown field ")
			Message := fmt.Sprintf("Request body contains unknown field %s", fieldName)
			return &MalformedRequest{Status: http.StatusBadRequest, Message: Message}

		case errors.Is(err, io.EOF):
			Message := "Request body must not be empty"
			return &MalformedRequest{Status: http.StatusBadRequest, Message: Message}

		case errors.As(err, &maxBytesError):
			Message := fmt.Sprintf("Request body must not be larger than %d bytes", maxBytesError.Limit)
			return &MalformedRequest{Status: http.StatusRequestEntityTooLarge, Message: Message}

		default:
			return err
		}
	}

	err = dec.Decode(&struct{}{})

	if !errors.Is(err, io.EOF) {
		Message := "Request body must only contain a single JSON object"
		return &MalformedRequest{Status: http.StatusBadRequest, Message: Message}
	}

	return nil
}
