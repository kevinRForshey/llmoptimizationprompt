# ============================================================================
# LLMCodeReviewPrompPhase1.ps1
# Generates an LLM prompt for code review based on the file(s) passed in
# ============================================================================
#
# SETUP:
#   1. Save this file as "LLMCodeReviewPrompPhase1.ps1" anywhere on your computer
#
# HOW TO RUN:
#   Option A - Without a code file (you'll paste code manually):
#     Right-click the file > "Run with PowerShell"
#     OR open PowerShell and run:
#       .\LLMCodeReviewPrompPhase1.ps1
#
#   Option B - With a code file (auto-injects your code):
#     Open PowerShell and run:
#       .\LLMCodeReviewPrompPhase1.ps1 -CodeFile "C:\path\to\your\code.py"
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

param(
    [string]$CodeFile
)

Write-Host ""
Write-Host "Gathering system information..." -ForegroundColor Cyan
Write-Host ""



# ---- Runtime Detection ----
$runtimes = @()
try {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $runtimes += "Python: $((python --version 2>&1).ToString().Trim())"
    }
} catch {}
try {
    if (Get-Command python3 -ErrorAction SilentlyContinue) {
        $runtimes += "Python3: $((python3 --version 2>&1).ToString().Trim())"
    }
} catch {}
try {
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $runtimes += "Node.js: $((node --version 2>&1).ToString().Trim())"
    }
} catch {}
try {
    if (Get-Command dotnet -ErrorAction SilentlyContinue) {
        $runtimes += ".NET SDK: $((dotnet --version 2>&1).ToString().Trim())"
    }
} catch {}
try {
    if (Get-Command java -ErrorAction SilentlyContinue) {
        $javaVer = (java --version 2>&1 | Select-Object -First 1).ToString().Trim()
        $runtimes += "Java: $javaVer"
    }
} catch {}
try {
    if (Get-Command go -ErrorAction SilentlyContinue) {
        $runtimes += "Go: $((go version 2>&1).ToString().Trim())"
    }
} catch {}
try {
    if (Get-Command rustc -ErrorAction SilentlyContinue) {
        $runtimes += "Rust: $((rustc --version 2>&1).ToString().Trim())"
    }
} catch {}

$runtimesBlock = if ($runtimes.Count -gt 0) { $runtimes -join "`n" } else { "No common runtimes detected" }

# ---- Code Injection ----
$codeBlock = "PASTE_YOUR_CODE_HERE"
$codeInjected = $false
if ($CodeFile -and (Test-Path $CodeFile)) {
    $codeBlock = Get-Content $CodeFile -Raw
    $codeInjected = $true
    Write-Host "Code file loaded: $CodeFile" -ForegroundColor Green
} elseif ($CodeFile) {
    Write-Host "WARNING: File not found: $CodeFile" -ForegroundColor Red
    Write-Host "The prompt will use PASTE_YOUR_CODE_HERE as a placeholder." -ForegroundColor Yellow
    Write-Host ""
}

# ---- Build the Prompt ----
$prompt = @"
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
$codeBlock
</code>
"@

# ---- Copy to Clipboard ----
$prompt | Set-Clipboard

# ---- Display Results ----
Write-Host "============================================" -ForegroundColor Green
Write-Host " PROMPT COPIED TO CLIPBOARD!              " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "--- System Specs ---" -ForegroundColor Cyan
Write-Host $specs
Write-Host ""
Write-Host "--- GPU ---" -ForegroundColor Cyan
Write-Host $gpu
Write-Host ""
Write-Host "--- Installed Runtimes ---" -ForegroundColor Cyan
Write-Host $runtimesBlock
Write-Host ""

if ($codeInjected) {
    Write-Host "--- Code ---" -ForegroundColor Cyan
    Write-Host "Loaded from: $CodeFile" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your prompt is READY. Paste it directly into your LLM." -ForegroundColor Green
} else {
    Write-Host "--- Next Steps ---" -ForegroundColor Yellow
    Write-Host "  1. Paste the prompt into your LLM (Ctrl+V)"
    Write-Host "  2. Replace PASTE_YOUR_CODE_HERE with your actual code"
    Write-Host ""
}

Write-Host ""
Read-Host "Press Enter to exit"