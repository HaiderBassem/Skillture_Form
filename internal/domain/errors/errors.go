package errors

import "errors"

var (
	// Common
	ErrNotFound     = errors.New("resource not found")
	ErrInvalidInput = errors.New("invalid input")

	// Form
	ErrFormClosed       = errors.New("form is closed")
	ErrFormNotPublished = errors.New("form is not published")

	// Response
	ErrDuplicateResponse    = errors.New("duplicate response")
	ErrMissingRequiredField = errors.New("missing required field")
)
