# TimeToEvent Project Export Script
# Собирает весь код проекта в один файл для анализа

# Настройки
$PROJECT_ROOT = $PWD
$OUTPUT_FILE = "timetoevent-export.txt"

# Директории с исходным кодом
$SOURCE_DIRS = @(
    "src",
    "src-tauri\src"
)

# Конфигурационные файлы (из корня и src-tauri)
$CONFIG_FILES = @(
    "package.json",
    "tsconfig.json",
    "tsconfig.node.json",
    "vite.config.ts",
    "tailwind.config.js",
    "postcss.config.js",
    "index.html",
    "README.md",
    "ARCHITECTURE.md",
    "src-tauri\Cargo.toml",
    "src-tauri\tauri.conf.json",
    "src-tauri\build.rs",
    "src-tauri\capabilities\default.json"
)

# Исключения (директории и файлы)
$EXCLUDE = @(
    "node_modules",
    "target",
    ".git",
    "dist",
    "dist-ssr",
    "build",
    ".env",
    ".env.local",
    ".env.*",
    "package-lock.json",
    "Cargo.lock",
    ".DS_Store",
    "Thumbs.db",
    "*.log",
    ".vscode",
    ".idea",
    "gen"
)

# Бинарные расширения (исключаем)
$BINARY_EXTENSIONS = @(
    ".jpg", ".jpeg", ".png", ".gif", ".webp", ".ico", ".svg",
    ".woff", ".ttf", ".eot", ".woff2",
    ".avif", ".mp4", ".mp3", ".wav", ".pdf",
    ".exe", ".dll", ".so", ".dylib",
    ".db", ".sqlite", ".sqlite3"
)

# Удаляем старый файл
if (Test-Path $OUTPUT_FILE) {
    Remove-Item $OUTPUT_FILE
}

# Заголовок
"=== TimeToEvent Project Export ===" | Out-File $OUTPUT_FILE -Encoding utf8
"Дата: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')" | Out-File $OUTPUT_FILE -Append -Encoding utf8
"Проект: TimeToEvent (Tauri V2 + Rust)" | Out-File $OUTPUT_FILE -Append -Encoding utf8
"" | Out-File $OUTPUT_FILE -Append -Encoding utf8
"=============================================" | Out-File $OUTPUT_FILE -Append -Encoding utf8

$processedCount = 0
$skippedCount = 0

# Функция для проверки исключений
function Test-Excluded {
    param($relativePath, $fileName)
    
    foreach ($ex in $EXCLUDE) {
        if ($relativePath -like "*$ex*" -or $fileName -like "*$ex*") {
            return $true
        }
    }
    return $false
}

# Функция для проверки бинарных файлов
function Test-Binary {
    param($extension)
    
    foreach ($ext in $BINARY_EXTENSIONS) {
        if ($extension -eq $ext) {
            return $true
        }
    }
    return $false
}

# Функция для обработки файла
function Process-File {
    param($file, $basePath)
    
    $relativePath = $file.FullName -replace [regex]::Escape("$basePath\"), ""
    
    # Проверка исключений
    if (Test-Excluded $relativePath $file.Name) {
        return $false
    }
    
    # Проверка бинарных файлов
    if (Test-Binary $file.Extension) {
        return $false
    }
    
    # Заголовок файла
    "" | Out-File $OUTPUT_FILE -Append -Encoding utf8
    "─────────────────────────────────────────" | Out-File $OUTPUT_FILE -Append -Encoding utf8
    "FILE: $relativePath" | Out-File $OUTPUT_FILE -Append -Encoding utf8
    "─────────────────────────────────────────" | Out-File $OUTPUT_FILE -Append -Encoding utf8
    
    # Содержимое
    try {
        Get-Content -LiteralPath $file.FullName -Encoding utf8 | Out-File $OUTPUT_FILE -Append -Encoding utf8
        return $true
    } catch {
        "ERROR: Не удалось прочитать файл" | Out-File $OUTPUT_FILE -Append -Encoding utf8
        return $false
    }
}

# Функция для построения дерева директорий
function Write-DirectoryTree {
    param(
        [string]$Path,
        [string]$Prefix = "",
        [int]$Depth = 0,
        [int]$MaxDepth = 10
    )
    
    if ($Depth -ge $MaxDepth) { return }
    
    try {
        $items = Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue | 
                 Where-Object { 
                     $name = $_.Name
                     $excluded = $false
                     foreach ($ex in $EXCLUDE) {
                         if ($name -like $ex -or $name -like "*$ex*") {
                             $excluded = $true
                             break
                         }
                     }
                     -not $excluded
                 } | Sort-Object Name
        
        $count = $items.Count
        $i = 0
        
        foreach ($item in $items) {
            $i++
            $isLast = ($i -eq $count)
            $connector = if ($isLast) { "└── " } else { "├── " }
            
            # Считаем файлы в директории
            $fileCount = (Get-ChildItem -Path $item.FullName -File -ErrorAction SilentlyContinue | 
                         Where-Object { 
                             $excluded = $false
                             foreach ($ex in $EXCLUDE) {
                                 if ($_.Name -like $ex -or $_.Name -like "*$ex*") {
                                     $excluded = $true
                                     break
                                 }
                             }
                             -not $excluded -and -not (Test-Binary $_.Extension)
                         }).Count
            
            $dirCount = (Get-ChildItem -Path $item.FullName -Directory -ErrorAction SilentlyContinue | 
                        Where-Object { 
                            $excluded = $false
                            foreach ($ex in $EXCLUDE) {
                                if ($_.Name -like $ex -or $_.Name -like "*$ex*") {
                                    $excluded = $true
                                    break
                                }
                            }
                            -not $excluded
                        }).Count
            
            $status = ""
            if ($fileCount -eq 0 -and $dirCount -eq 0) {
                $status = " [ПУСТАЯ]"
            } elseif ($fileCount -eq 0) {
                $status = " [$dirCount подпапок]"
            } else {
                $status = " [$fileCount файлов"
                if ($dirCount -gt 0) {
                    $status += ", $dirCount подпапок"
                }
                $status += "]"
            }
            
            "$Prefix$connector$($item.Name)/$status" | Out-File $OUTPUT_FILE -Append -Encoding utf8
            
            # Рекурсия в поддиректорию
            $newPrefix = if ($isLast) { "$Prefix    " } else { "$Prefix│   " }
            Write-DirectoryTree -Path $item.FullName -Prefix $newPrefix -Depth ($Depth + 1) -MaxDepth $MaxDepth
        }
    } catch {
        # Игнорируем ошибки доступа
    }
}

# Обработка исходных директорий (src/ и src-tauri/src/)
foreach ($sourceDir in $SOURCE_DIRS) {
    $fullPath = Join-Path $PROJECT_ROOT $sourceDir
    
    if (Test-Path $fullPath) {
        "" | Out-File $OUTPUT_FILE -Append -Encoding utf8
        "### ДИРЕКТОРИЯ: $sourceDir ###" | Out-File $OUTPUT_FILE -Append -Encoding utf8
        "" | Out-File $OUTPUT_FILE -Append -Encoding utf8
        
        $files = Get-ChildItem $fullPath -Recurse -File -ErrorAction SilentlyContinue
        
        foreach ($file in $files) {
            if (Process-File $file $PROJECT_ROOT) {
                $processedCount++
            } else {
                $skippedCount++
            }
        }
    } else {
        Write-Host "Предупреждение: Директория $sourceDir не найдена" -ForegroundColor Yellow
    }
}

# Обработка конфигурационных файлов
"" | Out-File $OUTPUT_FILE -Append -Encoding utf8
"### КОНФИГУРАЦИОННЫЕ ФАЙЛЫ ###" | Out-File $OUTPUT_FILE -Append -Encoding utf8
"" | Out-File $OUTPUT_FILE -Append -Encoding utf8

foreach ($configFile in $CONFIG_FILES) {
    $fullPath = Join-Path $PROJECT_ROOT $configFile
    
    if (Test-Path $fullPath) {
        $file = Get-Item $fullPath
        
        "" | Out-File $OUTPUT_FILE -Append -Encoding utf8
        "─────────────────────────────────────────" | Out-File $OUTPUT_FILE -Append -Encoding utf8
        "FILE: $configFile" | Out-File $OUTPUT_FILE -Append -Encoding utf8
        "─────────────────────────────────────────" | Out-File $OUTPUT_FILE -Append -Encoding utf8
        
        try {
            Get-Content -LiteralPath $file.FullName -Encoding utf8 | Out-File $OUTPUT_FILE -Append -Encoding utf8
            $processedCount++
        } catch {
            "ERROR: Не удалось прочитать файл" | Out-File $OUTPUT_FILE -Append -Encoding utf8
            $skippedCount++
        }
    }
}

# ============================================
# СТРУКТУРА ДИРЕКТОРИЙ (ДЕРЕВО)
# ============================================
"" | Out-File $OUTPUT_FILE -Append -Encoding utf8
"=============================================" | Out-File $OUTPUT_FILE -Append -Encoding utf8
"### СТРУКТУРА ПРОЕКТА ###" | Out-File $OUTPUT_FILE -Append -Encoding utf8
"=============================================" | Out-File $OUTPUT_FILE -Append -Encoding utf8
"" | Out-File $OUTPUT_FILE -Append -Encoding utf8

# Корневые директории проекта
$rootDirs = Get-ChildItem -Path $PROJECT_ROOT -Directory -ErrorAction SilentlyContinue | 
            Where-Object { 
                $name = $_.Name
                $excluded = $false
                foreach ($ex in $EXCLUDE) {
                    if ($name -like $ex -or $name -like "*$ex*") {
                        $excluded = $true
                        break
                    }
                }
                -not $excluded
            } | Sort-Object Name

$rootCount = $rootDirs.Count
$i = 0

foreach ($dir in $rootDirs) {
    $i++
    $isLast = ($i -eq $rootCount)
    $connector = if ($isLast) { "└── " } else { "├── " }
    
    # Считаем содержимое
    $fileCount = (Get-ChildItem -Path $dir.FullName -File -ErrorAction SilentlyContinue | 
                 Where-Object { 
                     $excluded = $false
                     foreach ($ex in $EXCLUDE) {
                         if ($_.Name -like $ex -or $_.Name -like "*$ex*") {
                             $excluded = $true
                             break
                         }
                     }
                     -not $excluded -and -not (Test-Binary $_.Extension)
                 }).Count
    
    $dirCount = (Get-ChildItem -Path $dir.FullName -Directory -ErrorAction SilentlyContinue | 
                Where-Object { 
                    $excluded = $false
                    foreach ($ex in $EXCLUDE) {
                        if ($_.Name -like $ex -or $_.Name -like "*$ex*") {
                            $excluded = $true
                            break
                        }
                    }
                    -not $excluded
                }).Count
    
    $status = ""
    if ($fileCount -eq 0 -and $dirCount -eq 0) {
        $status = " [ПУСТАЯ]"
    } elseif ($fileCount -eq 0) {
        $status = " [$dirCount подпапок]"
    } else {
        $status = " [$fileCount файлов"
        if ($dirCount -gt 0) {
            $status += ", $dirCount подпапок"
        }
        $status += "]"
    }
    
    "$connector$($dir.Name)/$status" | Out-File $OUTPUT_FILE -Append -Encoding utf8
    
    # Рекурсия в поддиректорию
    $newPrefix = if ($isLast) { "    " } else { "│   " }
    Write-DirectoryTree -Path $dir.FullName -Prefix $newPrefix -Depth 1 -MaxDepth 5
}

# Также показываем корневые файлы
$rootFiles = Get-ChildItem -Path $PROJECT_ROOT -File -ErrorAction SilentlyContinue | 
             Where-Object { 
                 $excluded = $false
                 foreach ($ex in $EXCLUDE) {
                     if ($_.Name -like $ex -or $_.Name -like "*$ex*") {
                         $excluded = $true
                         break
                     }
                 }
                 -not $excluded -and -not (Test-Binary $_.Extension)
             } | Sort-Object Name

if ($rootFiles.Count -gt 0) {
    "" | Out-File $OUTPUT_FILE -Append -Encoding utf8
    "# Корневые файлы:" | Out-File $OUTPUT_FILE -Append -Encoding utf8
    foreach ($file in $rootFiles) {
        "├── $($file.Name)" | Out-File $OUTPUT_FILE -Append -Encoding utf8
    }
}

# Итоговая статистика
"" | Out-File $OUTPUT_FILE -Append -Encoding utf8
"=============================================" | Out-File $OUTPUT_FILE -Append -Encoding utf8
"Обработано файлов: $processedCount" | Out-File $OUTPUT_FILE -Append -Encoding utf8
"Пропущено файлов: $skippedCount" | Out-File $OUTPUT_FILE -Append -Encoding utf8
"Размер экспорта: $((Get-Item $OUTPUT_FILE).Length) байт" | Out-File $OUTPUT_FILE -Append -Encoding utf8

Write-Host ""
Write-Host "✓ Готово! Результат: $OUTPUT_FILE" -ForegroundColor Green
Write-Host "✓ Обработано: $processedCount файлов" -ForegroundColor Cyan
Write-Host "⚠ Пропущено: $skippedCount файлов" -ForegroundColor Yellow
Write-Host "📦 Размер: $((Get-Item $OUTPUT_FILE).Length) байт" -ForegroundColor Cyan
Write-Host ""