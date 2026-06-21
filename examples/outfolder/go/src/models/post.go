package models

type PostStatus string

const (
	PostStatusDraft PostStatus = "draft"
	PostStatusPublished PostStatus = "published"
	PostStatusArchived PostStatus = "archived"
)

type Post struct {
	Id string `gorm:"primaryKey;column:id" json:"id"`
	Title *string `gorm:"column:title" json:"title"`
	Body *string `gorm:"column:body" json:"body"`
	Slug *string `gorm:"column:slug" json:"slug"`
	Status PostStatus `gorm:"column:status;not null;default:draft" json:"status"`
	UserId *string `gorm:"column:user_id" json:"userId"`
	CategoryId *string `gorm:"column:category_id" json:"categoryId"`
	Tags []PostTag `gorm:"foreignKey:PostId" json:"tags"`
}

