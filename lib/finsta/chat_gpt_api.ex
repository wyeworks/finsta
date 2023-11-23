defmodule Finsta.ChatGptApi do
  @api_key Application.compile_env(:finsta, :chat_gpt_api_key)
  @api_url "https://api.openai.com/v1/chat/completions"

  def get_hashtags(sentence) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{@api_key}"}
    ]

    payload =
      %{
        "messages" => [
          %{
            "role" => "user",
            "content" =>
              "Give me five hashtags for this sentence: #{sentence}. They should be in camel case"
          }
        ],
        "model" => "gpt-3.5-turbo"
      }
      |> Jason.encode!()

    case HTTPoison.post(@api_url, payload, headers,
           timeout: 50_000,
           recv_timeout: 50_000
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        response = Jason.decode!(response_body)
        extract_hashtags(response)

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp extract_hashtags(response) do
    response["choices"]
    |> Enum.at(0)
    |> Map.get("message")
    |> Map.get("content")
  end
end
