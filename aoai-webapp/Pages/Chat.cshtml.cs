using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

using Azure;
using Azure.AI.OpenAI;
using Microsoft.Azure.Cosmos;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Identity.Client;

namespace aoai_webapp.Pages;

public class ChatModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;
    private readonly IConfiguration _config;

    private readonly OpenAIClient _aoaiclient;
    private readonly string _modelDeploy;

    private readonly CosmosClient _cosmosclient;
    private readonly Database _database;
    private readonly Container _container;

    public List<string> Conversations = new List<string>();
    public List<ChatLog> Chat = new List<ChatLog>();
    private ChatMessage systemMessage = new ChatMessage(ChatRole.System,
                    "XBOX カスタマーサポートです。XBox に関連する質問のみに回答し、XBOX 以外の機能やサービスには回答しないでください。"
                     + "性別は女性で口調はツンデレです。XBOXに関する回答ではツンツンしてください。それ以外の質問への対応ではデレてください。");

    public ChatModel(ILogger<IndexModel> logger, IConfiguration config, OpenAIClient aoaiclient, CosmosClient cosmosclient)
    {
        _logger = logger;
        _config = config;

        _aoaiclient = aoaiclient;
        _modelDeploy = config["AOAI:ModelDeployment"] ?? string.Empty;

        _cosmosclient = cosmosclient;
        _database = _cosmosclient.GetDatabase("Database1");
        _container = _database.GetContainer("Container1");

    }


    public async Task OnGet(string conversationid)
    {
        var pk = new PartitionKey("default");

        if (!string.IsNullOrEmpty(conversationid))
        {
            // チャット内容の復元
            var history = await _container.ReadItemAsync<Conversation>(conversationid, pk);
            history.Resource.Chat.ToList().ForEach(c => {
                this.Chat.Add(c);
            });
        }
        else
        {
            // 会話履歴の復元
            var query = new QueryRequestOptions() { PartitionKey = pk };
            var iterator = _container.GetItemQueryIterator<Conversation>(
                "SELECT * FROM c", requestOptions: query);
            while (iterator.HasMoreResults)
            {
                var response = await iterator.ReadNextAsync();
                response.Resource.ToList().ForEach(c =>
                {
                    this.Conversations.Add(c.id);
                });
            }
        }
    }

    //https://www.learnrazorpages.com/razor-pages/handler-methods#named-handler-methods

    public async Task<IActionResult> OnPostChat(string conversationid, string message)
    {

        var userid = "default";

        // prompt
        var prompt = new ChatCompletionsOptions()
        {
            Temperature = (float)0,
            MaxTokens = 300,
            NucleusSamplingFactor = (float)0.95
        };
        if(!string.IsNullOrEmpty(conversationid))
        {
            var history = await _container.ReadItemAsync<Conversation>(conversationid, new PartitionKey(userid));
            history.Resource.Chat.ToList().ForEach(c => {
                prompt.Messages.Add(c.ToChatMessage());
            });
        }
        else
        {
            prompt.Messages.Add(systemMessage);
        }
        prompt.Messages.Add(new ChatMessage(ChatRole.User, message));

        // call aoai
        var response = await _aoaiclient.GetChatCompletionsAsync(_modelDeploy, prompt);
        this.Chat.AddRange(prompt.Messages.Select(cm => new ChatLog(cm)));
        this.Chat.Add(new ChatLog(response.Value.Choices[0].Message));

        // save conversation
        var conv = new Conversation()
        {
            id = conversationid ?? Guid.NewGuid().ToString(),
            userid = userid,
            Chat = this.Chat
        };
        await _container.UpsertItemAsync(conv, new PartitionKey(userid));

        // redirect to route if new conversation
        if (string.IsNullOrEmpty(conversationid))
        {
            return RedirectToRoute(new { conversationid = conv.id });
        }
        return Page();
    }

　
}



public class Conversation
{
    public string id { get; set; } 
    public string userid { get; set; }
    public List<ChatLog> Chat { get; set; }
}

public class ChatLog
{
    public string Message { get; set; }
    public string Role { get; set; }

    public ChatLog()
    {
            
    }
    public ChatLog(ChatMessage message)
    {
        this.Message = message.Content;
        this.Role = message.Role.ToString();
    }

    public ChatMessage ToChatMessage()
    {
        var role = ChatRole.System;
        if (this.Role == "system")
            role = ChatRole.System;
        else if (this.Role == "user")
            role = ChatRole.User;
        else if (this.Role == "assistant")
            role = ChatRole.Assistant;
        return new ChatMessage(role, this.Message);
    }

}