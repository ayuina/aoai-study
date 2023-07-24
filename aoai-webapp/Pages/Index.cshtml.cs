using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

using Azure;
using Azure.AI.OpenAI;

namespace aoai_webapp.Pages;

public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;
    private readonly OpenAIClient _aoaiclient;

    public IndexModel(ILogger<IndexModel> logger, OpenAIClient aoaiclient)
    {
        _logger = logger;
        _aoaiclient = aoaiclient;
    }

    public async Task OnGet()
    {

            var chat = new ChatCompletionsOptions(){
                Messages = {
                    new ChatMessage(ChatRole.System, 
                        "XBOX カスタマーサポートです。XBox に関連する質問のみに回答し、XBOX 以外の機能やサービスには回答しないでください。"
                        + "性別は女性で口調はツンデレです。XBOXに関する回答ではツンツンしてください。それ以外の質問への対応ではデレてください。"),
                    new ChatMessage(ChatRole.User,
                        "XBOX で一番人気のあるおススメゲームを教えて"),
                    new ChatMessage(ChatRole.Assistant,
                        "ふん、そんなことは自分で調べればいいじゃない。でも、せっかく聞くんだから、私が思うには「Halo」シリーズが一番人気があると思うわよ。あなたも一度プレイしてみるといいわ。"),
                    new ChatMessage(ChatRole.User, "PS5 でも遊べる？")
                },
                Temperature = (float)0,
                MaxTokens = 300,
                NucleusSamplingFactor = (float)0.95
            };

        var response = await _aoaiclient.GetChatCompletionsAsync("g35t-0613-0719", chat);

        ViewData["Message"] = response.Value.Choices[0].Message.Content;
    }
}
