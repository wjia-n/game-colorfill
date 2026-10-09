# Color Fill — Official Rules

_Package: `com.gameswajiha.colorfill`. This document is the authoritative source of truth for Color Fill's rules. If the implementation ever conflicts with this document, the implementation must be fixed — never the document._

## 1. Objective

Flood the entire board with **one** color. Your region starts as the single top-left tile and grows every time you pick a color, until every tile on the board is the same color.

## 2. Setup

- Each board is a square grid of colored tiles: **Easy = 8×8 with 5 colors, Medium = 10×10 with 6 colors, Hard = 12×12 with 7 colors**.
- Every board is generated with a seed and **re-dealt until it is valid**: all colors present somewhere on the board, and a greedy solver needs at least **5 / 7 / 9 moves** (Easy / Medium / Hard) to clear it — no freebies.
- Campaign has **20 levels**: levels 1–6 are Easy, 7–13 Medium, 14–20 Hard. Campaign levels use fixed seeds, so every player gets the same board per level. Restarting a board re-deals the **identical** tiles (same seed — a fair retry).
- Daily Challenge uses a fresh seed from the calendar date (one board per day). Quick Play uses a random seed at the chosen difficulty.
- Your move limit is **par + 8**, where par is the greedy-solver move count for that exact board. You get **3 hints** per board.

## 3. Turn order

There are no turns and no opponents — it is just you versus the board. Pick any color, watch the flood wave spread, then pick again.

## 4. Legal moves

- Tap any paint pot whose color **differs** from your current region color.
- Your whole connected region (all tiles reachable from the top-left through tiles of your region's color) changes to the picked color, and every touching tile of that color is absorbed into the region.
- Moves are legal only while the engine is in an input-open phase (awaiting a pick; a visible hint may be cancelled by picking).
- Undo is always available while input is open: it restores the exact previous board and move count (up to 30 steps of history).

## 5. Illegal moves

- Tapping the paint pot whose color your region **already is** is rejected (gentle "nope" sound, no state change) — it would be a no-op flood.
- Picking while the flood wave is still spreading, during the win/fail celebration, or after the board is over is rejected — input is locked outside input-open phases.
- Picking or undoing with an empty/unset board is rejected.

## 6. Captures

There are no captures — only growth. Every tile your region touches that matches your picked color joins the flood. Tiles never leave the region except via Undo.

## 7. Special rules

- **Undo** takes back your last pick (board, move count, and wave state all revert; up to 30 steps).
- **Hints** (3 per board): highlights the color that would grow your region the most right now. The highlight lasts ~2.4 seconds; picking a color cancels it.
- **Move limit**: par + 8 moves. If you run out of moves without flooding the board, the level fails ("Out of moves").
- **Stars**: 3 stars for finishing in ≤ par moves, 2 stars for ≤ par + 3, otherwise 1 star. Campaign unlocks the next level on any win; a better star count overwrites a worse one.
- **Daily streak**: flood the daily board to extend your streak; missing a day resets it to 1 on your next daily win.

## 8. Scoring

Stars are the score: up to 3 per campaign level (60 total). The win dialog shows your move count against par ("7 moves · par 5"). There is no numeric score beyond stars and streaks.

## 9. Winning conditions

- A single board is won when **every tile is the same color**.
- Campaign: clear all 20 levels (finishing level 20 fires the grand celebration).
- Daily: flood the seeded board before midnight to grow your streak.

## 10. Draw conditions

There are no draws. Every board ends in a win or an out-of-moves retry.

## 11. AI strategy

The hint system plays **greedily**: it simulates one flood per candidate color and picks the color that adds the most tiles to your region right now. Par is set from a full greedy solve of your exact board, so par is a strong-but-beatable target — optimal play often beats it.

## 12. Edge cases

- A board where the greedy solver needs fewer than the tier minimum moves is discarded during generation (up to 90 attempts), so trivial boards never ship.
- The flood wave is engine-driven: even if a frame timer dies mid-wave, the watchdog settles the flood to its solved state — the wave always finishes and the game can never get stuck.
- Pausing (menu pause or app backgrounding) freezes the phase timer; resuming re-arms the current phase — the board state is never lost or corrupted.
- Hard difficulty (campaign levels 14–20, Quick Play Hard) is a Pro feature; free players are routed to the Pro screen instead of a locked board.
- Campaign level seeds are fixed (`level * 7919 + 13`), so leaderboards and shares are comparable.

## 13. Test cases

1. Picking the current region color is rejected with the invalid sound and no move consumed.
2. Picking during the flood wave is rejected (input locked).
3. Undo restores the exact previous board and decrements the move count by one.
4. A board always contains every palette color and needs at least the tier-minimum greedy moves.
5. Solving the board flips every tile to one color and awards 3/2/1 stars per the par rule.
6. Exceeding par + 8 moves without solving triggers the fail state (retry offered).
7. Restart re-deals the identical board (same seed).
8. Hints highlight the greedy-best color and decrement the hint counter.
9. The engine watchdog recovers a killed phase timer without a stuck state.
10. Completing campaign level 20 fires the grand celebration event.
