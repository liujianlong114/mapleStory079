//go:build ignore

package main

import (
	"fmt"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
)

func main() {
	database.Init()
	inv := repository.NewInventoryRepository()
	for _, id := range []uint{1, 2, 3} {
		eq, err := inv.FindEquipped(id)
		fmt.Printf("char %d err=%v equips=%+v\n", id, err, eq)
	}
}
