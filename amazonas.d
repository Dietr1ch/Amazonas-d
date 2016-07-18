#!/usr/bin/env rdmd

import std.traits;
import std.stdio;

struct Amazonas {
	enum Player : byte {
		white = 0,
		black,
	}
	enum Piece : byte {
		free = -1,

		white = 0,  // Matches player enum!
		black,

		whiteArrow, // player+2 = playerArrow!
		blackArrow,
	}

	pure const
	string toString(Piece p) {
		pragma(inline, true);
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

		/**
		 * Translates the position by `p` and checks bounds
	 */
		pure
		bool translate(const ref Position p) {
			pragma(inline, true);
			x += p.x;
			y += p.y;
			return 0 <= x  &&  x < 10  &&
			       0 <= y  &&  y < 10;
		}
	}

	static
	immutable
	Position[] directions = [
		Position(-1,-1), Position(-1, 0), Position(-1, 1),
		Position( 0,-1),                  Position( 0, 1),
		Position( 1,-1), Position( 1, 0), Position( 1, 1)
	];

	Piece[10][10]  board;
	Position[4][2] amazonas = [
		[Position(0,3), Position(3,0), Position(6,0), Position(9,3)],
		[Position(0,6), Position(3,9), Position(6,9), Position(9,6)]
	];

	/**
	 * Set up the starting position
	 */
	pure
	void start() {
		pragma(inline, true);
		foreach(player; EnumMembers!Player)
			foreach(pos; amazonas[player])
				board[pos.y][pos.x] = cast(Piece)(player);
	}

	this(const ref Amazonas a) {
		board[]    = a.board[];
		amazonas[] = a.amazonas[];
	}

	const
	void print() {
		pragma(inline, true);
		foreach_reverse(i, row; board) {
			write(i, " ");
			foreach(cell; row)
				write(toString(cell));
			writeln();
		}

		write("  ");
		foreach(col; 0..10)
			write(col);
		writeln();
	}

	struct Move {
		Player p;
		size_t amazonaID;
		Position start;
		Position goal;
		Position arrow;

		@property
		pure const
		bool valid() {
			pragma(inline, true);
			return start != goal &&
			       goal  != arrow;
		}
	}

	pure const
	bool validMove(Player p, const ref Move m) {
		pragma(inline, true);
		if (p!=m.p) {
			debug writeln("Wrong player");
			return false;
		}
		if (amazonas[m.p][m.amazonaID]!=m.start) {
			debug writeln("Wrong amazona");
			return false;
		}
		if (!m.valid) {
			debug writeln("Move must be valid");
			return false;
		}
		return true;
	}

	pure
	bool move(Player p, const ref Move m) {
		pragma(inline, true);
		if (!validMove(p, m))
			return false;

		// Move piece
		amazonas[m.p][m.amazonaID] = m.goal;
		// Update board
		board[m.start.y][m.start.x] = Piece.free;
		board[m. goal.y][m. goal.x] = cast(Piece)(m.p);
		board[m.arrow.y][m.arrow.x] = cast(Piece)(m.p+2); // Gets the player's arrow

		return true;
	}

	pure
	auto ref moves(Player p) {
		Move[] moves;  // At most 5184

		foreach(a_i, a; amazonas[p]) {  // Pick amazona
			Position start = a;

			// Temporarily free remove the Amazona
			// This allows shooting to the start and behind without extra checks
			auto oldPiece = board[a.y][a.x];
			board[a.y][a.x] = Piece.free;

			foreach(d; Amazonas.directions) {  // Pick Move direction
				Position goal = start;
				while(goal.translate(d) && board[goal.y][goal.x]==Piece.free)
					foreach(da; Amazonas.directions) {  // Pick Arrow direction
						Position target = goal;

						while(target.translate(da) && board[target.y][target.x]==Piece.free)
							moves ~= Move(p, a_i, start, goal, target);
					}
			}

			// Restore Amazona
			board[a.y][a.x] = oldPiece;
		}

		debug writef("Found %d moves\n", moves.length);
		return moves;
	}
}
