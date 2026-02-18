#!/usr/bin/env bash
# ============================================================================
# LLMCodeReviewPrompPhase1.ps1
# Generates an LLM prompt for code review based on the file(s) passed in
# ============================================================================
#
# SETUP:
#   1. Save this file as "LLMCodeReviewPrompPhase1.sh" anywhere on your computer
#
# HOW TO RUN:
#   Option A - Without a code file (you'll paste code manually):
#     Right-click the file > "Run with PowerShell"
#     OR open PowerShell and run:
#       ./LLMCodeReviewPrompPhase1.sh
#
#   Option B - With a code file (auto-injects your code):
#     Open PowerShell and run:
#       ./LLMCodeReviewPrompPhase1.sh -CodeFile "~/pathto/your/code.py"
#
# IF YOU GET AN EXECUTION POLICY ERROR:
#   Run this command first (only needed once):
#     Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
#
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
As a Senior Level Software Engineer, review the following code with the requirements:
1. If this is a python file, ensure it is in Pep8 or black format an follow these additional requirements:
2. The code should be using "standard" design patterns when appropriate
3. The code needs to use configuration to do configuration when appropriate.
4. The code should be optimized to run extremely well on hardware with lower specs.
5. The code cannot be wasting resources such as unnecessary disk or memor reads/writes etc.
6. The code cannot contained any unused code.
7. The code needs to be as "Pythonic" as possible.
8. The code needs to be easy enough for my mom to read it.
9. All recommended updates need to have a reasoning and explanation attached to it.


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
