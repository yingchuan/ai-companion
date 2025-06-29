#!/bin/bash

# Development setup script for ai-companion
# This installs tools needed for local development (optional enhancements)

echo "🔧 Setting up ai-companion development environment..."

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Install pre-commit (required)
echo ""
print_info "Installing pre-commit (required)..."
if command_exists pre-commit; then
    print_success "pre-commit already installed"
elif command_exists pip3; then
    pip3 install pre-commit && print_success "pre-commit installed with pip3"
elif command_exists pip; then
    pip install pre-commit && print_success "pre-commit installed with pip"
else
    print_error "pip not found. Please install Python and pip first."
    echo "Visit: https://pip.pypa.io/en/stable/installation/"
    exit 1
fi

# Install pre-commit hooks
print_info "Installing pre-commit hooks..."
pre-commit install
print_success "Pre-commit hooks installed"

echo ""
print_info "Optional enhancements (for better development experience):"

# Check/install Lua
echo ""
if command_exists lua; then
    print_success "Lua already installed"
else
    print_warning "Lua not found - required for syntax checking"
    echo "Install instructions:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  brew install lua luarocks"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "  # Ubuntu/Debian: sudo apt install lua5.1 luarocks"
        echo "  # Fedora: sudo dnf install lua luarocks"
        echo "  # Arch: sudo pacman -S lua luarocks"
    fi
fi

# Check/install luacheck
if command_exists luacheck; then
    print_success "luacheck already installed"
else
    print_warning "luacheck not found - required for linting"
    if command_exists luarocks; then
        echo "Installing luacheck..."
        luarocks install --local luacheck
        # Add to PATH if needed
        if [[ ":$PATH:" != *":$HOME/.luarocks/bin:"* ]]; then
            echo "Add to your shell config (~/.bashrc or ~/.zshrc):"
            echo "  export PATH=\"\$HOME/.luarocks/bin:\$PATH\""
        fi
        print_success "luacheck installed"
    else
        echo "Install instructions:"
        echo "  luarocks install luacheck"
    fi
fi

# Check/install stylua
if command_exists stylua; then
    print_success "stylua already installed"
else
    print_info "stylua not found - optional for auto-formatting"
    echo "Install instructions:"
    echo "  cargo install stylua"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  brew install stylua"
    fi
fi

# Check/install markdownlint
if command_exists markdownlint; then
    print_success "markdownlint already installed"
else
    print_info "markdownlint not found - optional for doc linting"
    echo "Install instructions:"
    echo "  npm install -g markdownlint-cli"
fi

echo ""
print_info "Testing current setup..."
if pre-commit run --all-files; then
    print_success "All pre-commit hooks passed!"
else
    print_warning "Some hooks failed or were skipped (see above)"
    echo "This is normal if optional tools aren't installed yet."
fi

echo ""
print_success "Setup complete! 🎉"
echo ""
echo "📋 What's working:"
echo "  ✅ pre-commit hooks installed"
echo "  📝 Commits will trigger automatic checks"
echo "  🔧 Missing tools will show helpful install messages"
echo ""
echo "💡 Usage:"
echo "  • Hooks run automatically on: git commit"
echo "  • Run manually: pre-commit run --all-files"
echo "  • Update hooks: pre-commit autoupdate"
echo ""
echo "🚀 Start developing - the hooks will guide you!"