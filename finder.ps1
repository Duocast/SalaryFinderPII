# Load iTextSharp DLL
Add-Type -Path ".\itextsharp.dll"

# Load OpenXml SDK
Add-Type -AssemblyName DocumentFormat.OpenXml

function Get-PDFText {
    param (
        [string]$FilePath
    )

    $reader = New-Object iTextSharp.text.pdf.parser.SimpleTextExtractionStrategy
    $pdf = New-Object iTextSharp.text.pdf.PdfReader($FilePath)

    $text = ''
    for ($page = 1; $page -le $pdf.NumberOfPages; $page++) {
        $text += [iTextSharp.text.pdf.parser.PdfTextExtractor]::GetTextFromPage($pdf, $page, $reader)
    }

    $pdf.Close()
    return $text
}

function Get-DOCXText {
    param (
        [string]$FilePath
    )

    $wordDoc = [DocumentFormat.OpenXml.Packaging.WordprocessingDocument]::Open($FilePath, $false)
    $text = -join ($wordDoc.MainDocumentPart.Document.InnerText)
    $wordDoc.Close()
    return $text
}

function Get-XLSXText {
    param (
        [string]$FilePath
    )

    $excelContent = Import-Excel -Path $FilePath
    $text = -join ($excelContent | Out-String)
    return $text
}

function Contains-SalaryInfo {
    param (
        [string]$FilePath
    )

    $salaryPattern = '(?i)(\$|€|£)?\s*\d{1,3}(?:,\d{3})*(?:\.\d{2})?\s*(?:salary|salaries|wage|wages)|(?:salary|salaries|wage|wages)\s*\d{1,3}(?:,\d{3})*(?:\.\d{2})?\s*(\$|€|£)?'

    if ($FilePath.EndsWith('.pdf')) {
        $fileContent = Get-PDFText -FilePath $FilePath
    } elseif ($FilePath.EndsWith('.docx')) {
        $fileContent = Get-DOCXText -FilePath $FilePath
    } elseif ($FilePath.EndsWith('.xlsx')) {
        $fileContent = Get-XLSXText -FilePath $FilePath
    } else {
        $fileContent = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    }

    if ($fileContent -match $salaryPattern) {
        return $true
    }
    return $false
}

function Find-SalaryFiles {
    param (
        [string]$Directory
    )

    $salaryFiles = @()

    Get-ChildItem -Path $Directory -Recurse -File | ForEach-Object {
        if (Contains-SalaryInfo -FilePath $_.FullName) {
            $salaryFiles += $_.FullName
        }
    }

    return $salaryFiles
}

$directory = Read-Host "Enter the directory to search for salary files"
if (Test-Path -Path $directory -PathType Container) {
    $salaryFiles = Find-SalaryFiles -Directory $directory
    if ($salaryFiles.Count -gt 0) {
        Write-Host "Salary files found:"
        $salaryFiles | ForEach-Object {
            Write-Host "- $_"
        }
    } else {
        Write-Host "No salary files found."
    }
} else {
    Write-Host "Invalid directory."
}

