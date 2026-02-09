# Reaction Game

Game is inspired by the Speed test game shown in [Speden Spelit](https://en.wikipedia.org/wiki/Speden_Spelit).

![Speden spelit speed game](../assets/speed-game-speden-spelit.png)

## Overview

The Reaction Game is a fast-paced button-pressing challenge available in both solo and multiplayer modes. Players must quickly respond to visual cues by pressing the correct buttons as the pace increases. In multiplayer mode, two badges compete head-to-head using ESP-NOW communication.

## Game Modes

The Reaction Game is available in two modes: Solo (practice/challenge yourself) and Multiplayer (compete with another badge).

### Solo Mode

Single-player mode where you challenge yourself to achieve the highest score possible.

#### How to Play:

1. **Game Start**
   - Select "Reaction Game (Solo)" from the badge menu
   - The game generates a random sequence of 300 button presses
   - After a short countdown, the game begins
   - Four colored buttons appear: Green (Start), Blue (Select), Yellow (A), and Red (B)

2. **Gameplay**
   - The badge highlights one of the four buttons with a color flash
   - Quickly press the corresponding physical button on your badge
   - The game speeds up with each successful press
   - Continue until you make a mistake or complete all 300 steps

3. **Game End**
   - When the game ends, your final score is displayed
   - Options:
     - **Restart**: Try again to beat your score
     - **Quit**: Return to the main menu
   - **Long Press B**: Exit to menu

4. **Challenge Goals**
   - Try to beat your personal best
   - Aim for the maximum score of 300!
   - Practice to improve your reaction time

### Multiplayer Mode

Compete head-to-head with another badge using ESP-NOW communication.

#### How to Play:

1. **Connection Setup**
   - Two players select "Reaction Game" from their badge menus
   - Badges automatically establish a connection using ESP-NOW
   - Both players exchange random seeds to ensure fair gameplay

2. **Game Start**
   - Once connected, both badges generate identical button sequences using synchronized random seeds
   - The game begins after a short countdown
   - Four colored buttons appear on the screen: Green (Start), Blue (Select), Yellow (A), and Red (B)

3. **Gameplay**
   - The badge highlights one of the four buttons with a color flash
   - Players must quickly press the corresponding physical button on their badge
   - The highlight time decreases with each successful press, making the game progressively faster
   - The game continues until a player makes a mistake or completes all 300 steps

4. **Winning Conditions**
   - Press the wrong button → Game Over
   - Fall more than 5 steps behind the sequence → Game Over  
   - Successfully complete all 300 steps → Victory!

5. **Score Comparison**
   - When a player finishes, their final score is sent to the opponent
   - If the opponent is still playing, the finished player sees a "Waiting..." screen
   - Once both players finish, the badges compare scores and show the result:
     - **"You Won!"** - Your score is higher
     - **"You Lost!"** - Opponent's score is higher
     - **"Draw!"** - Both scores are equal

#### Technical Details:

- Both badges use the combined random seed (player1_seed + player2_seed) to generate identical button sequences
- This ensures both players face the exact same challenge
- Messages exchanged:
  - `ReactionStart`: Contains player's random seed
  - `ReactionEnd`: Contains player's final score

## Controls

### During Gameplay (Both Modes)

Press the physical button corresponding to the highlighted color on screen:
- **Start Button** (Green circle)
- **Select Button** (Blue circle)
- **A Button** (Yellow circle)
- **B Button** (Red circle)

### Exit/Menu Controls

- **Long Press B**: Exit game 
  - In Solo Mode: Works when game is over (on the end screen)
  - In Multiplayer Mode: Works when game is over (on the result screen)

### Solo Mode End Screen

- **Restart Button**: Start a new solo game
- **Quit Button**: Return to main menu

## Scoring

### Solo Mode
- Each correct button press adds 1 point to your score
- Maximum possible score: 300 points (complete all steps perfectly)
- Try to beat your personal best!

### Multiplayer Mode
- Each correct button press adds 1 point to your score
- Maximum possible score: 300 points (complete all steps perfectly)
- The player with the higher score wins
- Ties are possible if both players achieve the same score
- Results show: "You Won!", "You Lost!", or "Draw!"

## Game Difficulty

The game becomes progressively harder as you advance:
- **Highlight time**: Decreases by 1% per step (formula: `0.2 * 0.99^step`)
- **Reaction window**: Decreases from 1.0s to 0.2s minimum (formula: `max(0.2, 1.0 * 0.9^step)`)

This creates an exponential difficulty curve that challenges even the fastest players!
