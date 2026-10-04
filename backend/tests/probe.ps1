 = 'https://paycore-banking-app.vercel.app'
try {
   = Invoke-WebRequest -Uri  -UseBasicParsing -TimeoutSec 5
  Write-Output .StatusCode
} catch { Write-Output "ERR" }
