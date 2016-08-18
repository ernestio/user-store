/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package main

import (
	"encoding/json"
	"fmt"
	"testing"
	"time"

	"github.com/nats-io/nats"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGetHandler(t *testing.T) {
	setupNats()
	n.Subscribe("config.get.postgres", func(msg *nats.Msg) {
		n.Publish(msg.Reply, []byte(`{"names":["users","datacenters","datacenters","services"],"password":"","url":"postgres://postgres@127.0.0.1","user":""}`))
	})
	setupPg()
	startHandler()

	Convey("Scenario: getting a username", t, func() {
		setupTestSuite()
		Convey("Given the username does not exist on the database", func() {
			msg, err := n.Request("user.get", []byte(`{"id":"32"}`), time.Second)
			So(string(msg.Data), ShouldEqual, string(handler.NotFoundErrorMessage))
			So(err, ShouldEqual, nil)
		})

		Convey("Given the user exists on the database", func() {
			createEntities(1)
			e := Entity{}
			db.First(&e)
			id := fmt.Sprint(e.ID)

			msg, err := n.Request("user.get", []byte(`{"id":`+id+`}`), time.Second)
			output := Entity{}
			json.Unmarshal(msg.Data, &output)
			So(output.ID, ShouldEqual, e.ID)
			So(output.GroupID, ShouldEqual, e.GroupID)
			So(output.Username, ShouldEqual, e.Username)
			So(output.Password, ShouldEqual, e.Password)
			So(err, ShouldEqual, nil)
		})

		Convey("Given the user exists on the database and searching by name", func() {
			createEntities(1)
			e := Entity{}
			db.First(&e)

			msg, err := n.Request("user.get", []byte(`{"username":"`+e.Username+`"}`), time.Second)
			output := Entity{}
			json.Unmarshal(msg.Data, &output)
			So(output.ID, ShouldEqual, e.ID)
			So(output.GroupID, ShouldEqual, e.GroupID)
			So(output.Username, ShouldEqual, e.Username)
			So(output.Password, ShouldEqual, e.Password)
			So(err, ShouldEqual, nil)
		})
	})

	Convey("Scenario: deleting a user", t, func() {
		setupTestSuite()
		Convey("Given the user does not exist on the database", func() {
			msg, err := n.Request("user.del", []byte(`{"id":32}`), time.Second)
			So(string(msg.Data), ShouldEqual, string(handler.NotFoundErrorMessage))
			So(err, ShouldEqual, nil)
		})

		Convey("Given the user exists on the database", func() {
			createEntities(1)
			last := Entity{}
			db.First(&last)
			id := fmt.Sprint(last.ID)

			msg, err := n.Request("user.del", []byte(`{"id":`+id+`}`), time.Second)
			So(string(msg.Data), ShouldEqual, string(handler.DeletedMessage))
			So(err, ShouldEqual, nil)

			deleted := Entity{}
			db.First(&deleted, id)
			So(deleted.ID, ShouldEqual, 0)
		})
	})

	Convey("Scenario: user set", t, func() {
		setupTestSuite()
		Convey("Given we don't provide any id as part of the body", func() {
			Convey("Then it should return the created record and it should be stored on DB", func() {
				msg, err := n.Request("user.set", []byte(`{"username":"fred"}`), time.Second)
				output := Entity{}
				output.LoadFromInput(msg.Data)
				So(output.ID, ShouldNotEqual, nil)
				So(output.Username, ShouldEqual, "fred")
				So(err, ShouldEqual, nil)

				stored := Entity{}
				db.First(&stored, output.ID)
				So(stored.Username, ShouldEqual, "fred")
			})
		})

		Convey("Given we provide an unexisting id", func() {
			Convey("Then we should receive a not found message", func() {
				msg, err := n.Request("user.set", []byte(`{"id": 1000, "username":"fred"}`), time.Second)
				So(string(msg.Data), ShouldEqual, string(handler.NotFoundErrorMessage))
				So(err, ShouldEqual, nil)
			})
		})

		Convey("Given we provide an existing id", func() {
			createEntities(1)
			e := Entity{}
			db.First(&e)
			id := fmt.Sprint(e.ID)
			Convey("Then we should receive an updated entity", func() {
				msg, err := n.Request("user.set", []byte(`{"id": `+id+`, "username":"fred", "password":"supu"}`), time.Second)
				output := Entity{}
				output.LoadFromInput(msg.Data)
				So(output.ID, ShouldNotEqual, nil)
				So(output.Username, ShouldEqual, "fred")
				pwd := output.Password
				So(err, ShouldEqual, nil)

				stored := Entity{}
				db.First(&stored, output.ID)
				So(stored.Username, ShouldEqual, "fred")
				So(stored.Password, ShouldEqual, pwd)

				n.Request("user.set", []byte(`{"id": `+id+`, "password":""}`), time.Second)
				db.First(&stored, output.ID)
				So(stored.Password, ShouldEqual, pwd)
			})
		})
	})

	Convey("Scenario: find users", t, func() {
		setupTestSuite()
		Convey("Given users exist on the database", func() {
			createEntities(20)
			Convey("Then I should get a list of users", func() {
				msg, _ := n.Request("user.find", []byte(`{}`), time.Second)
				list := []Entity{}
				json.Unmarshal(msg.Data, &list)
				So(len(list), ShouldEqual, 20)
			})
		})
	})

}
