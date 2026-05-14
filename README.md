<div align="center">
  <img src="https://raw.githubusercontent.com/jayaswinjay-web/shared-assets/main/screenshots/ak-code-demo.svg" width="100%" alt="AK CODE Screenshot">
</div>

<br>

<div align="center">

[![License](https://img.shields.io/github/license/jayaswinjay-web/ak-code?style=flat&color=1a8a7a)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/jayaswinjay-web/ak-code?style=flat&color=1a8a7a)](https://github.com/jayaswinjay-web/ak-code/commits)
[![CI](https://github.com/jayaswinjay-web/ak-code/actions/workflows/build.yml/badge.svg)](https://github.com/jayaswinjay-web/ak-code/actions)
[![Repo Size](https://img.shields.io/github/repo-size/jayaswinjay-web/ak-code?style=flat&color=1a8a7a)](https://github.com/jayaswinjay-web/ak-code)
[![Stars](https://img.shields.io/github/stars/jayaswinjay-web/ak-code?style=social)](https://github.com/jayaswinjay-web/ak-code)

---

### ⭐ Support This Project — [Star on GitHub](https://github.com/jayaswinjay-web/ak-code) ⭐

---

</div>

---

## ✦ Features

AK CODE is a ground-up programming language built **entirely in x86-64 assembly** — no borrowed VM, no interpreter, no C runtime. Everything from the bootstrap compiler to the standard library is built from scratch.

### 🧠 Language Design

| Feature | Example |
|---------|---------|
| **Natural syntax** | `if age is greater than 18 then show "Adult"` |
| **No punctuation clutter** | No semicolons, no curly braces |
| **Variables** | `let name = "Alice"` |
| **Constants** | `always PI = 3.14159` |
| **Lists** | `let items = list of "apple" "banana" "cherry"` |
| **Maps** | `let config = map key is value end` |
| **Functions** | `define greet taking name and age` |
| **Classes** | `make kind called Animal` |
| **Error handling** | `try` / `catch` / `finally` |
| **Pattern matching** | `match value when it is` |
| **Concurrency** | `do in background` / `wait for` |
| **Modules** | `bring in math` |

### 📚 Standard Library (100+ modules)

```
stdlib/
├── ai/          Neural networks, tensors, optimizers, tokenizers
├── core/        IO, strings, lists, maps, memory, numbers, sets, errors
├── math/        Algebra, calculus, matrices, statistics, symbolic, visualization
├── web/         HTTP server/client, routing, HTML/CSS, JSON, WebSocket, templates
├── database/    SQL, NoSQL, ORM
├── os/          File I/O, networking, processes, threads
├── ui/          Windows, widgets, canvases, layouts
└── test/        Unit testing framework
```

### 🛠 Native Performance

- **Bootstrap compiler**: x86-64 assembly via NASM
- **Output**: Linux ELF binaries + Windows PE/COFF executables
- **Runtime**: Custom malloc, garbage collection, print, I/O — all from scratch
- **No dependencies**: Zero external libraries required

---

## ⚡ Quick Start

### Prerequisites

| Tool | Required For |
|------|-------------|
| [NASM](https://nasm.us/) | Assembling the bootstrap compiler |
| `ld` (GNU ld) | Linking Linux binaries |
| MSVC `link.exe` + `kernel32.lib` | Linking Windows binaries |

### Build

**Linux:**
```bash
chmod +x build.sh
./build.sh
```

**Windows:**
```cmd
build.bat
```

### Your First Program

```ak
# hello.ak
show "Hello from AK CODE!"
let name = ask "What's your name?"
show "Welcome," name "!"
```

```bash
./build/akc hello.ak -o hello
./hello
```

---

## 🎯 Showcase

### Hello World
```ak
show "Hello, World!"
```

### Fibonacci
```ak
define fibonacci taking n
  if n is less than 2 then
    give back n
  end
  give back fibonacci with n minus 1 plus fibonacci with n minus 2
end

let result = fibonacci with 10
show "Fibonacci(10) =" result
```

### HTTP Server
```ak
bring in web.server
bring in web.router

let app = router new
app get "/" give
  give back "Welcome to AK CODE Web!"
end

app get "/api/hello" give
  give back json of map
    message is "Hello from AK CODE"
    version is "1.0"
  end
end

server start with port 8080 and router app
show "Server running at http://localhost:8080"
```

### Neural Network
```ak
bring in ai.model
bring in ai.layer
bring in ai.optimizer

let model = neural network new
model add layer of type dense with 784 inputs and 128 outputs
model add layer of type relu
model add layer of type dense with 128 inputs and 10 outputs
model add layer of type softmax

model compile with optimizer "adam" and loss "categorical_crossentropy"
model train on dataset for 10 epochs
```

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────┐
│                   AK CODE Compiler                    │
│                                                      │
│  ┌─────────┐  ┌──────────┐  ┌───────────┐  ┌──────┐ │
│  │ Lexer   │→ │ Parser   │→ │ Codegen   │→ │ Link │ │
│  │ (asm)   │  │ (asm)    │  │ (asm)     │  │(glue)│ │
│  └─────────┘  └──────────┘  └───────────┘  └──────┘ │
│       │            │              │                   │
│       ▼            ▼              ▼                   │
│  tokens         AST           x86-64 asm     ELF/PE  │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │              Runtime Library                    │  │
│  │  malloc │ GC │ print │ IO │ type info │ math   │  │
│  └────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
         │
         ▼
  ┌─────────────────┐     ┌──────────────────┐
  │  Stage 2 Compiler│     │   AK CODE IDE    │
  │  (written in AK) │     │  (written in AK) │
  └─────────────────┘     └──────────────────┘
         │
         ▼
  ┌─────────────────────────────────────────────────┐
  │              Standard Library                    │
  │  AI │ Web │ Database │ Math │ OS │ UI │ Testing │
  └─────────────────────────────────────────────────┘
```

### Compiler Pipeline

1. **Lexer** (`asm/lexer.asm`) — Tokenises AK CODE source into tokens
2. **Parser** (`asm/parser.asm`) — Recursive-descent parser builds AST
3. **Codegen** (`asm/codegen.asm`) — Generates x86-64 machine code
4. **Linker Glue** (`asm/linker_glue.asm`) — Wraps into ELF or PE/COFF binary
5. **Runtime** (`asm/runtime.asm`) — Built-in malloc, GC, print, I/O

The **Stage 2 compiler** (`compiler/`) is written in AK CODE itself — once the bootstrap compiler is stable, AK CODE will compile itself.

---

## 🗺 Roadmap

- [x] **Phase 0**: Project structure & build system
- [x] **Phase 1**: Complete language specification (900+ lines)
- [x] **Phase 2**: Assembly bootstrap compiler (lexer, parser, codegen, runtime)
- [x] **Phase 3**: Stage-2 compiler written in AK CODE (compiler/)
- [x] **Phase 4**: Standard library (stdlib/)
- [x] **Phase 5**: AK CODE IDE with multi-agent AI panel (ide/)
- [ ] **Phase 6**: Advanced compiler optimisations (O1, O2, O3)
- [ ] **Phase 7**: Package manager (`akpkg`)
- [ ] **Phase 8**: Language server protocol (LSP) support
- [ ] **Phase 9**: Self-hosting — compiler compiles itself
- [ ] **Phase 10**: WASM backend & browser playground

---

## 📁 Project Structure

```
akcode/
├── asm/                # Bootstrap compiler (x86-64 assembly)
│   ├── lexer.asm       # Tokeniser
│   ├── parser.asm      # Recursive-descent parser
│   ├── codegen.asm     # x86-64 code generator
│   ├── runtime.asm     # Runtime library
│   └── linker_glue.asm # ELF/PE binary builder
├── compiler/           # Stage-2 compiler (written in AK CODE)
├── stdlib/             # Standard library
│   ├── ai/             # Neural networks, ML
│   ├── math/           # Algebra, calculus, stats
│   ├── web/            # HTTP, routing, templates
│   ├── database/       # SQL, NoSQL, ORM
│   ├── os/             # File, network, process
│   └── ui/             # Windows, widgets, canvas
├── ide/                # AK CODE IDE
│   ├── editor/         # Code editor with syntax highlighting
│   ├── agents/         # Multi-agent AI panel
│   ├── build/          # Build system & debugger
│   └── ui/             # IDE user interface
├── tests/              # Test suite
├── docs/               # Documentation
│   └── spec/           # Language specification
├── assets/             # Branding assets
├── build.bat           # Windows build script
├── build.sh            # Linux build script
└── README.md           # This file
```

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [Language Specification](docs/spec/LANGUAGE_SPEC.md) | Complete language specification (900+ lines) |
| [Standard Library API](docs/spec/STDLIB_API.md) | Full stdlib API reference |
| [Syntax Reference](docs/spec/SYNTAX_REFERENCE.md) | Quick syntax reference |
| [Hello World Tutorial](docs/tutorials/hello_world.md) | Getting started guide |
| [Web App Tutorial](docs/tutorials/web_app.md) | Building a web application |
| [AI Tutorial](docs/tutorials/train_ai.md) | Training a neural network |

---

## 🤝 Contributing

AK CODE is at an early stage and contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

- **Report bugs** — Open an issue
- **Suggest features** — Start a discussion
- **Write code** — Fork and submit a PR

---

## Show Your Support

- ⭐ **Star this repo** — helps others discover it
- 🐛 **Report issues** — I respond within 24 hours
- 📬 **Share feedback** — contact@jaytechsoln.in
- ☕ **Buy me a coffee** — [Sponsor](https://github.com/sponsors/jayaswinjay-web)

Made with ❤️ by [Aswin Jay](https://github.com/Aswinajay) — part of [JAY TECH SOLUTIONS](https://jaytechsoln.in)

## 📄 License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">
  <sub>Built from scratch with ❤️ and x86-64 assembly.<br>
  AK CODE — Because programming languages should be readable.</sub>
  <br><br>
  <a href="https://github.com/jayaswinjay-web/ak-code">
    <img src="https://img.shields.io/github/stars/jayaswinjay-web/ak-code?style=social" alt="Stars">
  </a>
  <a href="https://github.com/jayaswinjay-web/ak-code/fork">
    <img src="https://img.shields.io/github/forks/jayaswinjay-web/ak-code?style=social" alt="Forks">
  </a>
</div>
