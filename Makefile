

compile:
	ldc -O4 -of=amazonas-ldc  amazonas.d
	gdc -O3 -of=amazonas-gdc  amazonas.d
	dmd -O                    amazonas.d
