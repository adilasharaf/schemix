package models

type Tag struct {
	Id string `gorm:"primaryKey;column:id" json:"id"`
	Name string `gorm:"column:name;not null;uniqueIndex" json:"name"`
	Slug string `gorm:"column:slug;not null;uniqueIndex" json:"slug"`
	Posts []PostTag `gorm:"foreignKey:TagId" json:"posts"`
}

