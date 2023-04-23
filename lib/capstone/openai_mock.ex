defmodule MyApp.OpenAIMock do
  def create_chat_completion(_messages, _model) do
    {:ok,
     %{
       choices: [
         %{
           message: %{
             role: "assistant",
             content: "This is a mock response."
           }
         }
       ],
       usage: %{
         total_tokens: 10
       }
     }}
  end
end
