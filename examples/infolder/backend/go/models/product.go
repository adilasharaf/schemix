package models

type Product struct {
	Id string `gorm:"primaryKey;column:id" json:"id"`
	Name string `gorm:"column:name;not null" json:"name"`
	Price float64 `gorm:"column:price;not null" json:"price"`
	Stock int64 `gorm:"column:stock;not null;default:0" json:"stock"`
	Type string `gorm:"column:type;not null;default:physical" json:"type"`
}

