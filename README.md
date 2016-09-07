# User Store

It manages all ernest user storage through a public Nats API

## Build status

* master:  [![CircleCI Master](https://circleci.com/gh/ernestio/user-store/tree/master.svg?style=svg)](https://circleci.com/gh/ernestio/user-store/tree/master)
* develop: [![CircleCI Develop](https://circleci.com/gh/ernestio/user-store/tree/develop.svg?style=svg)](https://circleci.com/gh/ernestio/user-store/tree/develop)

## Installation

```
make deps
make install
```

## Running Tests

```
make deps
go test
```

## Endpoints

You have available the nats endpoints:

###user.get
It receives as input a valid user with only the id or name as required fields. It returns a valid user.

###user.del
It receives as input a valid user with only the id as required field. And it deletes the row if it can find it.

###user.set
It receives as input a valid user with id or not, and it will create or update the user with the given fields.

###user.find
It receives as input a valid user, and it will do a search on the database with the given fields.

## Contributing

Please read through our
[contributing guidelines](CONTRIBUTING.md).
Included are directions for opening issues, coding standards, and notes on
development.

Moreover, if your pull request contains patches or features, you must include
relevant unit tests.

## Versioning

For transparency into our release cycle and in striving to maintain backward
compatibility, this project is maintained under [the Semantic Versioning guidelines](http://semver.org/).

## Copyright and License

Code and documentation copyright since 2015 r3labs.io authors.

Code released under
[the Mozilla Public License Version 2.0](LICENSE).
