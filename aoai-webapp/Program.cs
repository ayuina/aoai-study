using Azure.AI.OpenAI;
using Azure;
using Azure.Identity;
using Microsoft.Azure.Cosmos;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();

builder.Services.AddSingleton<OpenAIClient>(
        new OpenAIClient(
            new Uri(builder.Configuration["AOAI:Endpoint"] ?? ""), 
            new DefaultAzureCredential())
);

// add cosmos client to service
builder.Services.AddSingleton<CosmosClient>(
           new CosmosClient(
               builder.Configuration["Cosmos:Endpoint"] ?? "",
               new DefaultAzureCredential())
           );


var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    //app.UseHsts();
}

//app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapRazorPages();

app.Run();
