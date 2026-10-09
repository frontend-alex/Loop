package user

import "time"

// The account inside the application
type User struct {
	ID        uint `gorm:"primaryKey"`
	Email     string
	Name      string
	AvatarURL string
	CreatedAt time.Time
	UpdatedAt time.Time
}

// The Provider identity associated with the user, Google, Apple, etc.
type AuthIdentity struct {
	ID uint `gorm:"primaryKey"`

	UserID uint `gorm:"not null;index"`
	User   User `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;"`

	Provider       string `gorm:"not null;uniqueIndex:idx_auth_provider_user"`
	ProviderUserID string `gorm:"not null;uniqueIndex:idx_auth_provider_user"`

	CreatedAt time.Time
	UpdatedAt time.Time
}
