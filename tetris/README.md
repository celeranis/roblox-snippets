# Tetris
*2019 – 2020*

A recreation of the classic game in Roblox, featuring a blend of the classic gameplay with the quality-of-life features seen in modern versions.

Includes multiplayer compatibility, allowing your friends to view your game in real-time, while still allowing you to play the game without any latency.

## Demos
Play on Roblox: [The Hangout](https://www.roblox.com/games/4560236409/The-Hangout)

Watch on YouTube:
* [Tetris Demo: Singleplayer](https://www.youtube.com/watch?v=o9Y9InJdx1E)
* [Tetris Demo: Multiplayer](https://www.youtube.com/watch?v=7XGYgSyYCMk)

## Technical Overview
In this implementation, the client handles inputs and piece positioning, occasionally updating the server on its current location. Once the piece lands, the client tells the server where it ended up, and if the server determines that it was a valid placement, the active board will be updated. Each row affected by this placement will be checked to see if it has been filled, clearing them as necessary.

If other players are within a certain radius of the physical game screen, they will also receive these events, allowing them to view the game in real-time.

All of Roblox's available input methods are fully supported by the minigame, and mobile players are even able to use touch gestures to quickly move pieces around.

The performance of this minigame was put to the test when a streamer brought his audience to partake in an a contest to see who could last the longest in the game, resulting in around 10-20 different people playing the game at once on the same server. The game an smoothly the entire time, and the arcade was permanently expanded to account for the new traffic.
