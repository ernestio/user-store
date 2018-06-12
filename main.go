/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package main

import (
	"runtime"

	"github.com/jinzhu/gorm"
	"github.com/nats-io/go-nats"
	"github.com/r3labs/natsdb"

	_ "github.com/jinzhu/gorm/dialects/postgres"
)

var n *nats.Conn
var db *gorm.DB
var err error
var handler natsdb.Handler

func startHandler() {
	handler = natsdb.Handler{
		NotFoundErrorMessage:   natsdb.NotFound.Encoded(),
		UnexpectedErrorMessage: natsdb.Unexpected.Encoded(),
		DeletedMessage:         []byte(`"deleted"`),
		Nats:                   n,
		NewModel: func() natsdb.Model {
			return &Entity{}
		},
	}

	handlers := map[string]nats.MsgHandler{
		"user.get":  handler.Get,
		"user.del":  handler.Del,
		"user.set":  handler.Set,
		"user.find": handler.Find,
	}

	for k, v := range handlers {
		if _, err = n.Subscribe(k, v); err != nil {
			panic(err)
		}
	}

}

func main() {
	setupNats()
	setupPg()
	startHandler()

	runtime.Goexit()
}
