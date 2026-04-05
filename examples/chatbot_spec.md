# AI Chatbot

An AI-powered chatbot service that can answer questions, hold conversations,
and assist users with tasks. Supports multiple AI providers and conversation history.

## Features
- Real-time chat interface
- Multiple AI provider support (any AI-provider-compatible provider)
- Conversation history and memory
- System prompt customization
- Streaming responses
- Rate limiting
- User sessions

## Pages
- Chat interface page
- Settings page (provider selection, system prompt)
- Conversation history page

## API Endpoints
- POST /chat/send
- GET /chat/history
- GET /chat/history/:id
- DELETE /chat/history/:id
- PUT /settings/provider
- GET /settings
- POST /sessions
- GET /sessions/:id
