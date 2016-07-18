

compile:
	ldc -O4 -of=server-ldc server.d amazonas.d
clean:
	rm *.o
