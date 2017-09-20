[![Stories in Ready](https://badge.waffle.io/ZURASTA/gingerbread.png?label=ready&title=Ready)](https://waffle.io/ZURASTA/gingerbread?utm_source=badge) [![CircleCI](https://circleci.com/gh/ZURASTA/gingerbread.svg?style=svg)](https://circleci.com/gh/ZURASTA/gingerbread)
# Gingerbread (Entity Management)

Manages the entities belonging to different identities. An entity is a unique ID that can be tagged to help identify it, and can be connected to other entities to form various relationships.

An entity ID is static and will remain unique for the lifetime of the database, regardless if the entity has been destroyed or not. This allows other services to safely associate other data with entity IDs.


### Usage

The service component (`Gingerbread.Service`) is an OTP application that should be started prior to making any requests to the service. This component should only be interacted with to configure/control the service explicitly.

An API (`Gingerbread.API`) is provided to allow for convenient interaction with the service from external applications.


### Ownership

An entity is associated with one identity. This identity is an external UUID that can be used to associate that entity belongs to an external resource. An identity can own any number of entities. Ownership of an entity can also be transferred from one identity to another. __Depending on the scenario, transfer may be an unsafe operation. In order to make it trusted, an external verification mechanism may need to be used to be sure the both identities (the current owner and the new owner) approve the transfer.__


### Relationship

Entities can be grouped into various relationships. This is exposed through parent-child connections, however this relationship isn't limited to a single parent-child. Rather this relationship can take the form of a one-to-many, many-to-one, many-to-many, tree, circular, or even self. The only restriction on a relationship is that the specific parent-child connection can only be made once (to avoid duplicates of the same relationship). Some examples of these relationships are as follows:

```svgbob
+---+    +---+   +---+    +---+   +---+<-+
| A |--->| B |   | A |<-->| B |   | A |  |
+---+    +---+   +---+    +---+   +---+<-+

+---+   +---+    +---+   +---+   +---+    +---+
| A |-->| B |--->| C |   | A |-->| B |--->| C |
+-+-+   +---+    +---+   +---+   +---+    +-+-+
  |                        ^                |
  |     +---+              |                |
  +---->| D |              +----------------+
        +---+
```

Relationships can be removed and re-added as necessary. They can be applied to any entity, regardless of owning identity. If a relationship is removed (either explicitly or an entity consisting of one part of that relationship is destroyed), any other connections that were apart of that relationship hierarchy will be unchanged. Any kind of specific behaviour around how relationships should behave under those circumstances must be handled externally.


### Use Cases?

Anywhere you want to retain relationships between various types of data, but allow for those relationships to be handled in a transactional manner. Regardless of where external data associated with those entities may be stored.


### Configuration

The service may be configured with the following options:

#### Setup Mode

The service has two setup modes: `:auto` and `:manual`. When the service is started in `:auto`, it will automatically handle creating and migrating the database. When the service is started in `:manual`, the state of the database is left up to the user to manually setup.

By default the service runs in `:auto` mode. To change this behaviour, pass in the `{ :setup_mode, mode }` when starting the application.

#### Database

The database options can be configured by providing the config for the key `Gingerbread.Service.Repo`. If no configuration is provided, a default configuration is used for `:test` and `:dev` builds. This default Ecto repo uses a locally hosted (accessible through localhost) PostgreSQL database, with the user/name as `postgres` and `postgres`.

For details on how to configure an [Ecto repo](https://hexdocs.pm/ecto/Ecto.Repo.html).

__Note:__ If a PostgreSQL database is used, the service will create a custom type. For details on how to interact with this type, see the [EctoEnum docs](http://hexdocs.pm/ecto_enum).
