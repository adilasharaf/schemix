package models

type User struct {
	Id string `gorm:"primaryKey;column:id" json:"id"`
	Email string `gorm:"column:email;not null" json:"email"`
	PasswordHash string `gorm:"column:password_hash;not null" json:"passwordHash"`
	DisplayName *string `gorm:"column:display_name" json:"displayName"`
	Posts []Post `gorm:"column:posts" json:"posts"`
	Profile *Profile `gorm:"column:profile" json:"profile"`
	Metadata *string `gorm:"column:metadata" json:"metadata"`
}

