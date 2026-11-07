#requires -Version 5.1
<#
Godot 4.7.2 import, 100-cycle baseline, then 10 outer rounds with
10..20 independent fix-verification runs and 10 independent retests.
On failure, preserves logs and stops for reproducible code repair.
No automatic code patching, Steam, web deployment, pushes or merges.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$GodotExe,
    [ValidateRange(10,20)][int]$FixVerifyRuns = 10
)
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$project=(Join-Path $root 'project.godot')
if(!(Test-Path -LiteralPath $GodotExe -PathType Leaf)){ throw "Godot executable not found: $GodotExe" }
if(!(Test-Path -LiteralPath $project)){ throw "Missing project: $project" }
$repoRoot=(Resolve-Path (Join-Path $root '..\..')).Path
$branch=(git -C $repoRoot branch --show-current 2>&1 | Out-String).Trim()
if($LASTEXITCODE -ne 0 -or $branch -ne 'feature/tree-rail-roguelike-design-20261107'){
    throw "Wrong branch: $branch"
}
$version=((& $GodotExe --version) 2>&1 | Out-String).Trim()
if($LASTEXITCODE -ne 0 -or $version -notmatch '^4\.7\.2(?:\.|\b)'){
    throw "Require Godot 4.7.2, found: $version"
}
$runId=Get-Date -Format 'yyyyMMdd-HHmmss'
$base=Join-Path $repoRoot ("tree\docs\qa_runs\"+$runId)
New-Item -ItemType Directory -Path $base -Force | Out-Null
$results=New-Object System.Collections.ArrayList
$summary=[ordered]@{
    branch=$branch; godot=$version; project=$project; started=(Get-Date).ToString('o')
    requested=[ordered]@{baseline_cycles=100; outer_rounds=10; fix_verifications_per_round=$FixVerifyRuns; retests_per_round=10}
    phase='INIT'; result='IN_PROGRESS'; completed_baseline_cycles=0; completed_rounds=0
    completed_fix_verifications=0; completed_retests=0; runs=$results
}
$summaryPath=Join-Path $base 'summary.json'
function Write-Summary {
    $summary | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $summaryPath -Encoding UTF8
}
function Invoke-Godot {
    param([string]$Name, [string[]]$Arguments, [string]$EvidencePath)
    $stdout=Join-Path $base ($Name+'.stdout.log')
    $stderr=Join-Path $base ($Name+'.stderr.log')
    $timer=[Diagnostics.Stopwatch]::StartNew()
    $oldAction=$ErrorActionPreference
    $ErrorActionPreference='Continue'
    try {
        & $GodotExe @Arguments 1> $stdout 2> $stderr
        $code=$LASTEXITCODE
    } finally {
        $ErrorActionPreference=$oldAction
    }
    $timer.Stop()
    $out=Get-Content -LiteralPath $stdout -Raw -ErrorAction SilentlyContinue
    $err=Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue
    $combined=$out+[Environment]::NewLine+$err
    $badLog= $combined -match '(?im)(SCRIPT ERROR|Parse Error|Failed to load|ERROR:|RAIL_QA_FAIL)'
    $hasSummary= $combined -match 'RAIL_QA_SUMMARY\s'
    $ok=($code -eq 0 -and !$badLog -and (!$EvidencePath -or ($hasSummary -and (Test-Path -LiteralPath $EvidencePath))))
    $record=[pscustomobject]@{name=$Name;result= $(if($ok){'PASS'}else{'FAIL'});exit_code=$code;duration_ms=$timer.ElapsedMilliseconds;stdout=$stdout;stderr=$stderr;evidence=$EvidencePath}
    [void]$results.Add($record)
    Write-Summary
    if(!$ok){ throw "Godot QA failed: $Name. See logs and $summaryPath. Repair source then rerun." }
}
try {
    $summary.phase='IMPORT'
    Write-Summary
    Invoke-Godot -Name 'import' -Arguments @('--headless','--path',$root,'--editor','--import') -EvidencePath ''
    $summary.phase='BASELINE_100'
    $baseline=Join-Path $base 'baseline-100.jsonl'
    Invoke-Godot -Name 'baseline-100' -Arguments @('--headless','--path',$root,'--script','res://tests/contract_runtime_qa.gd','--','--repeat=100',("--evidence="+$baseline.Replace('\','/'))) -EvidencePath $baseline
    $summary.completed_baseline_cycles=100
    Write-Summary
    for($round=1;$round -le 10;$round++){
        $summary.phase="ROUND_$round" + '_FIX_VERIFY'
        Write-Summary
        for($attempt=1;$attempt -le $FixVerifyRuns;$attempt++){
            $name='round-{0:d2}-fix-verify-{1:d2}' -f $round,$attempt
            $evidence=Join-Path $base ($name+'.jsonl')
            Invoke-Godot -Name $name -Arguments @('--headless','--path',$root,'--script','res://tests/contract_runtime_qa.gd','--','--repeat=1',("--evidence="+$evidence.Replace('\','/'))) -EvidencePath $evidence
            $summary.completed_fix_verifications++
            Write-Summary
        }
        $summary.phase="ROUND_$round" + '_RETEST_10'
        Write-Summary
        for($attempt=1;$attempt -le 10;$attempt++){
            $name='round-{0:d2}-retest-{1:d2}' -f $round,$attempt
            $evidence=Join-Path $base ($name+'.jsonl')
            Invoke-Godot -Name $name -Arguments @('--headless','--path',$root,'--script','res://tests/contract_runtime_qa.gd','--','--repeat=1',("--evidence="+$evidence.Replace('\','/'))) -EvidencePath $evidence
            $summary.completed_retests++
            Write-Summary
        }
        $summary.completed_rounds++
        Write-Summary
    }
    $summary.result='PASS_CONTRACT_AUTOMATION_ONLY'
} catch {
    $summary.result='FAIL_NEEDS_REPRO_FIX'
    $summary.error=$_.Exception.Message
    Write-Summary
    throw
} finally {
    $summary.finished=(Get-Date).ToString('o')
    Write-Summary
}
Write-Host ("Automated contract QA complete; GUI QA remains separate. Logs: "+$summaryPath)
