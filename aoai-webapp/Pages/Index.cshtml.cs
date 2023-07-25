using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

using Azure;
using Azure.AI.OpenAI;

namespace aoai_webapp.Pages;

public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;
    private readonly OpenAIClient _aoaiclient;
    private readonly IConfiguration _config;
    private readonly string _modelDeploy;

    public IndexModel(ILogger<IndexModel> logger, OpenAIClient aoaiclient, IConfiguration config)
    {
        _logger = logger;
        _aoaiclient = aoaiclient;
        _config = config;
        _modelDeploy = config["AOAI:ModelDeployment"] ?? string.Empty;
    }

    public void OnGet()
    {
    }
}
