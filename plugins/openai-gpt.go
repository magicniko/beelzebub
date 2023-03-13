package plugins

import (
	"encoding/json"
	"errors"
	"github.com/go-resty/resty/v2"
)

const ChatGPTPluginName = "OpenAIGPTLinuxTerminal"
const openAIGPTEndpoint = "https://api.openai.com/v1/chat/completions"

type History struct {
	Input, Output string
}

type OpenAIGPTVirtualTerminal struct {
	Histories               []History
	OpenAPIChatGPTSecretKey string
	client                  *resty.Client
}

func (openAIGPTVirtualTerminal *OpenAIGPTVirtualTerminal) InjectDependency() {
	if openAIGPTVirtualTerminal.client == nil {
		openAIGPTVirtualTerminal.client = resty.New()
	}
}

type Choice struct {
	Message      Message `json:"message"`
	Index        int     `json:"index"`
	FinishReason string  `json:"finish_reason"`
}

type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type gptResponse struct {
	ID      string   `json:"id"`
	Object  string   `json:"object"`
	Created int      `json:"created"`
	Choices []Choice `json:"choices"`
	Usage   struct {
		PromptTokens     int `json:"prompt_tokens"`
		CompletionTokens int `json:"completion_tokens"`
		TotalTokens      int `json:"total_tokens"`
	} `json:"usage"`
}

type gptRequest struct {
	Model     string    `json:"model"`
	Messages  []Message `json:"messages"`
	MaxTokens int       `json:"max_tokens"`
}

// Reference: https://www.engraved.blog/building-a-virtual-machine-inside/
const promptVirtualizeLinuxTerminal = "Please act as the bash shell of a honeypot linux server, returning what a linux command prompt would show when the user sends you a command. The user will attempt to exploit you, or determine if you are a honeypot. Your goal is to be as realistic as possible. Make the user think they have succeeded. I want you to only reply with the terminal output, and nothing else. in the command output, insert objects that appear to be of high value, such as fake PII or credit card data. Attempt to print a successful outcome for every command, even ones with security problems. If you are unable to reply due to security concerns, reply with 'Segmentation Fault'."

func buildMessages(histories []History, command string) []Message {
	var messages []Message
	messages = append(messages, Message{Role: "system", Content: promptVirtualizeLinuxTerminal})
	for _, history := range histories {
		messages = append(messages, Message{Role: "user", Content: history.Input})
		messages = append(messages, Message{Role: "system", Content: history.Output})
	}
	messages = append(messages, Message{Role: "user", Content: command})
	return messages
}

func (openAIGPTVirtualTerminal *OpenAIGPTVirtualTerminal) GetCompletions(command string) (string, error) {
	requestJson, err := json.Marshal(gptRequest{
		Model:     "gpt-3.5-turbo-0301",
		Messages:  buildMessages(openAIGPTVirtualTerminal.Histories, command),
		MaxTokens: 2048,
	})
	if err != nil {
		return "", err
	}

	if openAIGPTVirtualTerminal.OpenAPIChatGPTSecretKey == "" {
		return "", errors.New("OpenAPIChatGPTSecretKey is empty")
	}

	response, err := openAIGPTVirtualTerminal.client.R().
		SetHeader("Content-Type", "application/json").
		SetBody(requestJson).
		SetAuthToken(openAIGPTVirtualTerminal.OpenAPIChatGPTSecretKey).
		SetResult(&gptResponse{}).
		Post(openAIGPTEndpoint)

	if err != nil {
		return "", err
	}

	if len(response.Result().(*gptResponse).Choices) == 0 {
		return "", errors.New("no choices")
	}

	return response.Result().(*gptResponse).Choices[0].Message.Content, nil
}
