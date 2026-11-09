package onboarding

import (
	"encoding/json"
	"time"

	"loop.com/server/internal/user"
)

type Onboarding struct {
	ID uint `gorm:"primaryKey"`

	UserID uint      `gorm:"not null;uniqueIndex"`
	User   user.User `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;"`

	Answers map[string]json.RawMessage `gorm:"serializer:json;type:jsonb" json:"answers"`

	CompletedAt *time.Time
	CurrentStep int

	CreatedAt time.Time
	UpdatedAt time.Time
}
