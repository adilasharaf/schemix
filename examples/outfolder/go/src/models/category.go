package models

type CategoryType string

const (
	CategoryTypeStandard CategoryType = "standard"
	CategoryTypePremium CategoryType = "premium"
	CategoryTypeInternal CategoryType = "internal"
)

type Category struct {
	Id string `gorm:"primaryKey;column:id" json:"id"`
	Name string `gorm:"column:name;not null;uniqueIndex" json:"name"`
	Type CategoryType `gorm:"column:type;not null;default:standard" json:"type"`
	Posts []Post `gorm:"foreignKey:CategoryId" json:"posts"`
}

