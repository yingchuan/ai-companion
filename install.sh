#!/bin/bash

# AI 工作夥伴插件安裝腳本
# 用法: curl -sSL https://raw.githubusercontent.com/your-repo/ai-companion.nvim/main/install.sh | bash

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 工具函數
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 檢查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 檢查前置條件
check_prerequisites() {
    print_info "檢查前置條件..."
    
    # 檢查 Neovim
    if ! command_exists nvim; then
        print_error "未找到 Neovim，請先安裝 Neovim"
        exit 1
    fi
    
    # 檢查 Neovim 版本
    nvim_version=$(nvim --version | head -n1 | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+')
    print_success "Neovim 版本: $nvim_version"
    
    # 檢查 Git
    if ! command_exists git; then
        print_error "未找到 Git，請先安裝 Git"
        exit 1
    fi
    
    # 檢查 Cargo（用於安裝 aichat）
    if ! command_exists cargo; then
        print_warning "未找到 Cargo，將嘗試其他方式安裝 aichat"
    fi
    
    print_success "前置條件檢查完成"
}

# 安裝 aichat
install_aichat() {
    print_info "檢查 aichat..."
    
    if command_exists aichat; then
        print_success "aichat 已安裝"
        return
    fi
    
    print_info "安裝 aichat..."
    
    # 嘗試使用 Cargo 安裝
    if command_exists cargo; then
        print_info "使用 Cargo 安裝 aichat..."
        cargo install aichat
        print_success "aichat 安裝完成"
        return
    fi
    
    # 嘗試使用 Homebrew（macOS）
    if [[ "$OSTYPE" == "darwin"* ]] && command_exists brew; then
        print_info "使用 Homebrew 安裝 aichat..."
        brew install aichat
        print_success "aichat 安裝完成"
        return
    fi
    
    # 手動安裝提示
    print_error "無法自動安裝 aichat，請手動安裝："
    echo "  1. 安裝 Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    echo "  2. 安裝 aichat: cargo install aichat"
    echo "  3. 重新運行此腳本"
    exit 1
}

# 檢查 LazyVim
check_lazyvim() {
    print_info "檢查 LazyVim 配置..."
    
    local config_dir="$HOME/.config/nvim"
    local lazy_file="$config_dir/lua/config/lazy.lua"
    
    if [[ ! -f "$lazy_file" ]]; then
        print_warning "未檢測到 LazyVim 配置"
        print_info "請確保你使用的是 LazyVim 或兼容的配置"
    else
        print_success "LazyVim 配置已找到"
    fi
}

# 安裝插件
install_plugin() {
    print_info "安裝 AI 工作夥伴插件..."
    
    local config_dir="$HOME/.config/nvim"
    local plugin_dir="$config_dir/lua/ai-companion"
    local plugins_dir="$config_dir/lua/plugins"
    
    # 創建必要目錄
    mkdir -p "$plugin_dir"
    mkdir -p "$plugins_dir"
    
    # 下載插件文件（這裡假設從 GitHub 下載）
    print_info "下載插件文件..."
    
    # 如果有 Git 倉庫，可以直接 clone
    # git clone https://github.com/your-username/ai-companion.nvim.git "$plugin_dir"
    
    # 或者下載單個文件
    local files=(
        "init.lua"
        "core/chat.lua"
        "core/ai.lua"  
        "core/intent.lua"
        "core/content.lua"
        "templates/prompts.lua"
        "utils/git.lua"
        "utils/aichat.lua"
        "utils/helpers.lua"
        "config/defaults.lua"
    )
    
    for file in "${files[@]}"; do
        local dir_path=$(dirname "$plugin_dir/$file")
        mkdir -p "$dir_path"
        
        # 這裡應該從實際的倉庫 URL 下載
        # curl -sSL "https://raw.githubusercontent.com/your-repo/ai-companion.nvim/main/$file" -o "$plugin_dir/$file"
        print_info "需要手動複製文件: $file"
    done
    
    # 創建插件配置文件
    local config_file="$plugins_dir/ai-companion.lua"
    if [[ ! -f "$config_file" ]]; then
        print_info "創建插件配置文件..."
        cat > "$config_file" << 'EOF'
-- AI 工作夥伴插件配置
return {
  {
    "ai-companion.nvim",
    dir = vim.fn.stdpath("config") .. "/lua/ai-companion",
    dependencies = {
      "ibhagwan/fzf-lua",
      "nvim-lua/plenary.nvim",
    },
    opts = {
      workspace_dir = "~/workspace",
      ai_config = {
        embedding_model = "openai:text-embedding-3-small",
        generation_model = "claude-3-5-sonnet",
        temperature = 0.7,
      },
    },
    config = function(_, opts)
      require('ai-companion').setup(opts)
    end,
    event = "VeryLazy",
  }
}
EOF
        print_success "插件配置文件已創建: $config_file"
    else
        print_warning "插件配置文件已存在，跳過創建"
    fi
}

# 設置工作目錄
setup_workspace() {
    print_info "設置工作目錄..."
    
    local workspace_dir="$HOME/workspace"
    
    if [[ ! -d "$workspace_dir" ]]; then
        mkdir -p "$workspace_dir"
        print_success "工作目錄已創建: $workspace_dir"
    else
        print_success "工作目錄已存在: $workspace_dir"
    fi
    
    # 初始化 Git 倉庫（可選）
    if [[ ! -d "$workspace_dir/.git" ]]; then
        read -p "是否初始化 Git 倉庫？(y/N): " init_git
        if [[ "$init_git" =~ ^[Yy]$ ]]; then
            cd "$workspace_dir"
            git init
            echo "# AI 工作夥伴工作空間" > README.md
            echo "" >> README.md
            echo "這是由 AI 工作夥伴插件管理的工作空間。" >> README.md
            git add README.md
            git commit -m "Initial commit: AI companion workspace"
            print_success "Git 倉庫已初始化"
        fi
    fi
}

# 檢查 API 密鑰
check_api_keys() {
    print_info "檢查 API 密鑰配置..."
    
    local needs_setup=false
    
    if [[ -z "$OPENAI_API_KEY" ]]; then
        print_warning "未設置 OPENAI_API_KEY 環境變量"
        needs_setup=true
    fi
    
    if [[ -z "$ANTHROPIC_API_KEY" ]]; then
        print_warning "未設置 ANTHROPIC_API_KEY 環境變量"
        needs_setup=true
    fi
    
    if [[ "$needs_setup" == true ]]; then
        print_info "請在 shell 配置文件中設置 API 密鑰："
        echo ""
        echo "# 添加到 ~/.bashrc 或 ~/.zshrc"
        echo "export OPENAI_API_KEY=\"your-openai-api-key\""
        echo "export ANTHROPIC_API_KEY=\"your-anthropic-api-key\""
        echo ""
        echo "然後重新加載配置: source ~/.bashrc"
    else
        print_success "API 密鑰已配置"
    fi
}

# 完成安裝
finish_installation() {
    print_success "安裝完成！"
    echo ""
    print_info "下一步："
    echo "  1. 重啟 Neovim"
    echo "  2. 運行 :lazy sync 同步插件"
    echo "  3. 按 <leader><space> 開始使用"
    echo ""
    print_info "如果遇到問題："
    echo "  - 運行 :AiStatus 檢查狀態"
    echo "  - 運行 :AiConfigTest 測試 AI 連接"
    echo "  - 查看 README.md 獲取詳細文檔"
    echo ""
    print_info "快速開始："
    echo '  - "明天要開會討論新功能" → 創建會議記錄'
    echo '  - "記錄一下今天學的 React" → 保存學習筆記'
    echo '  - "週五前完成API文檔" → 創建任務'
    echo '  - "這週工作怎麼樣？" → 生成工作回顧'
}

# 主函數
main() {
    echo "=========================================="
    echo "   AI 工作夥伴插件安裝程序"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    install_aichat
    check_lazyvim
    install_plugin
    setup_workspace
    check_api_keys
    finish_installation
}

# 運行主函數
main "$@"