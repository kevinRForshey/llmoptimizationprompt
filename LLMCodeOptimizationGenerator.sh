#!/usr/bin/env bash
# ============================================================================
# LLMCodeOptimizationGenerator.sh
# Generates an LLM prompt for code optimization tailored to your system specs
# Works on both Linux and macOS with bash or zsh
# ============================================================================
#
# SETUP:
#   1. Save this file as "LLMCodeOptimizationGenerator.sh" anywhere on your computer
#   2. Make it executable (only needed once):
#        chmod +x LLMCodeOptimizationGenerator.sh
#
# HOW TO RUN:
#   Option A - Without a code file (you'll paste code manually):
#        ./LLMCodeOptimizationGenerator.sh
#
#   Option B - With a code file (auto-injects your code):
#        ./LLMCodeOptimizationGenerator.sh /path/to/your/code.py
#
# WHAT IT DOES:
#   - Detects your OS, CPU, RAM, GPU, and installed runtimes
#   - Builds a detailed optimization prompt for any LLM (ChatGPT, Claude, etc.)
#   - Copies the prompt to your clipboard (pbcopy on Mac, xclip/xsel on Linux)
#   - You paste it into the LLM and (if needed) replace PASTE_YOUR_CODE_HERE
#
# NOTES:
#   - On Linux, install xclip or xsel for clipboard support:
#       sudo apt install xclip    (Debian/Ubuntu)
#       sudo dnf install xclip    (Fedora)
#       sudo pacman -S xclip      (Arch)
#   - If no clipboard tool is found, the prompt is saved to a file instead
#
# ============================================================================

# ---- Colors ----
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}Gathering system information...${NC}"
echo ""

# ---- Detect OS ----
OS_TYPE="$(uname -s)"

# ---- System Specs ----
if [[ "$OS_TYPE" == "Darwin" ]]; then
    # macOS
    OS_NAME="macOS $(sw_vers -productVersion)"
    OS_BUILD="Build $(sw_vers -buildVersion)"
    CPU_INFO="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Unknown')"
    CPU_CORES="$(sysctl -n hw.ncpu 2>/dev/null || echo 'Unknown')"
    CPU_ARCH="$(uname -m)"
    RAM_BYTES="$(sysctl -n hw.memsize 2>/dev/null || echo '0')"
    RAM_GB="$(echo "scale=1; $RAM_BYTES / 1073741824" | bc 2>/dev/null || echo 'Unknown')"
    RAM_INFO="${RAM_GB} GB"

    # GPU on macOS
    GPU_INFO="$(system_profiler SPDisplaysDataType 2>/dev/null | grep 'Chipset Model\|Chip Model' | sed 's/^[[:space:]]*//' || echo 'Unable to detect GPU')"
    if [[ -z "$GPU_INFO" ]]; then
        # Apple Silicon - GPU is part of the SoC
        GPU_INFO="$(sysctl -n machdep.cpu.brand_string 2>/dev/null | grep -i 'apple' && echo '(Integrated Apple GPU)' || echo 'Unable to detect GPU')"
    fi

    SPECS="OS: ${OS_NAME} (${OS_BUILD})
Architecture: ${CPU_ARCH}
Processor: ${CPU_INFO}
CPU Cores: ${CPU_CORES}
Total RAM: ${RAM_INFO}"

elif [[ "$OS_TYPE" == "Linux" ]]; then
    # Linux
    if [[ -f /etc/os-release ]]; then
        OS_NAME="$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'"' -f2)"
    else
        OS_NAME="Linux $(uname -r)"
    fi
    CPU_INFO="$(grep 'model name' /proc/cpuinfo 2>/dev/null | head -1 | cut -d':' -f2 | sed 's/^[[:space:]]*//' || echo 'Unknown')"
    CPU_CORES="$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 'Unknown')"
    CPU_ARCH="$(uname -m)"
    RAM_INFO="$(free -h 2>/dev/null | awk '/^Mem:/{print $2}' || echo 'Unknown')"

    # GPU on Linux
    GPU_INFO="$(lspci 2>/dev/null | grep -i 'vga\|3d\|display' | cut -d':' -f3 | sed 's/^[[:space:]]*//' || echo 'Unable to detect GPU')"
    if [[ -z "$GPU_INFO" ]]; then
        GPU_INFO="Unable to detect GPU (lspci not available)"
    fi

    SPECS="OS: ${OS_NAME}
Kernel: $(uname -r)
Architecture: ${CPU_ARCH}
Processor: ${CPU_INFO}
CPU Cores: ${CPU_CORES}
Total RAM: ${RAM_INFO}"
else
    echo -e "${RED}Unsupported OS: ${OS_TYPE}${NC}"
    exit 1
fi

# ---- GPU Block ----
if [[ -z "$GPU_INFO" || "$GPU_INFO" == *"Unable"* ]]; then
    GPU_BLOCK="Unable to detect GPU"
else
    GPU_BLOCK="$GPU_INFO"
fi

# ---- Runtime Detection ----
RUNTIMES=""

detect_runtime() {
    local cmd="$1"
    local label="$2"
    local version_flag="${3:---version}"

    if command -v "$cmd" &>/dev/null; then
        local ver
        ver="$($cmd $version_flag 2>&1 | head -1 | tr -d '\n')"
        RUNTIMES="${RUNTIMES}${label}: ${ver}\n"
    fi
}

detect_runtime "python3" "Python3"
detect_runtime "python"  "Python"
detect_runtime "node"    "Node.js"
detect_runtime "dotnet"  ".NET SDK"
detect_runtime "java"    "Java"    "-version"
detect_runtime "go"      "Go"      "version"
detect_runtime "rustc"   "Rust"
detect_runtime "gcc"     "GCC"
detect_runtime "g++"     "G++"
detect_runtime "clang"   "Clang"
detect_runtime "swift"   "Swift"

if [[ -z "$RUNTIMES" ]]; then
    RUNTIMES_BLOCK="No common runtimes detected"
else
    RUNTIMES_BLOCK="$(echo -e "$RUNTIMES" | sed '/^$/d')"
fi

# ---- Code Injection ----
CODE_FILE="$1"
CODE_BLOCK="PASTE_YOUR_CODE_HERE"
CODE_INJECTED=false

if [[ -n "$CODE_FILE" ]]; then
    if [[ -f "$CODE_FILE" ]]; then
        CODE_BLOCK="$(cat "$CODE_FILE")"
        CODE_INJECTED=true
        echo -e "${GREEN}Code file loaded: ${CODE_FILE}${NC}"
    else
        echo -e "${RED}WARNING: File not found: ${CODE_FILE}${NC}"
        echo -e "${YELLOW}The prompt will use PASTE_YOUR_CODE_HERE as a placeholder.${NC}"
        echo ""
    fi
fi

# ---- Build the Prompt ----
PROMPT="As a Senior Level Software Engineer, optimize the following code so that:
1. No existing functionality is changed — inputs and outputs must remain identical
2. It is optimized to run as fast as possible on the system described below
3. All optimizations are documented with inline comments explaining WHY each change improves performance on this specific hardware

<system_specs>
${SPECS}
GPU: ${GPU_BLOCK}
</system_specs>

<installed_runtimes>
${RUNTIMES_BLOCK}
</installed_runtimes>

<optimization_priorities>
- Leverage CPU architecture and instruction sets available on this processor
- Optimize memory usage relative to available RAM
- Use OS-specific performance APIs or features where applicable
- Prefer algorithmic improvements over micro-optimizations
- Identify and eliminate unnecessary allocations, redundant operations, or blocking calls
- Consider parallelism and concurrency if the CPU supports multiple cores/threads
- If a GPU is available and the workload suits it, suggest GPU acceleration options
- Use runtime-specific optimizations relevant to the detected language and version
</optimization_priorities>

<output_format>
- Provide the fully optimized code in a single code block
- Include a summary table of changes made and their expected performance impact
- Flag any trade-offs (e.g., readability vs speed, memory vs speed)
- Note if any dependencies, compiler flags, or runtime flags are recommended for this system
- If no meaningful optimizations are possible, state that clearly
</output_format>

<code>
${CODE_BLOCK}
</code>"

# ---- Copy to Clipboard ----
CLIPBOARD_SUCCESS=false
OUTPUT_FILE="$HOME/llm-optimize-prompt.txt"

if [[ "$OS_TYPE" == "Darwin" ]]; then
    # macOS always has pbcopy
    echo "$PROMPT" | pbcopy
    CLIPBOARD_SUCCESS=true
elif [[ "$OS_TYPE" == "Linux" ]]; then
    if command -v xclip &>/dev/null; then
        echo "$PROMPT" | xclip -selection clipboard
        CLIPBOARD_SUCCESS=true
    elif command -v xsel &>/dev/null; then
        echo "$PROMPT" | xsel --clipboard --input
        CLIPBOARD_SUCCESS=true
    elif command -v wl-copy &>/dev/null; then
        echo "$PROMPT" | wl-copy
        CLIPBOARD_SUCCESS=true
    fi
fi

# If clipboard failed, save to file as fallback
if [[ "$CLIPBOARD_SUCCESS" == false ]]; then
    echo "$PROMPT" > "$OUTPUT_FILE"
fi

# ---- Display Results ----
echo ""
echo -e "${GREEN}============================================${NC}"
if [[ "$CLIPBOARD_SUCCESS" == true ]]; then
    echo -e "${GREEN} PROMPT COPIED TO CLIPBOARD!              ${NC}"
else
    echo -e "${GREEN} PROMPT SAVED TO FILE!                    ${NC}"
fi
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${CYAN}--- System Specs ---${NC}"
echo "$SPECS"
echo ""
echo -e "${CYAN}--- GPU ---${NC}"
echo "$GPU_BLOCK"
echo ""
echo -e "${CYAN}--- Installed Runtimes ---${NC}"
echo "$RUNTIMES_BLOCK"
echo ""

if [[ "$CODE_INJECTED" == true ]]; then
    echo -e "${CYAN}--- Code ---${NC}"
    echo -e "${GREEN}Loaded from: ${CODE_FILE}${NC}"
    echo ""
    echo -e "${GREEN}Your prompt is READY. Paste it directly into your LLM.${NC}"
else
    echo -e "${YELLOW}--- Next Steps ---${NC}"
    if [[ "$CLIPBOARD_SUCCESS" == true ]]; then
        echo "  1. Paste the prompt into your LLM (Cmd+V / Ctrl+V)"
        echo "  2. Replace PASTE_YOUR_CODE_HERE with your actual code"
    else
        echo "  1. Open the saved file: ${OUTPUT_FILE}"
        echo "  2. Copy the contents into your LLM"
        echo "  3. Replace PASTE_YOUR_CODE_HERE with your actual code"
        echo ""
        echo -e "${YELLOW}  TIP: Install xclip for automatic clipboard support:${NC}"
        echo "    sudo apt install xclip"
    fi
fi

echo ""
