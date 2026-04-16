# Windows PowerShell GUI for WinNFSd - Placeholder Optimization
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- 1. WINAPI (KHÔNG LỖI SỐ) ---
$signature = @'
[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern uint SetThreadExecutionState(uint esFlags);

[DllImport("user32.dll", CharSet = CharSet.Auto)]
public static extern Int32 SendMessage(IntPtr hWnd, int msg, int wParam, [MarshalAs(UnmanagedType.LPWStr)] string lParam);
'@
$WinAPI = Add-Type -MemberDefinition $signature -Name "WinAPI" -Namespace "WinAPI" -PassThru

function Keep-System-Awake { try { [void]$WinAPI::SetThreadExecutionState([uint32]2147483649) } catch {} }
function Allow-System-Sleep { try { [void]$WinAPI::SetThreadExecutionState([uint32]2147483648) } catch {} }

# --- 2. BIẾN ---
$script:nfsProcess = $null
$nfsExe = Join-Path $PSScriptRoot "winnfsd.exe"
$defaultPath = $PSScriptRoot 

# --- 3. STOP LOGIC ---
function Stop-NFS {
    if ($script:nfsProcess) { Stop-Process -Id $script:nfsProcess.Id -Force -ErrorAction SilentlyContinue }
    Get-Process "winnfsd" -ErrorAction SilentlyContinue | Stop-Process -Force
    Allow-System-Sleep
}

# --- 4. GIAO DIỆN ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "NFS Ultimate Manager"
$form.Size = New-Object System.Drawing.Size(440, 240)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"

# TextBox + Placeholder (Cue Banner)
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(25, 50)
$textBox.Size = New-Object System.Drawing.Size(300, 25)
$textBox.Text = $defaultPath # Tự điền path hiện tại cho ông đỡ phải gõ
$form.Controls.Add($textBox)

# Thiết lập chữ mờ khi ô trống
[void]$WinAPI::SendMessage($textBox.Handle, 0x1501, 0, "Dán đường dẫn folder vào đây...")

$browseBtn = New-Object System.Windows.Forms.Button
$browseBtn.Text = "Chọn..."
$browseBtn.Location = New-Object System.Drawing.Point(335, 48)
$browseBtn.Size = New-Object System.Drawing.Size(75, 28)
$browseBtn.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = "Chọn thư mục bạn muốn share NFS" # TIÊU ĐỀ BẢNG CHỌN
    $dlg.ValidateNames = $false
    $dlg.CheckFileExists = $false
    $dlg.CheckPathExists = $true
    
    # ĐÂY LÀ PLACEHOLDER TRONG BẢNG CHỌN (NHƯ HÌNH ÔNG GỬI)
    $dlg.FileName = "--- NHẤN OPEN ĐỂ CHỌN THƯ MỤC NÀY ---"
    
    if ($dlg.ShowDialog() -eq "OK") { 
        # Lấy đường dẫn thư mục cha của file ảo đó
        $textBox.Text = [System.IO.Path]::GetDirectoryName($dlg.FileName) 
    }
})
$form.Controls.Add($browseBtn)

$startBtn = New-Object System.Windows.Forms.Button
$startBtn.Text = "🚀 CHẠY NFS & CHỐNG NGẮT MẠNG"
$startBtn.Location = New-Object System.Drawing.Point(25, 110)
$startBtn.Size = New-Object System.Drawing.Size(385, 60)
$startBtn.BackColor = [System.Drawing.Color]::PaleGreen
$startBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($startBtn)

# --- 5. TRAY ICON ---
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Shield
$notifyIcon.Visible = $false
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$menuShow = $contextMenu.Items.Add("Hiện giao diện")
$menuStop = $contextMenu.Items.Add("Dừng & Thoát hẳn")
$notifyIcon.ContextMenuStrip = $contextMenu

# --- 6. LOGIC CHẠY ---
$startBtn.Add_Click({
    if (Test-Path $textBox.Text) {
        Stop-NFS 
        Keep-System-Awake
        $script:nfsProcess = Start-Process $nfsExe -ArgumentList "`"$($textBox.Text)`"", "/exports" -WindowStyle Hidden -PassThru
        $form.Hide()
        $notifyIcon.Text = "NFS Sharing: $($textBox.Text)"
        $notifyIcon.Visible = $true
        $notifyIcon.ShowBalloonTip(3000, "NFS Live", "Server đã chạy ngầm và chống ngủ gật.", [System.Windows.Forms.ToolTipIcon]::Info)
    }
})

$menuShow.Add_Click({ $form.Show() })
$notifyIcon.Add_DoubleClick({ $form.Show() })
$menuStop.Add_Click({ Stop-NFS; $notifyIcon.Visible = $false; [System.Windows.Forms.Application]::Exit() })

$form.Add_FormClosing({
    if ($script:nfsProcess -and $notifyIcon.Visible) {
        $_.Cancel = $true
        $form.Hide()
    } else {
        Stop-NFS
        $notifyIcon.Visible = $false
    }
})

[System.Windows.Forms.Application]::Run($form)