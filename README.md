# growletters

This is a game about growing apples.
"Why not just make apple trees?"
seems too boring

In this game, you grow bananas to trade for apples in multiplayer.
But as the economy goes, there's so much demand for a limited supply of apples.
So prices go up exponentially until apples are practically inaffordable.
The player with the most apples wins!

## Getting Started

If you want to run this on your own machine, follow these steps:

1. Build flutter code
```sh
flutter build web
```

2. Make a web server
```sh
cd build/web
python3 -m http.server
```

3. Run the actual go server (in a seperate terminal)
```sh
# go back to the root
cd server
go run .
```

Have fun! (requires friends)

## Purpose
This game teaches kids vocabulary. It also teaches them the unstable economics of apples.

## Playing the game

Clients can choose to be a host or a player in the lobby.

The host:
- shares the join code
- can kick people
- sets the time limit
- starts the game

The players:
- play the game

When you enter the game, you need to click on the little seeds and answer questions to grow them into big trees.
The big trees (at stage 5) produce bananas. You can harvest these by clicking on the tree.

When you have enough bananas, go to the trading post to trade for apples. You can also trade your apples for more trees.

## Other notes

Not many contribution guidelines here because only I understand the code. You can too, although it'll take you a day+.

If you were wondering how many dart files this project has, we have `40` whole files! That's a lot for a small project!
