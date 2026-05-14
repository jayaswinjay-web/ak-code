#!/bin/bash
# ============================================================================
# AK CODE Bootstrap Compiler - Linux Build Script
# Builds the entire bootstrap compiler using NASM and LD
# ============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"

echo "=== AK CODE Bootstrap Compiler Build ==="
echo ""

# Create build directory
mkdir -p "$BUILD_DIR"

# Functions for build steps
assemble() {
    echo "  Assembling $1..."
    nasm -f elf64 -g -F dwarf "$SCRIPT_DIR/asm/$1" -o "$BUILD_DIR/${1%.asm}.o"
}

link() {
    echo "  Linking..."
    ld -o "$BUILD_DIR/akc" \
       "$BUILD_DIR/entry_linux.o" \
       "$BUILD_DIR/lexer.o" \
       "$BUILD_DIR/parser.o" \
       "$BUILD_DIR/codegen.o" \
       "$BUILD_DIR/runtime.o" \
       "$BUILD_DIR/linker_glue.o" \
       -e _start \
       --gc-sections \
       -z noexecstack
}

echo "Step 1: Assembling all source files..."
assemble "runtime.asm"
assemble "entry_linux.asm"
assemble "lexer.asm"
assemble "parser.asm"
assemble "codegen.asm"
assemble "linker_glue.asm"

echo ""
echo "Step 2: Linking..."
link

echo ""
echo "Step 3: Setting permissions..."
chmod +x "$BUILD_DIR/akc"

echo ""
echo "=== Build Complete ==="
echo "  Output: $BUILD_DIR/akc"
echo ""
echo "Usage:"
echo "  ./build/akc source.ak [-o output]"
echo ""

# Test if NASM is available
if command -v nasm &> /dev/null; then
    NASM_VER=$(nasm --version 2>&1 | head -n1)
    echo "  NASM: $NASM_VER"
else
    echo "  WARNING: NASM not found in PATH"
fi
