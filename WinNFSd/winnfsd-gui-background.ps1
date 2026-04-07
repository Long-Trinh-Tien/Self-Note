# Windows PowerShell GUI for WinNFSd (Modern Folder Picker)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "WinNFSd Manager Pro"
$form.Size = New-Object System.Drawing.Size(450,220)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog" # Cho nó giống app thật

$label = New-Object System.Windows.Forms.Label
$label.Text = "Folder to Share (NFS):"
$label.Location = New-Object System.Drawing.Point(20,25)
$label.AutoSize = $true
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(20,50)
$textBox.Size = New-Object System.Drawing.Size(300,25)
$form.Controls.Add($textBox)

$browseBtn = New-Object System.Windows.Forms.Button
$browseBtn.Text = "Browse..."
$browseBtn.Location = New-Object System.Drawing.Point(330,48)
$browseBtn.Size = New-Object System.Drawing.Size(80,28)

# --- PHẦN QUAN TRỌNG: CHỌN FOLDER KIỂU MỚI ---
$browseBtn.Add_Click({
    $openFileDlg = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDlg.Filter = "Folders|*.none" # Chỉ là filter ảo
    $openFileDlg.CheckFileExists = $false
    $openFileDlg.CheckPathExists = $true
    $openFileDlg.FileName = "Select Folder" # Chữ này sẽ hiện ở ô File Name
    $openFileDlg.Title = "Chọn thư mục để share NFS"
    
    if ($openFileDlg.ShowDialog() -eq "OK") {
        # Lấy thư mục cha của cái "file ảo" mình vừa chọn
        $textBox.Text = [System.IO.Path]::GetDirectoryName($openFileDlg.FileName)
    }
})
$form.Controls.Add($browseBtn)

$startBtn = New-Object System.Windows.Forms.Button
$startBtn.Text = "🚀 START NFS SERVER"
$startBtn.Location = New-Object System.Drawing.Point(20,110)
$startBtn.Size = New-Object System.Drawing.Size(390,45)
$startBtn.BackColor = [System.Drawing.Color]::PaleGreen
$startBtn.Font = New-Object System.Drawing.Size(10,1) # Bold font

$startBtn.Add_Click({
    if ($textBox.Text -ne "" -and (Test-Path $textBox.Text)) {
        # Chạy WinNFSd ngầm (-WindowStyle Hidden) để không hiện cửa sổ đen của nó
        Start-Process "winnfsd.exe" -ArgumentList "`"$($textBox.Text)`"", "/exports" -WindowStyle Hidden
        $form.Close()
    } else {
        [System.Windows.Forms.MessageBox]::Show("Đường dẫn không hợp lệ!", "Lỗi")
    }
})
$form.Controls.Add($startBtn)

$form.ShowDialog()