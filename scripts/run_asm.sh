#as -o utils.o src/asm/utils.s
#ld -macos_version_min 14.4.0 -o wordle wordle.o utils.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e main -arch arm64

as -o wordle.o src/asm/wordle.s
ld -macos_version_min 14.4.0 -o wordle wordle.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e main -arch arm64

./wordle