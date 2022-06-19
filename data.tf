
data "aws_ami" "windows-2019" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "template_file" "windows-userdata" {
    template = <<EOF
      <script>
         net user ${var.instance_username} '${var.instance_password}' /add /y
         net localgroup administrators ${var.instance_username} /add
      </script>
      <powershell>
        if ($fqdn -eq $null){
            $fqdn = "$env:computername"
        }
        Write-Host "------Enabling WinRM (HTTP)"
        winrm quickconfig -q 
        winrm set "winrm/config" '@{MaxTimeoutms="1800000"}'
        winrm set "winrm/config/winrs" '@{MaxMemoryPerShellMB="1024"}'
        winrm set "winrm/config/service" '@{AllowUnencrypted="true"}'
        winrm set "winrm/config/client" '@{AllowUnencrypted="true"}'
        winrm set "winrm/config/service/auth" '@{Basic="true"}'
        winrm set "winrm/config/client/auth" '@{Basic="true"}'
        winrm set "winrm/config/service/auth" '@{CredSSP="true"}'
        winrm set "winrm/config/client" '@{TrustedHosts="*"}'
        
        # Remove HTTP listener
        Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse

        Write-Host "------Genning Thumbprint"
        $thumbprint = (New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname $fqdn -NotAfter (Get-Date).AddMonths(36)).Thumbprint

        Write-Host "------Proceeding with following details"
        Write-Host fqdn: $fqdn, thumbprint: $thumbprint
        $cmd = 'winrm create winrm/config/listener?Address=*+Transport=HTTPS `@`{Hostname=`"$fqdn`"`; CertificateThumbprint=`"$thumbprint`"`}'

        Write-Host "------Enabling WinRM (HTTPS)"
        Invoke-Expression $cmd
        
        Write-Host "------Making Firewall rule"
        & netsh advfirewall firewall add rule name="winRM HTTPS" dir=in action=allow protocol=TCP localport=5986

        Write-Host "------Testing WinRM"
        & test-wsman $fqdn

        # Set Administrator password
        $admin = [adsi]("WinNT://./${var.instance_username}, user")
        $admin.psbase.invoke("SetPassword", "${var.instance_password}")
      </powershell>
    EOF
}
