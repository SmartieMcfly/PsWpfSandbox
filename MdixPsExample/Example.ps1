#---[ Script Vars ]---#
$MyTitle = "Example"
$MyVersion = "0.1.0"
$MyRoot = Get-Item -Path "C:\Users\smcollier\Source\GitHub\PsWpfSandbox\MdixExample"
<# Debug:
$MyRoot = Get-Item -Path $PSScriptRoot
#>

#---[ Set Paths ]---#
$ResourcePath = Join-Path -Path $MyRoot.Fullname -ChildPath "Resources"
$AssetPath    = Join-Path -Path $ResourcePath -ChildPath "Assets"
$AssemblyPath = Join-Path -Path $ResourcePath -ChildPath "Assemblies"
$FunctionPath = Join-Path -Path $ResourcePath -ChildPath "Functions"
$LayoutPath   = Join-Path -Path $ResourcePath -ChildPath "Layouts"

#---[ Load Assemblies ]---#
Add-Type -AssemblyName PresentationFramework
Add-Type -Path "$($AssemblyPath)\MaterialDesignThemes.Wpf.dll"
Add-Type -Path "$($AssemblyPath)\MaterialDesignColors.dll"
# [Void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
# [Void][System.Reflection.Assembly]::LoadFrom("$ResourcePath\MaterialDesignThemes.Wpf.dll")
# [Void][System.Reflection.Assembly]::LoadFrom("$ResourcePath\MaterialDesignColors.dll")




#---[ Theme ]---#
[System.Collections.ArrayList]$ThemePrimaryColors = [System.Enum]::GetNames([MaterialDesignColors.PrimaryColor])
$ThemePrimaryColors.Sort()
[System.Collections.ArrayList]$ThemeSecondaryColors = [System.Enum]::GetNames([MaterialDesignColors.SecondaryColor])
$ThemeSecondaryColors.Sort()

#---[ RegEx ]---#
[regex]$RegEx_Numbers           = '^[0-9]*$'
[regex]$RegEx_AlphaNumeric      = '^[a-zA-Z0-9]*$'
[regex]$RegEx_Letters           = '^[a-zA-Z]*$'
[regex]$RegEx_LettersSpace      = '^[\sa-zA-Z]*$'
[regex]$RegEx_AlphaNumericSpaceUnderscore = '^[\s_a-zA-Z0-9]*$'
[regex]$RegEx_NoteChars         = '^[\s_\"\.\-,a-zA-Z0-9]*$'
[regex]$RegEx_EmailChars        = '^[\@\.\-a-zA-Z0-9]*$'
[regex]$RegEx_EmailPattern      = '^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'
[regex]$RegEx_NumbersDash       = '^[\-0-9]*$'

#---[ Load Functions ]---#
Get-ChildItem -Path $FunctionPath -Filter *.ps1 | ForEach-Object {. ($_.FullName)}

#---[ Load Config ]---#
$ConfigFile = Join-Path -Path $ResourcePath -ChildPath "Config.xml"
$Config = Open-File -Path $ConfigFile -FileType xml

#---[ Load Layout ]---#
# $MainWindowFile = Join-Path -Path $LayoutPath -ChildPath "Example13.xaml"
$MainWindowFile = "C:\Users\smcollier\Source\OpenSource\PowerShell.MaterialDesign\Example13.xaml"
try {
    $Window = New-Window -XamlFile $MainWindowFile
} catch {
    Write-Output $_.Exception.Message
}

Set-Theme -Window $Window -PrimaryColor $Config.Parameters.Settings.Theme.PrimaryColor -SecondaryColor $Config.Parameters.Settings.Theme.SecondaryColor -ThemeMode $Config.Parameters.Settings.Theme.Mode

#---[ Component Config ]---#
$LeftDrawer_PrimaryColor_LstBox.Itemssource = $ThemePrimaryColors
$LeftDrawer_SecondaryColor_LstBox.Itemssource = $ThemeSecondaryColors
$LeftDrawer_ThemeMode_TglBtn.IsChecked = if((Get-ThemeMode -Window $Window) -eq "Dark") {$true} else {$false}

[scriptblock]$OnClosingLeftDrawer = {
    $DrawerHost.IsLeftDrawerOpen = $false
    $LeftDrawer_Open_TglBtn.IsChecked = $false
    $LeftDrawer_Open_TglBtn.Visibility="Visible"
}

$DrawerHost.add_DrawerClosing($OnClosingLeftDrawer)

$LeftDrawer_Close_TglBtn.add_Click($OnClosingLeftDrawer)

$LeftDrawer_Open_TglBtn.add_Click({
    $DrawerHost.IsLeftDrawerOpen = $true
    $LeftDrawer_Close_TglBtn.IsChecked = $true
    $LeftDrawer_Open_TglBtn.Visibility="Hidden"
})

$LeftDrawer_ThemeMode_TglBtn.Add_Click({
        $ThemeMode = if ($LeftDrawer_ThemeMode_TglBtn.IsChecked -eq $true) {"Dark"} else {"Light"}
        Set-Theme -Window $Window -ThemeMode $ThemeMode
})

$LeftDrawer_PrimaryColor_LstBox.Add_SelectionChanged( {
    if ($this.IsMouseCaptured ) {   # this condition prvents the event to be triggered when listbox selection is changed programatically
        Set-Theme -Window $Window -PrimaryColor $LeftDrawer_PrimaryColor_LstBox.SelectedValue
    }
})

$LeftDrawer_SecondaryColor_LstBox.Add_SelectionChanged( {
    if ($this.IsMouseCaptured ) {   # this condition prvents the event to be triggered when listbox selection is changed programatically
        Set-Theme -Window $Window -SecondaryColor $LeftDrawer_SecondaryColor_LstBox.SelectedValue
    }
})

$LeftDrawer_Theme_Undo_Btn.Add_Click( {
    Set-Theme -Window $Window -PrimaryColor $Config.Parameters.Settings.Theme.PrimaryColor -SecondaryColor $Config.Parameters.Settings.Theme.SecondaryColor -ThemeMode $Config.Parameters.Settings.Theme.Mode
    $LeftDrawer_ThemeMode_TglBtn.IsChecked = if((Get-ThemeMode -Window $Window) -eq "Dark") {$true} else {$false}
    $LeftDrawer_PrimaryColor_LstBox.SelectedIndex = $ThemePrimaryColors.indexof($Config.Parameters.Settings.Theme.PrimaryColor)
    $LeftDrawer_SecondaryColor_LstBox.SelectedIndex = $ThemeSecondaryColors.indexof($Config.Parameters.Settings.Theme.SecondaryColor)
})

$LeftDrawer_Theme_Apply_Btn.Add_Click( {

    $IsChanged = $false
    if (($LeftDrawer_PrimaryColor_LstBox.SelectedValue) -and $Config.Parameters.Settings.Theme.PrimaryColor -ne $LeftDrawer_PrimaryColor_LstBox.SelectedValue) {
        $IsChanged = $true
        $Config.Parameters.Settings.Theme.PrimaryColor = $LeftDrawer_PrimaryColor_LstBox.SelectedValue
    }
    if (($LeftDrawer_SecondaryColor_LstBox.SelectedValue) -and $Config.Parameters.Settings.Theme.SecondaryColor -ne $LeftDrawer_SecondaryColor_LstBox.SelectedValue) {
        $IsChanged = $true
        $Config.Parameters.Settings.Theme.SecondaryColor = $LeftDrawer_SecondaryColor_LstBox.SelectedValue
    }
    if (($Config.Parameters.Settings.Theme.Mode -eq "Light") -and ($LeftDrawer_ThemeMode_TglBtn.IsChecked)) {
        $IsChanged = $true
        $Config.Parameters.Settings.Theme.Mode = "Dark"
    }
    if (($Config.Parameters.Settings.Theme.Mode -eq "Dark") -and (!$LeftDrawer_ThemeMode_TglBtn.IsChecked)) {
        $IsChanged = $true
        $Config.Parameters.Settings.Theme.Mode = "Light"
    }
    if ($IsChanged) {
        try {
            $Config.Save($ConfigFile)
            New-Snackbar -Snackbar $MainSnackbar -Text "Theme was successfully saved"
        }
        catch {
            New-Snackbar -Snackbar $MainSnackbar -Text  $_[0] -ButtonCaption "OK"
            return
        }
    }
})

#---[ Show Window ]---#
$Window.ShowDialog() | out-null