package enums

type PostStatus string

const (
	PostStatusDraft PostStatus = "draft"
	PostStatusPublished PostStatus = "published"
	PostStatusArchived PostStatus = "archived"
)
