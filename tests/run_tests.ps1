param(
    [string]$NcBin = "",
    [int]$Port = 8092
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$sdkFile = Join-Path $repoRoot "sdk\nc_ai_api.nc"
$ncLangRoot = Resolve-Path (Join-Path $repoRoot "..\nc-lang")

if (-not $NcBin) {
    $candidates = @(
        (Join-Path $ncLangRoot "engine\build\nc.exe"),
        (Join-Path $ncLangRoot "engine\build\nc_ready.exe"),
        (Join-Path $ncLangRoot "engine\build\nc_new.exe")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            $NcBin = $candidate
            break
        }
    }
}

if (-not $NcBin -or -not (Test-Path $NcBin)) {
    throw "NC binary not found. Pass -NcBin or build nc-lang/engine/build/nc.exe first."
}

$stdoutLog = Join-Path $env:TEMP "nc-ai-sdk-tests-stdout.log"
$stderrLog = Join-Path $env:TEMP "nc-ai-sdk-tests-stderr.log"
$serverProc = $null
$script:passed = 0
$script:failed = 0

function Invoke-ApiGet {
    param([string]$Path)
    Invoke-RestMethod -Uri "http://127.0.0.1:$Port$Path" -Method Get
}

function Invoke-ApiPost {
    param(
        [string]$Path,
        [hashtable]$Body
    )
    $json = $Body | ConvertTo-Json -Depth 8
    Invoke-RestMethod -Uri "http://127.0.0.1:$Port$Path" -Method Post -ContentType "application/json" -Body $json
}

function Wait-ForHealth {
    param([int]$TimeoutSeconds = 20)

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            $health = Invoke-ApiGet "/health"
            if ($health.status -eq "ok") {
                return
            }
        }
        catch {
            Start-Sleep -Milliseconds 300
        }
    }

    $stdout = if (Test-Path $stdoutLog) { Get-Content $stdoutLog -Raw } else { "" }
    $stderr = if (Test-Path $stderrLog) { Get-Content $stderrLog -Raw } else { "" }
    throw "Timed out waiting for NC AI SDK server on port $Port.`nSTDOUT:`n$stdout`nSTDERR:`n$stderr"
}

function Run-Test {
    param(
        [string]$Name,
        [scriptblock]$Body
    )

    try {
        & $Body
        Write-Host "PASS $Name"
        $script:passed++
    }
    catch {
        Write-Host "FAIL $Name"
        Write-Host "  $($_.Exception.Message)"
        $script:failed++
    }
}

try {
    $serverProc = Start-Process -FilePath $NcBin -ArgumentList @("serve", $sdkFile) -WorkingDirectory $repoRoot -PassThru -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
    Wait-ForHealth

    Run-Test "health" {
        $result = Invoke-ApiGet "/health"
        if ($result.status -ne "ok") {
            throw "Expected status=ok, got $($result.status)"
        }
        if ($result.release_mode -ne "stable-v1") {
            throw "Expected release_mode=stable-v1, got $($result.release_mode)"
        }
    }

    Run-Test "intent" {
        $result = Invoke-ApiPost "/intent" @{ prompt = "Build a todo CRUD API" }
        if ($result.intent -ne "crud") {
            throw "Expected intent=crud, got $($result.intent)"
        }
    }

    Run-Test "generate" {
        $result = Invoke-ApiPost "/generate" @{ prompt = "Build an orders CRUD service"; options = @{} }
        if (-not $result.code.Contains("service ")) {
            throw "Generated code is missing a service declaration"
        }
        if (-not $result.code.Contains("api:")) {
            throw "Generated code is missing an api block"
        }
    }

    Run-Test "recommend" {
        $code = "service `"demo`"`nversion `"1.0.0`"`n`nto list_items:`n    respond with []"
        $result = Invoke-ApiPost "/recommend" @{ code = $code; artifact_type = "service" }
        if ([int]$result.count -lt 1) {
            throw "Expected at least one recommendation"
        }
    }

    Run-Test "fix" {
        $buggy = "function greet:`n    return `"hi`""
        $result = Invoke-ApiPost "/fix" @{ buggy_code = $buggy; error_message = "return keyword" }
        if (-not $result.code.Contains("respond with ")) {
            throw "Expected fixed code to contain 'respond with'"
        }
    }

    Run-Test "reason" {
        $result = Invoke-ApiPost "/reason" @{ question = "What is 2 + 2?"; context = "" }
        if (-not $result.answer.Contains("4")) {
            throw "Expected arithmetic answer to mention 4"
        }
    }

    Run-Test "plan" {
        $result = Invoke-ApiPost "/plan" @{ goal = "Build a dashboard page"; constraints = @{} }
        if ($result.intent -ne "ncui") {
            throw "Expected plan intent=ncui, got $($result.intent)"
        }
        if ($result.steps.Count -lt 1) {
            throw "Expected at least one plan step"
        }
    }

    Run-Test "encode" {
        $result = Invoke-ApiPost "/encode" @{ text = "alpha beta beta" }
        if ([int]$result.token_count -ne 3) {
            throw "Expected token_count=3, got $($result.token_count)"
        }
        if ([int]$result.unique_count -ne 2) {
            throw "Expected unique_count=2, got $($result.unique_count)"
        }
    }

    Run-Test "similarity" {
        $result = Invoke-ApiPost "/similarity" @{ text_a = "alpha beta"; text_b = "alpha gamma" }
        if ([int]$result.overlap -ne 1) {
            throw "Expected overlap=1, got $($result.overlap)"
        }
    }

    Run-Test "swarm" {
        $result = Invoke-ApiPost "/swarm" @{ task = "Build a user registration service"; num_agents = 3; strategy = "balanced" }
        if (-not $result.winner.Contains("service ")) {
            throw "Expected winning swarm candidate to contain a service declaration"
        }
        if ($result.candidates.Count -ne 3) {
            throw "Expected exactly 3 swarm candidates"
        }
    }
}
finally {
    if ($serverProc -and -not $serverProc.HasExited) {
        Stop-Process -Id $serverProc.Id -Force
    }
}

Write-Host ""
Write-Host "Passed: $script:passed"
Write-Host "Failed: $script:failed"

if ($script:failed -gt 0) {
    exit 1
}
