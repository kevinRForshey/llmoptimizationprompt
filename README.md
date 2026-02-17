# ============================================================================
# LLMCodeOptimizationGenerator.ps1
# Generates an LLM prompt for code optimization tailored to your system specs
# ============================================================================
#
# SETUP:
#   1. Save this file as "LLMCodeOptimizationGenerator.ps1" anywhere on your computer
#
# HOW TO RUN:
#   Option A - Without a code file (you'll paste code manually):
#     Right-click the file > "Run with PowerShell"
#     OR open PowerShell and run:
#       .\LLMCodeOptimizationGenerator.ps1
#
#   Option B - With a code file (auto-injects your code):
#     Open PowerShell and run:
#       .\LLMCodeOptimizationGenerator.ps1 -CodeFile "C:\path\to\your\code.py"
#
# IF YOU GET AN EXECUTION POLICY ERROR:
#   Run this command first (only needed once):
#     Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
#
# WHAT IT DOES:
#   - Detects your OS, CPU, RAM, GPU, and installed runtimes
#   - Builds a detailed optimization prompt for any LLM (ChatGPT, Claude, etc.)
#   - Copies the prompt to your clipboard
#   - You paste it into the LLM and (if needed) replace PASTE_YOUR_CODE_HERE
#
# ============================================================================
