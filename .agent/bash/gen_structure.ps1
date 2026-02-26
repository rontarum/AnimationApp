# Folders to exclude completely
$excludeFolders = @(".agent", ".git", ".godot", ".kiro", ".qoder", ".vscode", ".import", "addons", "builds")

# File extensions to INCLUDE (only these will appear)
$includeExtensions = @(".gd", ".gdshader", ".gdshaderinc", ".tscn", ".tres", ".json", ".csv")

$OutputFile = "structure.md"

function Get-Tree($Path, $Prefix) {

    $items = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue

    # Sort: folders first, then files
    $items = $items | Sort-Object { -not $_.PSIsContainer }, Name

    $count = $items.Count
    $i = 0

    foreach ($item in $items) {
        $i++
        $isLast = $i -eq $count

        # Skip excluded folders
        if ($item.PSIsContainer -and ($excludeFolders -contains $item.Name)) {
            continue
        }

        # If file — include only allowed extensions
        if (-not $item.PSIsContainer) {
            if ($includeExtensions -notcontains $item.Extension) {
                continue
            }
        }

        if ($isLast) { $marker = "+-- " } else { $marker = "|-- " }

        $line = "$Prefix$marker$($item.Name)"
        Add-Content -Path $OutputFile -Value $line -Encoding UTF8

        # Recurse into folders (even if they may end up empty)
        if ($item.PSIsContainer) {
            if ($isLast) { $newPrefix = "$Prefix    " } else { $newPrefix = "$Prefix|   " }
            Get-Tree -Path $item.FullName -Prefix $newPrefix
        }
    }
}

# ---- RUN ----

Set-Content -Path $OutputFile -Value '---' -Encoding UTF8
Add-Content -Path $OutputFile -Value "inclusion: auto" -Encoding UTF8
Add-Content -Path $OutputFile -Value "name: structure" -Encoding UTF8
Add-Content -Path $OutputFile -Value "description: Project current structure. Use this when you need to know project file-folder structure to avoid jump-finding file-to-file." -Encoding UTF8
Add-Content -Path $OutputFile -Value '---' -Encoding UTF8
Add-Content -Path $OutputFile -Value "" -Encoding UTF8
Add-Content -Path $OutputFile -Value "# Current project structure" -Encoding UTF8
Add-Content -Path $OutputFile -Value "" -Encoding UTF8
Add-Content -Path $OutputFile -Value '```' -Encoding UTF8

Write-Host "Scanning project..."
Get-Tree -Path (Get-Location) -Prefix ""

Add-Content -Path $OutputFile -Value '```' -Encoding UTF8
Write-Host "Done! structure.md updated."