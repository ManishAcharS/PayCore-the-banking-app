$base = 'https://paycore-banking-app.vercel.app'
try {
   = Invoke-WebRequest -Uri "/api/health" -UseBasicParsing
  Write-Output "HEALTH: "
  Write-Output .Content
} catch {
  Write-Output "ERR"
  Write-Output .Exception.Message
}
