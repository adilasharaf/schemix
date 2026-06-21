package models

import (
	"example/go/enums"
)

type Post struct {
	Id string `gorm:"primaryKey;column:id" json:"id"`
	Title *string `gorm:"column:title" json:"title"`
	Body *string `gorm:"column:body" json:"body"`
	Slug *string `gorm:"column:uuid" json:"slug"`
	Status enums.PostStatus `gorm:"column:status;not null;default:draft" json:"status"`
	UserId *string `gorm:"column:user_id" json:"userId"`
	CategoryId *string `gorm:"column:category_id" json:"categoryId"`
	Tags []Tag `gorm:"column:tags" json:"tags"`
}

