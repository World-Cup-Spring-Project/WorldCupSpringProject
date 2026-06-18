# Build all ArenaCup OS services (WorldCupSpringProject stack)
# Requires JDK 21 on PATH, OR use: docker compose up --build (multi-stage Dockerfiles)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$services = @(
    @{ Path = "eureka"; Mvnw = "mvnw.cmd" },
    @{ Path = "gateway"; Mvnw = $null },
    @{ Path = "../ms-core-data"; Mvnw = $null },
    @{ Path = "../ms-matches"; Mvnw = "mvnw.cmd" },
    @{ Path = "../ms-tickets"; Mvnw = $null },
    @{ Path = "../ms-engagement"; Mvnw = $null },
    @{ Path = "../ms-analytics"; Mvnw = "mvnw.cmd" }
)

foreach ($svc in $services) {
    $svcPath = Join-Path $root $svc.Path
    $pom = Join-Path $svcPath "pom.xml"
    $mvnw = if ($svc.Mvnw) { Join-Path $svcPath $svc.Mvnw } else { "mvn" }
    $name = Split-Path $svcPath -Leaf
    Write-Host "=== Building $name ===" -ForegroundColor Cyan
    if ($svc.Mvnw) {
        & $mvnw -f $pom clean package -DskipTests
    } else {
        mvn -f $pom clean package -DskipTests
    }
    if ($LASTEXITCODE -ne 0) { throw "Build failed for $name" }
}

Write-Host "All services built." -ForegroundColor Green
