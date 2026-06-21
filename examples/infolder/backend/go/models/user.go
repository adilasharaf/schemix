package models

import (
	"gorm.io/datatypes"
)

type User struct {
	Id string `gorm:"primaryKey;column:id" json:"id"`
	Email string `gorm:"column:email;not null;uniqueIndex" json:"email"`
	PasswordHash string `gorm:"column:password_hash;not null" json:"passwordHash"`
	DisplayName *string `gorm:"column:display_name" json:"displayName"`
	Posts []Post `gorm:"foreignKey:UserId" json:"posts"`
	Profile *Profile `gorm:"foreignKey:UserId" json:"profile"`
	Metadata datatypes.JSON `gorm:"column:metadata" json:"metadata"`
}

