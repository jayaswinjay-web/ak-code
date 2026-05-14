# AK CODE — The Language That Reads Like a Conversation

**AK CODE** is a brand-new native programming language built from the ground up in x86-64 assembly. No C library, no VM, no interpreter — just raw native binaries for Linux (ELF) and Windows (PE/COFF).

## Philosophy

AK CODE reads like a natural English conversation between two human beings. Someone who has never programmed before can read AK CODE and understand exactly what it is doing. There are no statement terminators (no semicolons). Indentation conveys structure. Symbols are kept to an absolute minimum.

## Quick Start

### Prerequisites
- **NASM** (Netwide Assembler) — for building the bootstrap compiler
- **Linux**: `ld` (GNU linker) is required
- **Windows**: MSVC `link.exe` and `kernel32.lib`

### Building the Bootstrap Compiler

**Linux:**
```bash
chmod +x build.sh
./build.sh
```

**Windows:**
```cmd
build.bat
```

### Your First AK CODE Program

Create `hello.ak`:
```
show "Hello from AK CODE"
let name = "World"
show "Hello" name
```

Compile and run:
```bash
./build/akc hello.ak -o hello
./hello
```

## Language Features (Implemented)

- Natural English syntax with no punctuation clutter
- Variables: `let name = "Alice"`
- Constants: `always PI = 3.14159`
- Output: `show "Hello"`
- Input: `ask "Name?" and store in name`
- Arithmetic: `plus`, `minus`, `times`, `divided by`, `mod`
- Conditions: `if age is greater than 18`, `else`, `end`
- Loops: `repeat N times`, `repeat while`, `for each`, `count from`
- Functions: `define add taking a and b`, `give back`
- Classes: `make kind called Animal`, `new Dog called with`
- Lists: `list of`, `add to`, `remove from`, `first item of`, `size of`
- Maps: `map key is value end`, `get`, `set`
- Error handling: `try`, `catch`, `finally`
- Pattern matching: `match`, `when it is`, `otherwise`
- Modules: `bring in math`
- Concurrency: `do in background`, `wait for`
- Mathematics: symbolic, calculus, statistics, plotting
- AI/ML: neural network definition, training, prediction
- Web: HTTP server, routing, frontend pages
- Database: SQL tables, queries
- Testing: `test suite`, `test`, `expect`

## Project Structure

```
akcode/
├── asm/                  # Bootstrap compiler in x86-64 assembly
│   ├── entry_linux.asm   # Linux ELF entry point
│   ├── entry_win.asm     # Windows PE entry point
│   ├── lexer.asm         # Tokeniser
│   ├── parser.asm        # Recursive-descent parser
│   ├── codegen.asm       # x86-64 code generator
│   ├── runtime.asm       # Runtime library (malloc, print, etc.)
│   └── linker_glue.asm   # ELF/PE binary builder
├── compiler/             # Stage-2 compiler (written in AK CODE)
├── stdlib/               # Standard library
├── ide/                  # AK IDE (written in AK CODE)
├── tests/                # Test suite
├── docs/                 # Documentation
├── build.sh / build.bat  # Build scripts
└── README.md
```

## Status

- [x] Phase 0: Project structure
- [x] Phase 1: Language specification
- [x] Phase 2: Assembly bootstrap compiler
- [ ] Phase 3: Bootstrapping (compiler in AK CODE)
- [ ] Phase 4: Standard library
- [ ] Phase 5: AK IDE
- [ ] Phase 6: Advanced features
- [ ] Phase 7: Testing framework
- [ ] Phase 8: Documentation system
- [ ] Phase 9: Package manager

## License

AK CODE — A programming language for everyone.
