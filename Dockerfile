#
# Dockerfile for creating a Windows driver build environment
# Copyright (c) 2022 Colin Finck, ENLYZE GmbH <c.finck@enlyze.com>
# SPDX-License-Identifier: MIT
#

FROM mcr.microsoft.com/windows/servercore:ltsc2022
MAINTAINER Colin Finck <c.finck@enlyze.com>
LABEL Description="Windows Server Core 2022 with WDK 7.1.0, 7-Zip, and Git"

SHELL ["powershell"]

# Download and install 7-Zip.
RUN $ProgressPreference = 'SilentlyContinue'; \
    Invoke-WebRequest https://7-zip.org/a/7z2201-x64.exe -OutFile 7z2201-x64.exe; \
    Start-Process -FilePath 7z2201-x64.exe -ArgumentList (\"/S\") -Wait; \
    Remove-Item 7z2201-x64.exe

# Download and install our required parts of the WDK 7.1.0.
# Its KitSetup.exe installer doesn't work in a container, so we have to extract the MSIs by hand.
RUN $ProgressPreference = 'SilentlyContinue'; \
    Invoke-WebRequest https://download.microsoft.com/download/4/A/2/4A25C7D5-EFBE-4182-B6A9-AE6850409A78/GRMWDK_EN_7600_1.ISO -OutFile GRMWDK_EN_7600_1.ISO; \
    Start-Process -FilePath $Env:ProgramFiles\7-Zip\7z.exe -ArgumentList (\"x\", \"-y\", \"-o\wdkiso\", \"GRMWDK_EN_7600_1.ISO\") -Wait; \
    Start-Process -FilePath $Env:SystemRoot\system32\msiexec.exe -ArgumentList (\"/a\", \"\wdkiso\WDK\buildtools_x86fre.msi\", \"/q\", \"/norestart\", \"TARGETDIR=C:\wdk\") -Wait; \
    Start-Process -FilePath $Env:SystemRoot\system32\msiexec.exe -ArgumentList (\"/a\", \"\wdkiso\WDK\buildtools_x64fre.msi\", \"/q\", \"/norestart\", \"TARGETDIR=C:\wdk\") -Wait; \
    Start-Process -FilePath $Env:SystemRoot\system32\msiexec.exe -ArgumentList (\"/a\", \"\wdkiso\WDK\headers.msi\", \"/q\", \"/norestart\", \"TARGETDIR=C:\wdk\") -Wait; \
    Start-Process -FilePath $Env:SystemRoot\system32\msiexec.exe -ArgumentList (\"/a\", \"\wdkiso\WDK\libs_x86fre.msi\", \"/q\", \"/norestart\", \"TARGETDIR=C:\wdk\") -Wait; \
    Start-Process -FilePath $Env:SystemRoot\system32\msiexec.exe -ArgumentList (\"/a\", \"\wdkiso\WDK\libs_x64fre.msi\", \"/q\", \"/norestart\", \"TARGETDIR=C:\wdk\") -Wait; \
    Start-Process -FilePath $Env:SystemRoot\system32\msiexec.exe -ArgumentList (\"/a\", \"\wdkiso\WDK\wcoinstallers.msi\", \"/q\", \"/norestart\", \"TARGETDIR=C:\wdk\") -Wait; \
    Start-Process -FilePath $Env:SystemRoot\system32\msiexec.exe -ArgumentList (\"/a\", \"\wdkiso\WDK\wxplibs_x86fre.msi\", \"/q\", \"/norestart\", \"TARGETDIR=C:\wdk\") -Wait; \
    Start-Process -FilePath $Env:SystemRoot\system32\msiexec.exe -ArgumentList (\"/a\", \"\wdkiso\WDK\wnetlibs_x64fre.msi\", \"/q\", \"/norestart\", \"TARGETDIR=C:\wdk\") -Wait; \
    New-Item -Type Directory -Path C:\WinDDK; \
    Move-Item -Path C:\wdk\WinDDK\7600.16385.win7_wdk.100208-1538 -Destination C:\WinDDK\7600.16385.1; \
    Copy-Item -Path C:\wdk\WinDDK\7600.16385.win7_wdk.100210\* -Destination C:\WinDDK\7600.16385.1 -Recurse -Force; \
    Remove-Item -Path C:\wdk -Recurse; \
    Remove-Item -Path C:\wdkiso -Recurse; \
    Remove-Item -Path GRMWDK_EN_7600_1.ISO

# Download and install MinGit compiled with Busybox.
# This is the most container-compatible version of Git for Windows, all others failed for me. See also https://github.com/git-for-windows/git/issues/1403#issuecomment-355429601
RUN $ProgressPreference = 'SilentlyContinue'; \
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    Invoke-WebRequest https://github.com/git-for-windows/git/releases/download/v2.21.0.windows.1/MinGit-2.21.0-busybox-64-bit.zip -OutFile git.zip; \
    Expand-Archive git.zip -DestinationPath C:\git; \
    [System.Environment]::SetEnvironmentVariable(\"Path\", [System.Environment]::GetEnvironmentVariable(\"Path\", \"Machine\") + \";C:\git\cmd\", \"Machine\"); \
    Remove-Item git.zip
