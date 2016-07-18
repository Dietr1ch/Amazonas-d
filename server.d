#!/usr/bin/env rdmd

import std.stdio;
import std.concurrency;
import core.time;
import amazonas : Board=Amazonas;

struct GetColourMessage {}
struct CancelMessage {}
struct CancelAckMessage {}

void amazonasPlayer(Tid ownerTid, Board.Player colour) {
	bool canceled = false;
	writeln("Starting ", thisTid, "...");

	while (!canceled) {
		receive(
			(GetColourMessage _) { send(ownerTid, colour); },

			(CancelMessage m) {
				writeln("Stopping ", thisTid, "...");
				send(ownerTid, CancelAckMessage());
				canceled = true;
			},

			(Board board, Duration timeLimit) {
				Board.Move m = board.moves(colour)[0];
				send(ownerTid, m);
			}
		);
	}
}

int main() {
	auto whiteThread = spawn(&amazonasPlayer, thisTid, Board.Player.white);
	register("white", whiteThread);
	auto blackThread = spawn(&amazonasPlayer, thisTid, Board.Player.black);
	register("black", blackThread);

	send(whiteThread, GetColourMessage());
	auto colour1 = receiveOnly!(Board.Player);
	assert(colour1 == Board.Player.white);
	writeln("White player running");

	send(blackThread, GetColourMessage());
	auto colour2 = receiveOnly!(Board.Player);
	assert(colour2 == Board.Player.black);
	writeln("Black player running");


	Duration timeout = dur!"seconds"(5);

	Board board;
	board.start();
	while(true) {

		// White turn
		writeln("");
		writeln("White plays on");
		board.print();
		if(board.moves(Board.Player.white).length == 0) {
			writeln("Black player trapped white");
			send(whiteThread, CancelMessage());
			send(blackThread, CancelMessage());
			break;
		}

		send(whiteThread, board, timeout);
		bool whiteOnTime = receiveTimeout(timeout,
			(Board.Move whiteMove) {
				if(!board.move(Board.Player.white, whiteMove)) {
					writeln("Black player won");
					send(whiteThread, CancelMessage());
					send(blackThread, CancelMessage());
				}
				writeln("White plays ", whiteMove);
			}
		);
		if(!whiteOnTime) {
			writeln("Black player won due to timeout");
			send(whiteThread, CancelMessage());
			send(blackThread, CancelMessage());
			break;
		}


		// Black turn
		writeln("");
		writeln("Black plays on");
		board.print();
		if(board.moves(Board.Player.black).length == 0) {
			writeln("White player trapped black");
			send(whiteThread, CancelMessage());
			send(blackThread, CancelMessage());
			break;
		}

		send(blackThread, board, timeout);
		bool blackOnTime = receiveTimeout(timeout,
			(Board.Move blackMove) {
				if(!board.move(Board.Player.black, blackMove)) {
					writeln("Black player won");
					send(whiteThread, CancelMessage());
					send(blackThread, CancelMessage());
				}
				writeln("Black plays ", blackMove);
			}
		);
		if(!blackOnTime) {
			writeln("White player won due to timeout");
			send(whiteThread, CancelMessage());
			send(blackThread, CancelMessage());
			break;
		}
	}

	return 0;
}
