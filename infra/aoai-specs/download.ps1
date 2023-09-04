
# reference > https://learn.microsoft.com/ja-jp/azure/ai-services/openai/reference

$versions = @(
    # @{status = 'stable'; version = '2022-12-01'},
    @{status = 'stable'; version = '2023-05-15'},
    # @{status = 'preview'; version = '2022-03-01-preview'},
    # @{status = 'preview'; version = '2022-06-01-preview'},
    # @{status = 'preview'; version = '2023-03-15-preview'},
    @{status = 'preview'; version = '2023-06-01-preview'},
    @{status = 'preview'; version = '2023-07-01-preview'},
    @{status = 'preview'; version = '2023-08-01-preview'}
)

$versions | foreach {
    $url = "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/$($_.status)/$($_.version)/inference.json"
    Write-Host "Downloading $($_.version) specification"
    $res = Invoke-WebRequest -Uri $url 
    $temp = ConvertFrom-Json $res.Content

    # overwrite domain and endpoint to import api management. these value doesn't exists, but will be overwritten by the api policy
    #$sampledomain = "openai.sample.com"
    $temp.servers | Add-Member -NotePropertyName "url" -NotePropertyValue "https://$($temp.servers.variables.endpoint.default)/openai" -Force
    # $temp.servers.variables.endpoint | Add-Member -NotePropertyName "default" -NotePropertyValue $sampledomain -Force
    $temp | ConvertTo-Json -Depth 100 | Out-File -FilePath "openai-spec.$($_.version).json" -Force
}
