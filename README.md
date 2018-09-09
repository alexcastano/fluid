## Fluid

Fluid is a library to create meaningful IDs.

It may be useful in context where data space it is important, ie: sending package over the network.

## Installation

The package can be installed by adding `fluid` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fluid, "~> 0.0.1-dev"}
  ]
end
```

[Documentation](https://hexdocs.pm/fluid).

## Example

Let's see how we can implement the [Instagram ID](https://instagram-engineering.com/sharding-ids-at-instagram-1cf5a71e5a5c) using fluid.
This format allows us to create ID independently, each Elixir node (or PostgreSQL instance) can create them
without collisions and without communication.
It is sortable by time, independently where the ID was generated.
Last, but not least, it is small. It is only 64 bits. This is perfect to index in SQL or to cache in Redis or in a ETS table.

### Definition

```elixir
defmodule MyApp.ID do
  use Fluid,
    fields: [
      inserted_at: %Fluid.Field.NaiveDateTime{
        size: 41,
        epoch: ~N[2018-01-01 00:00:00],
        time_unit: :millisecond
      },
      node_id: %Fluid.Field.Integer{size: 13},
      local_id: %Fluid.Field.Integer{size: 10, unsigned: false}
    ],
    formats: [
      hex: %Fluid.Format.Hexadecimal{
        separator: ?-,
        groups: 4
      }
    ],
    ecto: [type: :integer, format: %Fluid.Formatter.Hexadecimal{}]
end
```

### Fields

We defined 3 fields:
* `inserted_at`: when the id was generated
* `node_id`: in which node was generated
* `local_id`: just a consecutive counter to avoid collision in the same millisecond

The type of `inserted_at` is `Fluid.Field.NaiveDateTime` which means it returns `NaiveDateTime` values.
Its `time_unit` is `:millisecond`. We could use `:second` but the precision would not be enough for
many applications, or `:microsecond`, but the maximum date would be much closer.

We don't use Unix epoch (1970-01-01 00:00) to save the date,
we changed to a more modern date to optimize space.
The size of `inserted_at` is `41` bits.
This allows to create IDs until the following date:

```elixir
iex(3)> MyApp.ID.__fluid__(:max, :inserted_at)
~N[2087-09-07 15:47:35]
iex(4)> MyApp.ID.__fluid__(:min, :inserted_at)
~N[2018-01-01 00:00:00]
```

80 years! Not bad at all!
The ID saves the number of millisecond since the epoch date.
Let's see an example:

```elixir
iex(7)> MyApp.ID.__fluid__(:load, :inserted_at, <<1000::41>>)
{:ok, ~N[2018-01-01 00:00:01]}
```

When we saved a `1000`, it is a second from the epoch date.
The inverse operation it is also available:

```elixir
iex(9)> MyApp.ID.__fluid__(:dump, :inserted_at, ~N[2018-01-01 00:00:01])
{:ok, <<0, 0, 0, 1, 244, 0::size(1)>>}
iex(10)> MyApp.ID.__fluid__(:dump, :inserted_at, ~N[2000-01-01 00:00:01])
:error
```

If we try to encode (or decode) invalid values it returns `:error`

We could access to the size of the field with the following call:

```elixir
iex(11)> MyApp.ID.__fluid__(:bit_size, :inserted_at)
41
```

For the `node_id` we have similar behaviour:

```elixir
iex(13)> MyApp.ID.__fluid__(:bit_size, :node_id)
13
iex(14)> MyApp.ID.__fluid__(:min, :node_id)
0
iex(15)> MyApp.ID.__fluid__(:max, :node_id)
8191
```

So we can have 8191 different nodes generating ids.

And, of course, we can `load` and `dump` with a bitstring:

```elixir
iex(17)> MyApp.ID.__fluid__(:load, :node_id, <<255, 10::5>>)
{:ok, 8170}
iex(18)> MyApp.ID.__fluid__(:dump, :node_id, 8000)
{:ok, <<250, 0::size(5)>>}
iex(19)> MyApp.ID.__fluid__(:dump, :node_id, 9999)
```

For the `local_id` field we gave the option of `unsigned: false` for demonstration purposes only:

```elixir
iex(20)> MyApp.ID.__fluid__(:bit_size, :local_id)
10
iex(21)> MyApp.ID.__fluid__(:min, :local_id)
-512
iex(22)> MyApp.ID.__fluid__(:max, :local_id)
511
```

For each node, we can generate 1024 ids per millisecond. Enough for the majority of apps.

### Formats

We chose `Fluid.Format.Hexadecimal` because it is easier to read
and it keeps the order correctly.

Let's create a full ID:

```elixir
iex(3)> MyApp.ID.new(inserted_at: ~N[2018-01-01 00:00:00], node_id: 0, local_id: 0)
{:ok, "0000-0000-0000-0000"}
iex(4)> MyApp.ID.new(inserted_at: ~N[2043-07-31 12:34:56.654], node_id: 1976, local_id: 432)
{:ok, "5df8-423a-071e-e1b0"}
```

So, we can see it is simple to create IDs.
The format is using `groups: 4` hexadecimal characters and the separator is `-`
just because it easier to read for the human eye.

In addition, the format respect the `inserted_at` order:

```elixir
iex(5)> "5df8-423a-071e-e1b0" > "0000-0000-0000-0000"
true
```

So this way we can use those binary strings in our code.
This method is similar to the one used by Ecto with the UUID,
it works with strings and not with bitstrings.

However, we can decode an id to its bits representation if it is needed:

```elixir
iex(6)> MyApp.ID.decode("5df8-423a-071e-e1b0")
{:ok, <<93, 248, 66, 58, 7, 30, 225, 176>>}
iex(7)> MyApp.ID.decode("0000-0000-0000-0000")
{:ok, <<0, 0, 0, 0, 0, 0, 0, 0>>}
```

If we want to access to relevant data coded inside the ID we just:

```elixir
iex(8)> MyApp.ID.get("5df8-423a-071e-e1b0", :inserted_at)
{:ok, ~N[2043-07-31 12:34:56]}
iex(9)> MyApp.ID.get("5df8-423a-071e-e1b0", :node_id)
{:ok, 1976}
iex(10)> MyApp.ID.get("5df8-423a-071e-e1b0", :local_id)
{:ok, 432}
```

### More Introspection

```elixir
iex(2)> MyApp.ID.__fluid__(:bit_size)
64
iex(3)> MyApp.ID.__fluid__(:fields)
[:inserted_at, :node_id, :local_id]
iex(4)> MyApp.ID.__fluid__(:field, :inserted_at)
%Fluid.Field.NaiveDateTime{
  epoch: ~N[2018-01-01 00:00:00],
  size: 41,
  time_unit: :millisecond
}
iex(5)> MyApp.ID.__fluid__(:field, :node_id)
%Fluid.Field.Integer{size: 13, unsigned: true}
```

### Ecto

The last part of the definition of the ID is the `:ecto` part.
This creates the functions needed by Ecto to store the ID in the database.
In this case the `:type` is `:integer`.
To save as an integer we have to set the format to `Fluid.Format.Integer`.
That's all. Now we can use it:

```elixir
defmodule MyApp.Repo.Migrations.CreatePost do
  use Ecto.Migration

  def change() do
    create table(:post, primary_key: false) do
      add(:id, :bigint, primary_key: true)
      add(:user_id, references(:users, type: :bigint), null: false)
      add(:body, :text)
    end
  end
end

defmodule MyApp.Post do
  use Ecto.Schema

  @primary_key {:id, MyApp.ID, autogenerate: true, read_after_writes: true}
  @foreign_key MyApp.ID
  @timestamps_opts [inserted_at: false, type: :utc_datetime, usec: false]

  schema "posts" do
    belongs_to :user, MyApp.User
    field :body, :string
  end

  def inserted_at(%__MODULE__{id: id}), do: MyApp.ID.get(id, :inserted_at)
end
```

We are still working with hexadecimal strings that are easy to read.
Ecto, internally, will use 64 bits integer to improve indexing and to save space in the database.

```elixir
iex> Repo.insert!(%Post{id: "0000-1111-2222-3333", user_id: "ffff-0000-ffff-0000", body: "text"})
%Post{...}
iex> Repo.get!(Post, "0000-1111-2222-3333")
%Post{...}
```

Like we have the `inserted_at` field in the ID, we don't need the same timestamp field.
We defined a function to get it easily given the struct.
We can also paginate or search by `inserted_at` with just the ID:

```elixir
iex> init_date = MyApp.ID.new(inserted_at: ~N[2018-03-01 00:00:00], local_id: 0, node_id: 0)
{:ok, "0097-eb9a-0000-0000"}
iex> final_date = MyApp.ID.new(inserted_at: ~N[2018-04-01 00:00:00], local_id: 0, node_id: 0)
{:ok, "00e7-be2c-0000-0000"}
iex> from p in Post, where: p.id > ^init_date and p.id < ^final_date
```

And ordering by ID means ordering by date as well.


## Optimized in compilation

The generated modules are optimized in compilation stage, avoiding unnecessary operation in runtime.
Most of the functions use pattern matching with bitstrings which are very fast in Elixir.
This is needed because the functions are used often:

* casting parameters in queries
* to load any model
* to insert any model
* to update any model
* to delete any model

## Work in progress

This is a proof of concept. I use this kind of ID with very good results.
This library is a try to make it more generic, so everyone can create its own ID.
There are more options I like to add, better errors, etc.

More formats:

  * Fluid.Format.Bitstring
  * Fluid.Format.Base32
  * Fluid.Format.Base64
  * Fluid.Format.UrlBase64
  * Fluid.Format.OrderedUrlBase64
  * Fluid.Format.Map
  * Fluid.Format.Struct

And more field types:

  * Fluid.Field.Binary
  * Fluid.Field.Boolean
  * Fluid.Field.Enum

If you are interested, just let me know.

[Alex Castaño](https://alexcastano.com)
