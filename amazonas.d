#!/usr/bin/env rdmd

import std.traits;
import std.stdio;

struct Amazonas {
	enum Player : byte {
		white = 0,
		black
	}
	enum Piece : byte {
		free = -1,

		white = 0,  // Matches player enum!
		black = 1,

		whiteArrow,
		blackArrow,
	}
	static string toString(Piece p) {
		final switch(p) {
			case Piece.free:       return "-";
			case Piece.white:      return "q";
			case Piece.black:      return "Q";
			case Piece.whiteArrow: return "x";
			case Piece.blackArrow: return "X";
		}
	}


	struct Position {
		auto x = 0;
		auto y = 0;
		bool translate(Position p) {
			x += p.x;
			y += p.y;
			return 0 <= x  &&  x < 10  &&
			       0 <= y  &&  y < 10;
		}
	}

	static Position[] directions = [
		Position(-1,-1), Position(-1, 0), Position(-1, 1),
		Position( 0,-1),                  Position( 0, 1),
		Position( 1,-1), Position( 1, 0), Position( 1, 1)
	];

	Piece[10][10]  board;
	Position[4][2] amazonas = [
		[Position(0,3), Position(3,0), Position(6,0), Position(9,3)],
		[Position(0,6), Position(3,9), Position(6,9), Position(9,6)]
	];

	void start() {
		foreach(player; EnumMembers!Player)
			foreach(pos; amazonas[player])
				board[pos.y][pos.x] = cast(Piece)(player);
	}
	this(const ref Amazonas a) {
		board[]    = a.board[];
		amazonas[] = a.amazonas[];
	}

	void print() {
		foreach_reverse(row; board) {
			foreach(cell; row)
				write(toString(cell));
			writeln();
		}
	}

	void move(Player p, int i,
		        Position start,
		        Position goal,
		        Position arrow) {
		assert(amazonas[p][i]==start, "Wrong amazona");
		assert(goal!=start, "Start should be different than the goal");
		assert(goal!=arrow, "Target should be different than the goal");

		// Move piece
		amazonas[p][i] = goal;
		// Update board
		board[start.y][start.x] = Piece.free;
		board[ goal.y][ goal.x] = cast(Piece)(p);
		board[arrow.y][arrow.x] = cast(Piece)(p+2); // Gets the player's arrow
	}

	auto ref moves(Player p) {
		Amazonas[] moves;  // At most 5184

		foreach(a_i, a; amazonas[p]) {
			Position start = a;

			foreach(d; Amazonas.directions) {
				Position goal = start;
				while(goal.translate(d) && board[goal.y][goal.x]==Piece.free)
					foreach(da; Amazonas.directions) {
						Position target = goal;

						while(target.translate(da) && board[target.y][target.x]==Piece.free) {
							moves ~= Amazonas(this);
							moves[$-1].move(p, a_i, start, goal, target);
						}
					}
			}
		}

		writef("Found %d moves\n", moves.length);
		return moves;
	}
}

int main() {
	Amazonas a;
	a.start();

	foreach(m; a.moves(Amazonas.Player.white)) {
		//m.print();
	}

	return 0;
}
