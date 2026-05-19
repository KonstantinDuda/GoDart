package main

// Cheking the winner
var winPatterns = [8][3]int{
	{0, 1, 2}, {3, 4, 5}, {6, 7, 8},
	{0, 3, 6}, {1, 4, 7}, {2, 5, 8},
	{0, 4, 8}, {2, 4, 6},
}

func checkWinner(board [9]string, room *Room) string {
	for _, pattern := range winPatterns {
		if board[pattern[0]] != "" &&
			board[pattern[0]] == board[pattern[1]] &&
			board[pattern[1]] == board[pattern[2]] {
			room.Winner = board[pattern[0]]
			return board[pattern[0]]
		}
	}

	isFull := true
	for _, cell := range board {
		if cell == "" {
			isFull = false
			break
		}
	}

	if isFull {
		return "Draw"
	}

	canAnyoneWin := false
	for _, pattern := range winPatterns {
		hasX := false
		hasO := false
		for _, idx := range pattern {
			if board[idx] == "X" {
				hasX = true
			}
			if board[idx] == "O" {
				hasO = true
			}
		}
		if !(hasX && hasO) {
			canAnyoneWin = true
			break
		} else {
			canAnyoneWin = false
		}
	}

	if !canAnyoneWin {
		return "Draw"
	}

	return ""
}
