package models

type PostTag struct {
	Id string `gorm:"primaryKey;column:id" json:"id"`
	PostId string `gorm:"column:post_id" json:"postId"`
	TagId string `gorm:"column:tag_id" json:"tagId"`
	Post *Post `gorm:"foreignKey:PostTagId" json:"post"`
	Tag *Tag `gorm:"foreignKey:PostTagId" json:"tag"`
}

