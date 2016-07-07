/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package main

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"time"

	"golang.org/x/crypto/scrypt"

	"github.com/nats-io/nats"
	"github.com/r3labs/natsdb"
)

const (
	// SaltSize is the size of the salt in bits
	SaltSize = 32
	// HashSize is the size of the hash in bits
	HashSize = 64
)

// Entity : the database mapped entity
type Entity struct {
	ID        uint   `json:"id" gorm:"primary_key"`
	GroupID   uint   `json:"group_id" gorm:"unique_index:idx_per_group"`
	Username  string `json:"username" gorm:"unique_index:idx_per_group"`
	Password  string `json:"password"`
	Email     string `json:"email"`
	Salt      string `json:"salt"`
	Admin     bool   `json:"admin"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time `json:"-" sql:"index"`
}

// TableName : set Entity's table name to be groups
func (Entity) TableName() string {
	return "users"
}

// Find : based on the defined fields for the current entity
// will perform a search on the database
func (e *Entity) Find() []interface{} {
	entities := []Entity{}

	if e.Username != "" && e.GroupID != 0 {
		db.Where("username = ?", e.Username).Where("group_id = ?", e.GroupID).Find(&entities)
	} else {
		if e.Username != "" {
			db.Where("username = ?", e.Username).Find(&entities)
		} else if e.GroupID != 0 {
			db.Where("group_id = ?", e.GroupID).Find(&entities)
		}
	}

	if e.GroupID != 0 {
		db.Where("group_id = ?", e.GroupID).Find(&entities)
	} else {
		db.Find(&entities)
	}

	list := make([]interface{}, len(entities))
	for i, s := range entities {
		list[i] = s
	}

	return list
}

// MapInput : maps the input []byte on the current entity
func (e *Entity) MapInput(body []byte) {
	json.Unmarshal(body, &e)
}

// HasID : determines if the current entity has an id or not
func (e *Entity) HasID() bool {
	if e.ID == 0 {
		return false
	}
	return true
}

// LoadFromInput : Will load from a []byte input the database stored entity
func (e *Entity) LoadFromInput(msg []byte) bool {
	e.MapInput(msg)
	var stored Entity
	if e.ID != 0 {
		db.First(&stored, e.ID)
	} else if e.Username != "" {
		db.Where("username = ?", e.Username).First(&stored)
	}
	if &stored == nil {
		return false
	}
	if ok := stored.HasID(); !ok {
		return false
	}

	e.ID = stored.ID
	e.GroupID = stored.GroupID
	e.Username = stored.Username
	e.Password = stored.Password
	e.Salt = stored.Salt
	e.Admin = stored.Admin

	return true
}

// LoadFromInputOrFail : Will try to load from the input an existing entity,
// or will call the handler to Fail the nats message
func (e *Entity) LoadFromInputOrFail(msg *nats.Msg, h *natsdb.Handler) bool {
	stored := &Entity{}
	ok := stored.LoadFromInput(msg.Data)
	if !ok {
		h.Fail(msg)
	}
	*e = *stored

	return ok
}

// Update : It will update the current entity with the input []byte
func (e *Entity) Update(body []byte) error {
	e.MapInput(body)
	stored := Entity{}
	db.First(&stored, e.ID)
	stored.Username = e.Username
	stored.Password = e.Password
	stored.Save()
	return nil
}

// Delete : Will delete from database the current Entity
func (e *Entity) Delete() error {
	db.Unscoped().Delete(&e)

	return nil
}

// Save : Persists current entity on database
func (e *Entity) Save() error {
	salt := make([]byte, SaltSize)
	_, err := io.ReadFull(rand.Reader, salt)
	if err != nil {
		return fmt.Errorf(`{"error": "%s"}`, err.Error())
	}

	hash, err := scrypt.Key([]byte(e.Password), salt, 16384, 8, 1, HashSize)
	if err != nil {
		return fmt.Errorf(`{"error": "%s"}`, err.Error())
	}

	// Create a base64 string of the binary salt and hash for storage
	e.Salt = base64.StdEncoding.EncodeToString(salt)
	e.Password = base64.StdEncoding.EncodeToString(hash)

	db.Save(&e)

	return nil
}
