package models

type Order struct {
	Id string `gorm:"primaryKey;column:id" json:"id"`
	UserId string `gorm:"column:user_id" json:"userId"`
	Status string `gorm:"column:status;not null;default:pending" json:"status"`
	OrderNumber *int64 `gorm:"column:order_number" json:"orderNumber"`
	CreditCardToken *string `gorm:"column:credit_card_token" json:"creditCardToken"`
}

