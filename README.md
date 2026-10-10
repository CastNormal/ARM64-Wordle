# ARM64 Wordle

A bare-metal **ARM64 Assembly language** clone of the popular Wordle game, built completely from scratch. This project showcases low-level system design, hardware register optimization, data compression engineering, and algorithmic mapping without relying on high-level runtime libraries.

## Key Engineering Highlights
* **High-Level to Low-Level Optimization:** Initially prototyped in **C** to map out logical features and structural flows before being completely rewritten in **ARM64 assembly**.
* **Custom Bit-Packed Word Compression:** Designed an asset utility in C that compresses a standard dictionary file into sequential **32-bit integer arrays**, significantly shrinking the game's storage footprint.
* **Low-Level Data Mechanics:** Implemented a binary search algorithm entirely in assembly using bitwise shifts (`lsl`) to validate player guesses against **14,850+ words** in sub-millisecond lookups.
* **Pure Register State Management:** Hand-allocated hardware registers (`x19-x27`) to maintain game loops, check frequencies, and track bitmask profiles without causing stack-thrashing.

---

## System Architecture

The codebase is structured to enforce a strict **Separation of Concerns**, cleanly isolating core engine loops from utilities and asset engines:

```text
arm64-wordle/
├── src/
│   └── asm/
│       ├── wordle.s        # Main game engine loop, logic, and bitmask comparisons
│       └── utils.s         # Modular subroutines for rendering and binary decoding
├── tools/
│   ├── word_compressor.c   # Tool transforming raw dictionary files to 32-bit tokens
│   └── int32-words.bin     # Packed asset binary parsed directly by the assembly engine
└── README.md               # Project documentation
```

---

## Technical Implementation Details

### 1. Data Compression Strategy
Instead of storing words as raw 5-byte ASCII strings (`14,855 words * 5 bytes = ~74KB`), the custom asset compilation tool maps lowercase alphabet letters (`a-z`) down to a tight **5-bit numeric value** (2⁵ = 32 total possibilities). 5 letters × 5 bits fits perfectly into a single **32-bit integer boundary**, maximizing standard CPU L1-cache efficiency during game runtime.

### 2. Algorithmic Guess Verification Loop
The engine validates matches in a dual-pass layout to correctly handle duplicate letters:
* **Pass 1 (Green/Exact Matches):** Scans the packed 32-bit values. If characters line up exactly, a positional bit is set in the green mask tracker (`x26`), and a frequency lookup table (`x25`) maps remaining unmatched characters.
* **Pass 2 (Yellow/Misplaced Matches):** Evaluates remaining positions against the frequency table. If a letter exists elsewhere in the puzzle word, a bit is set in the yellow mask tracker (`x27`), and that element is decremented from the target frequency map.

### 3. Zero High-Level Dependencies
The game interacts directly with the operating system kernel via software exception interrupts (`svc 0x80`). It sets up its own standard frames and directly invokes low-level system traps:
* `sys_read` (`#3`) for character stream input buffering
* `sys_write` (`#4`) for unbuffered standard stream printing
* `sys_open` (`#5`) & `sys_close` (`#6`) for binary asset lookups

---

## Accessing (macOS Apple Silicon)

### Prerequisites
* A Mac running an Apple Silicon M-Series chip
* Xcode Command Line Tools installed (`clang`, `as`, `ld`)

### Compilation & Execution

An automation script is provided in the `scripts/` directory to handle the multi-file assembly pipeline, resolve linkage symbols across modules, and launch the game seamlessly.

To build and run the executable in a single step, execute the script from the root of the project:

```bash
# Clone the repository
git clone https://github.com
cd arm64-wordle

# Make the script executable (if required)
chmod +x scripts/run.sh

# Run the unified build and launch pipeline
./scripts/run.sh
```

## Gameplay

The UI parses match states directly into distinct character tokens to deliver an instant visual report in the terminal:

```text
[ # ] = Correct Spot (Green Match equivalent)
[ ? ] = Wrong Spot (Yellow Match equivalent)
[ X ] = Not in Word (Grey Match equivalent)

Enter Guess: rails
# X X ? X
```
