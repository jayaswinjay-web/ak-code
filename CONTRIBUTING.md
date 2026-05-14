# Contributing to AK CODE

Thanks for your interest! AK CODE is an ambitious project — a programming language built from scratch in x86-64 assembly. Here's how you can help.

## Areas Where Help Is Welcome

- **NASM assembly** — Improve the bootstrap compiler (lexer, parser, codegen, runtime)
- **AK CODE standard library** — Write modules in AK CODE itself
- **Documentation** — Tutorials, examples, API docs
- **Testing** — Write test cases, find bugs
- **IDE** — Help with the AK CODE IDE (written in AK CODE)
- **Examples** — Port algorithms and showcase projects to AK CODE

## Getting Started

1. Fork the repo
2. Build the compiler following [README.md](README.md#quick-start)
3. Explore the codebase:
   - `asm/` — Bootstrap compiler in x86-64 NASM
   - `compiler/` — Stage-2 compiler in AK CODE
   - `stdlib/` — Standard library modules
4. Look for open issues or pick a feature from the roadmap

## Pull Request Process

1. Keep changes focused — one feature/fix per PR
2. Update documentation if you change behaviour
3. Add tests if you add features
4. Ensure the build script completes without errors

## Style Guide

- **Assembly**: Follow existing conventions in `asm/` files
- **AK CODE**: Use natural English naming — readable over terse
- **Docs**: Write in clear, simple English with examples

## Questions?

Open a discussion or issue. All skill levels welcome — even if you're new to assembly or compiler design!
