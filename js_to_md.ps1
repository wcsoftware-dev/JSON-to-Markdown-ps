function Convert-JsonToMarkdownList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Json
    )

    begin {
        function Write-Md {
            param(
                [object]$Node,
                [int]$Level = 0,
                [string]$Key = $null,
                [System.Collections.Generic.List[string]]$Lines
            )

            $indent = '  ' * $Level
            $bullet = '- '

            if ($Node -is [System.Management.Automation.PSCustomObject]) {
                # JSON object → iterate properties
                if ($Key) {
                    $Lines.Add("$indent$bullet**$Key:**")
                    $Level++
                    $indent = '  ' * $Level
                }

                foreach ($prop in $Node.PSObject.Properties) {
                    $name  = $prop.Name
                    $value = $prop.Value

                    if ($null -eq $value) {
                        $Lines.Add("$indent$bullet**$name:** null")
                    }
                    elseif ($value -is [System.Management.Automation.PSCustomObject] -or
                            $value -is [System.Collections.IEnumerable] -and
                            -not ($value -is [string])) {
                        # Nested object/array
                        Write-Md -Node $value -Level ($Level) -Key $name -Lines $Lines
                    }
                    else {
                        $Lines.Add("$indent$bullet**$name:** $value")
                    }
                }
            }
            elseif ($Node -is [System.Collections.IEnumerable] -and -not ($Node -is [string])) {
                # JSON array
                if ($Key) {
                    $Lines.Add("$indent$bullet**$Key:**")
                    $Level++
                    $indent = '  ' * $Level
                }

                foreach ($item in $Node) {
                    if ($item -is [System.Management.Automation.PSCustomObject] -or
                        ($item -is [System.Collections.IEnumerable] -and -not ($item -is [string]))) {
                        Write-Md -Node $item -Level $Level -Lines $Lines
                    }
                    else {
                        $Lines.Add("$indent$bullet$item")
                    }
                }
            }
            else {
                # Primitive value with optional key
                if ($Key) {
                    $Lines.Add("$indent$bullet**$Key:** $Node")
                }
                else {
                    $Lines.Add("$indent$bullet$Node")
                }
            }
        }
    }

    process {
        $obj = $Json | ConvertFrom-Json
        $lines = [System.Collections.Generic.List[string]]::new()
        Write-Md -Node $obj -Lines $lines
        $lines -join "`n"
    }
}
