# Intisync

Create private sessions to control vibration-based devices remotely

## Run locally

Make sure you have `elixir` and `erlang` installed on your local machine.

A personal recommendation is to install them using [`asdf`](https://github.com/asdf-vm/asdf)
or my new favourite [`mise`](https://github.com/jdx/mise).

Then, make sure you have phoenix [installed](https://hexdocs.pm/phoenix/installation.html).
You can ignore the Ecto setup part, this project doesn't use Ecto for now.

After making sure you have elixir installed and the `mix` tool running, go to the root of the project and run:

1. Install javascript dependencies

```bash
cd assets && npm install && cd ..
```

2. Install elixir dependencies & build assets

```bash
mix setup
```

3. Run the project inside and start iex

```bash
iex -S mix phx.server
```

Now you can go to `localhost:4000` and start playing around :)

## Notes on the project name

Despite the similarity on the name, this project is not endorsed by [Intiface](https://github.com/intiface) and [Intiface](https://github.com/intiface) is their own registered trademark.

I chose this name because this project was inspired by `Intiface` and the clients require the use of their software to connect the Hub to the bluetooth devices.

Also I find the name IntiSync very catchy and easy to remember.
