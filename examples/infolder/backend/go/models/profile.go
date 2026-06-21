package models

type Profile struct {
	Id string `gorm:"primaryKey;column:id" json:"id"`
	UserId string `gorm:"column:user_id" json:"userId"`
	Website *string `gorm:"column:website" json:"website"`
	PhoneNumber *string `gorm:"column:phone_number" json:"phoneNumber"`
	IsActive bool `gorm:"column:is_active;not null;default:true" json:"isActive"`
	Age *int64 `gorm:"column:age" json:"age"`
}

