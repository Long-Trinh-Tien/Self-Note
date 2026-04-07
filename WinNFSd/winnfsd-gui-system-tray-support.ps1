# Windows PowerShell GUI for WinNFSd - Fixed Tray Version
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- BIẾN TOÀN CỤC ---
$script:nfsProcess = $null

# --- KHỞI TẠO FORM ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "NFS Manager Pro v3"
$form.Size = New-Object System.Drawing.Size(440, 220) # Cao ráo để không mất nút
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# --- TRAY ICON SETUP ---
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Shield
$notifyIcon.Visible = $false

$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$menuShow = $contextMenu.Items.Add("Hiện giao diện")
$menuStop = $contextMenu.Items.Add("Dừng & Thoát hẳn")
$notifyIcon.ContextMenuStrip = $contextMenu

# --- CÁC THÀNH PHẦN GIAO DIỆN ---
$label = New-Object System.Windows.Forms.Label
$label.Text = "Thư mục muốn share NFS:"
$label.Location = New-Object System.Drawing.Point(20, 25)
$label.AutoSize = $true
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(20, 50)
$textBox.Size = New-Object System.Drawing.Size(300, 25)
$form.Controls.Add($textBox)

$browseBtn = New-Object System.Windows.Forms.Button
$browseBtn.Text = "Chọn..."
$browseBtn.Location = New-Object System.Drawing.Point(330, 48)
$browseBtn.Size = New-Object System.Drawing.Size(80, 28)
$browseBtn.Add_Click({
    $openFileDlg = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDlg.ValidateNames = $false
    $openFileDlg.CheckFileExists = $false
    $openFileDlg.CheckPathExists = $true
    $openFileDlg.FileName = "Chọn thư mục này"
    if ($openFileDlg.ShowDialog() -eq "OK") {
        $textBox.Text = [System.IO.Path]::GetDirectoryName($openFileDlg.FileName)
    }
})
$form.Controls.Add($browseBtn)

$startBtn = New-Object System.Windows.Forms.Button
$startBtn.Text = "🚀 START NFS SERVER"
$startBtn.Location = New-Object System.Drawing.Point(20, 110)
$startBtn.Size = New-Object System.Drawing.Size(390, 60)
$startBtn.BackColor = [System.Drawing.Color]::PaleGreen
$startBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)

# DÒNG QUAN TRỌNG ĐÂY TOMMY ƠI:
$form.Controls.Add($startBtn)

# --- XỬ LÝ SỰ KIỆN ---
$startBtn.Add_Click({
    if ($textBox.Text -ne "" -and (Test-Path $textBox.Text)) {
        # Chạy winnfsd ẩn hoàn toàn
        $script:nfsProcess = Start-Process "winnfsd.exe" -ArgumentList "`"$($textBox.Text)`"", "/exports" -WindowStyle Hidden -PassThru
        $form.Hide()
        $notifyIcon.Text = "Đang share: $($textBox.Text)"
        $notifyIcon.Visible = $true
        $notifyIcon.ShowBalloonTip(3000, "NFS Live", "Server đang chạy ngầm.", [System.Windows.Forms.ToolTipIcon]::Info)
    }
})

$menuShow.Add_Click({ $form.Show() })
$notifyIcon.Add_DoubleClick({ $form.Show() })

$menuStop.Add_Click({
    if ($script:nfsProcess) { Stop-Process -Id $script:nfsProcess.Id -Force -ErrorAction SilentlyContinue }
    # Quét sạch tàn dư
    Get-Process "winnfsd" -ErrorAction SilentlyContinue | Stop-Process -Force
    $notifyIcon.Visible = $false
    $form.Close()
    [System.Windows.Forms.Application]::Exit()
})

$form.Add_FormClosing({ $notifyIcon.Visible = $false })

[System.Windows.Forms.Application]::Run($form)