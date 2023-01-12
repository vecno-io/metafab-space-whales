# MetaFab - Space Whales

A 2D shooter set in space with some special and unique ammo and harvesting mechanics.

[LDJam 52 - Submission](https://ldjam.com/events/ludum-dare/52/the-dust-harvest)
[MetaFab 02 - Submission](https://story-arc.itch.io/the-metafab-harvest)

## LDJam Setup 

*Tag: v0.1.0*

**Game loop:**
```
Tutorial  -> start button
-> Game   -> Sector -> End
-> Dialog -> Sector -> End
-> goto Game
```

## Metafab Setup

*Tag: >v0.1.0*

#### Start & Stop Namkama Server

Copy the `.env.sample` file to `.env.dev` and update it with information for your metafab instance.

Start the server
~~~
$ cd server
$ go mod vendor
$ docker compose --env-file .env.dev up --build --timeout 30
~~~

Stop the server
~~~
$ docker-compose down --timeout 30
~~~

## Audio & Music

**Chiptronical**
[by Patrick de Arteaga](https://patrickdearteaga.com/royalty-free-music/chiptronical/)

## License

Code and Art are provided for education. 
All rights reserved unless stated otherwise.
