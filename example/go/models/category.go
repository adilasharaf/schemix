package models

import (
	"example/go/enums"
)

type Category struct {
	Id string `gorm:"primaryKey;column:id" json:"id"`
	Name string `gorm:"column:name;not null" json:"name"`
	Type enums.CategoryType `gorm:"column:type;not null;default:standard" json:"type"`
	Posts []Post `gorm:"column:posts" json:"posts"`
}

