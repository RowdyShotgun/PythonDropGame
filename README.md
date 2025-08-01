# Python DropGame

A Python conversion of the original LÖVE2D Lua DropGame, built with Pygame.

## Description

This is a fun arcade-style game where you click falling objects to send them back to the top. The game features progressive difficulty, powerups, and score tracking.

## Features

- **Progressive Difficulty**: Objects get faster as you play
- **Powerup System**: Snail powerup reduces object size and speed
- **Score Tracking**: Keep track of your high score
- **Multiple Object Types**: Different objects with varying speeds
- **Beautiful Graphics**: Background images and object sprites

## Requirements

- Python 3.6+
- Pygame 2.5.0+

## Installation

1. Clone the repository:
```bash
git clone https://github.com/RowdyShotgun/PythonDropGame.git
cd PythonDropGame
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

## How to Play

1. Run the game:
```bash
python main.py
```

2. **Click anywhere** on the title screen to start
3. **Click falling objects** to send them back to the top and score points
4. **Click the green snail powerup** (appears every 10 seconds) to temporarily slow down and shrink objects
5. **Don't let objects reach the bottom** - that's game over!
6. **Click anywhere** on the game over screen to return to title

## Controls

- **Left Mouse Click**: Interact with game elements
- **Close Window**: Quit the game

## Game Mechanics

- Objects spawn at the top of the screen and fall down
- Clicking an object sends it back to the top with increased speed
- Each click increases the overall difficulty
- The snail powerup reduces object size by 40% and speed by 50% for 5 seconds
- Game ends when any object reaches the bottom of the screen

## Files

- `main.py` - Main game file
- `requirements.txt` - Python dependencies
- `*.png` - Game assets (backgrounds, objects, powerup icon)

## Original

This is a Python conversion of the original LÖVE2D Lua game. The original Lua version can be found in the same directory.

## License

This project is open source and available under the MIT License. 