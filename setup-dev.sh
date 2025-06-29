#!/bin/bash

# Development setup script for ai-companion
# This installs all tools needed for local development

set -e

echo "🔧 Setting up ai-companion development environment..."

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install pre-commit
echo "📦 Installing pre-commit..."
if command_exists pip3; then
    pip3 install pre-commit
elif command_exists pip; then
    pip install pre-commit
else
    echo "❌ pip not found. Please install Python and pip first."
    exit 1
fi

# Install Lua and luarocks (if not present)
if ! command_exists lua; then
    echo "📦 Installing Lua..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists brew; then
            brew install lua luarocks
        else
            echo "❌ Homebrew not found. Please install Lua manually."
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command_exists apt; then
            sudo apt update && sudo apt install -y lua5.1 luarocks
        elif command_exists yum; then
            sudo yum install -y lua luarocks
        elif command_exists pacman; then
            sudo pacman -S lua luarocks
        else
            echo "❌ Package manager not found. Please install Lua manually."
            exit 1
        fi
    fi
fi

# Install luacheck
echo "📦 Installing luacheck..."
if command_exists luarocks; then
    luarocks install --local luacheck
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.luarocks/bin:"* ]]; then
        echo "export PATH=\"\$HOME/.luarocks/bin:\$PATH\"" >> ~/.bashrc
        export PATH="$HOME/.luarocks/bin:$PATH"
    fi
else
    echo "❌ luarocks not found. Please install luarocks first."
    exit 1
fi

# Install stylua (Lua formatter)
echo "📦 Installing stylua..."
if command_exists cargo; then
    cargo install stylua
elif [[ "$OSTYPE" == "darwin"* ]] && command_exists brew; then
    brew install stylua
else
    echo "⚠️ Could not install stylua. Please install manually:"
    echo "   cargo install stylua"
    echo "   or download from: https://github.com/JohnnyMorganz/StyLua/releases"
fi

# Install markdownlint-cli
echo "📦 Installing markdownlint-cli..."
if command_exists npm; then
    npm install -g markdownlint-cli
elif command_exists yarn; then
    yarn global add markdownlint-cli
else
    echo "⚠️ Could not install markdownlint-cli. Please install Node.js and npm first."
fi

# Install and setup pre-commit hooks
echo "🪝 Installing pre-commit hooks..."
pre-commit install

# Run pre-commit on all files to test setup
echo "🧪 Testing pre-commit setup..."
pre-commit run --all-files || true

echo ""
echo "✅ Development environment setup complete!"
echo ""
echo "📋 What was installed:"
echo "  - pre-commit (Git hooks manager)"
echo "  - luacheck (Lua linter)"
echo "  - stylua (Lua formatter) - if available"
echo "  - markdownlint-cli (Markdown linter)"
echo ""
echo "🚀 Ready for development!"
echo ""
echo "💡 Usage:"
echo "  - Hooks run automatically on git commit"
echo "  - Run manually: pre-commit run --all-files"
echo "  - Update hooks: pre-commit autoupdate"
echo ""
echo "🔧 Configure your editor:"
echo "  - Enable Lua LSP with luacheck integration"
echo "  - Set up auto-formatting with stylua"
echo "  - Install Lua and Markdown language servers"