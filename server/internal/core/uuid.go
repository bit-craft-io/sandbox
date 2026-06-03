package core

import (
	"github.com/google/uuid"
)

func GenUuid() string {
	return uuid.New().String()
}
