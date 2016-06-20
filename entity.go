/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package main

import (
	"encoding/json"
	"time"

	"github.com/nats-io/nats"
	"github.com/r3labs/natsdb"
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

// Find : based on the defined fields for the current entity
// will perform a search on the database
func (e *Entity) Find() []interface{} {
	entities := []Entity{}
	db.Find(&entities)

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
func (e *Entity) Update(body []byte) {
	e.MapInput(body)
	stored := Entity{}
	db.First(&stored, e.ID)
	stored.Username = e.Username

	db.Save(&stored)
	e = &stored
}

// Delete : Will delete from database the current Entity
func (e *Entity) Delete() {
	db.Unscoped().Delete(&e)
}

// Save : Persists current entity on database
func (e *Entity) Save() {
	db.Save(&e)
}
