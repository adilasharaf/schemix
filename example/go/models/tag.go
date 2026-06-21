package models

type Tag struct {
	Id string `gorm:"primaryKey;column:id" json:"id"`
	Name string `gorm:"column:name;not null;unique" json:"name"`
	Slug string `gorm:"column:slug;not null;unique" json:"slug"`
}

