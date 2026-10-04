 = 'https://paycore-banking-app.vercel.app'
try { Invoke-RestMethod -Uri  -TimeoutSec 3 -ErrorAction Stop } catch { Write-Host .Exception.Message }
