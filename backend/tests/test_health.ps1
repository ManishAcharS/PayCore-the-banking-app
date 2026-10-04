$base = 'https://paycore-banking-app.vercel.app'
try {
  $r = Invoke-WebRequest -Uri "$base/api/health" -UseBasicParsing
  Write-Output "HEALTH:$($r.StatusCode)"
  Write-Output $r.Content
} catch {
  Write-Output "ERR"
}
