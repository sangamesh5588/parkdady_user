# Parking App Chat Service - Production-Ready Setup

AI-powered customer support chat service for the parking application with intelligent escalation to human agents, database persistence, and production-grade error handling.

## 🚀 Features

- ✅ **AI-Powered Chat Engine**: Pattern matching + TF-IDF classification
- ✅ **Supabase Database Integration**: Persistent chat history and sessions
- ✅ **Automatic Agent Escalation**: Intelligent escalation based on confidence & context
- ✅ **Production Error Handling**: Comprehensive logging and error recovery
- ✅ **Retry Logic**: Exponential backoff for network failures
- ✅ **Docker Support**: Containerized deployment with docker-compose
- ✅ **Health Monitoring**: Health check endpoints for uptime monitoring
- ✅ **Twilio Integration**: Optional voice call escalation
- ✅ **Redis Support**: Optional session management and caching
- ✅ **Row Level Security**: Secure data access with Supabase RLS policies

## Architecture

```
┌─────────────────┐    HTTP/WebSocket    ┌─────────────────┐
│   Flutter App   │◄──────────────────► │  FastAPI Server  │
│                 │                     │                 │
│ - Chat Widget   │                     │ - Chat Engine   │
│ - User Interface│                     │ - Agent Service │
│ - Message UI    │                     │ - Session Mgmt  │
└─────────────────┘                     └─────────────────┘
                                              │
                                              ▼
                                   ┌─────────────────┐
                                   │   External APIs │
                                   │                 │
                                   │ - Twilio Calls │
                                   │ - Redis Cache  │
                                   │ - Supabase DB  │
                                   └─────────────────┘
```

## Setup Instructions

### Prerequisites

- Python 3.11+ **(Required)**
- Supabase Account **(Required for production)**
- Redis (optional, for agent escalation)
- Twilio account (optional, for voice calls)
- Docker (optional, for containerized deployment)

### Installation

1. **Clone and navigate to the chat service directory:**
   ```bash
   cd src/chat-service
   ```

2. **Create virtual environment:**
   ```bash
   python -m venv venv

   # Windows
   venv\Scripts\activate

   # Linux/Mac
   source venv/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Download NLTK data:**
   ```bash
   python -m nltk.downloader punkt stopwords
   ```

5. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your actual configuration
   ```

   **Required variables:**
   ```bash
   # Supabase (REQUIRED for production)
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

   # Server
   PORT=8000
   BASE_URL=http://localhost:8000
   ```

6. **Set up Supabase database:**
   - Go to your Supabase project > SQL Editor
   - Copy and paste the contents of `schema.sql`
   - Execute the SQL to create tables and RLS policies

### Running the Service

**Development Mode:**
```bash
python app.py
```

**Production Mode:**
```bash
uvicorn app:app --host 0.0.0.0 --port 8000 --workers 4
```

The API will be available at `http://localhost:8000`

## API Endpoints

### Chat Endpoints

- `POST /chat` - Send a chat message
  ```json
  {
    "user_id": "user123",
    "message": "How do I book a parking space?",
    "chat_id": "optional_existing_chat_id"
  }
  ```

- `GET /chat/{chat_id}/history` - Get chat message history

- `POST /chat/{chat_id}/escalate` - Manually escalate to agent

### Agent Endpoints

- `GET /agents/available` - Get list of available agents

### System Endpoints

- `GET /health` - Health check
- `GET /` - Service information

### Twilio Webhooks

- `POST /twilio/connect_agent/{conference_name}` - Connect agent to call
- `POST /twilio/connect_user/{conference_name}` - Connect user to call
- `POST /twilio/call_status` - Handle call status updates

## Chat Engine Features

### Query Classification

The chat engine uses multiple AI techniques to classify user queries:

1. **Regex Pattern Matching**: Fast, rule-based classification
2. **TF-IDF Similarity**: Machine learning-based text similarity
3. **Keyword Matching**: Simple but effective keyword detection

### Supported Query Categories

- **Booking**: Reservations, cancellations, modifications
- **Payment**: Billing, refunds, payment methods
- **Vehicle**: Registration, management, requirements
- **Account**: Login, profile, settings
- **Technical**: App issues, QR codes, permissions
- **General**: Contact info, support hours

### Escalation Logic

The system automatically escalates to human agents when:

- AI confidence is below 40%
- User shows frustration (keywords: complaint, angry, frustrated)
- Complex queries requiring human judgment
- Multiple failed conversation attempts
- Legal or emergency situations

## Flutter Integration

### Chat Widget Usage

```dart
import 'chat_widget.dart';

// In your screen
void showChat() {
  final userId = user?.id ?? 'anonymous_user';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ChatWidget(userId: userId),
  );
}
```

### Configuration

Update the chat service URL in `chat_widget.dart`:

```dart
final String _chatServiceUrl = 'https://your-deployed-service.com';
```

## Deployment

### Docker Deployment

```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Environment Variables for Production

```bash
# Production settings
PORT=8000
BASE_URL=https://your-domain.com

# Redis cluster
REDIS_HOST=your-redis-cluster
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password

# Twilio production credentials
TWILIO_ACCOUNT_SID=prod_account_sid
TWILIO_AUTH_TOKEN=prod_auth_token
TWILIO_PHONE_NUMBER=+1234567890

# Agent dashboard WebSocket
AGENT_SOCKET_URL=wss://agent-dashboard.your-domain.com
```

## Monitoring & Analytics

### Chat Metrics

- Response time
- Resolution rate
- Escalation rate
- User satisfaction
- Popular query categories

### Agent Performance

- Response time
- Resolution rate
- Customer satisfaction
- Call duration

## Troubleshooting

### Common Issues

1. **NLTK Data Not Found**
   ```python
   import nltk
   nltk.download('punkt')
   nltk.download('stopwords')
   ```

2. **Redis Connection Failed**
   - Check Redis server is running
   - Verify connection credentials
   - Use fallback in-memory storage

3. **Twilio Calls Not Working**
   - Verify account credentials
   - Check phone number is verified
   - Ensure sufficient Twilio balance

### Logs

Check application logs for detailed error information:

```bash
tail -f logs/chat_service.log
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- 📧 Email: support@parkingapp.com
- 📞 Phone: +1 (555) 123-4567
