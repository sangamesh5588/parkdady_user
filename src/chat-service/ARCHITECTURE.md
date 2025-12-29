# Chat System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        PARKING APP CHAT SYSTEM                   │
└─────────────────────────────────────────────────────────────────┘

┌────────────────────┐         ┌─────────────────────┐         ┌─────────────────┐
│                    │         │                     │         │                 │
│   Flutter Mobile   │────────▶│   FastAPI Backend   │────────▶│   Supabase DB   │
│       App          │◀────────│   (Python 3.11)     │◀────────│   (PostgreSQL)  │
│                    │  HTTPS  │                     │  REST   │                 │
└────────────────────┘         └─────────────────────┘         └─────────────────┘
         │                              │                              │
         │                              │                              │
         │                              ▼                              │
         │                     ┌─────────────────┐                    │
         │                     │  Redis Cache    │                    │
         │                     │  (Optional)     │                    │
         │                     └─────────────────┘                    │
         │                              │                              │
         │                              ▼                              │
         │                     ┌─────────────────┐                    │
         └────────────────────▶│  Twilio API     │                    │
                               │  (Voice Calls)  │                    │
                               └─────────────────┘                    │
                                                                       │
         ┌─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│   Log Files     │
│  (Monitoring)   │
└─────────────────┘
```

## Data Flow

### 1. User Sends Message

```
User types message in Flutter app
         │
         ▼
ChatWidget._sendMessage()
         │
         ▼
HTTP POST to /chat endpoint
         │
         ├─── Retry logic (3 attempts)
         ├─── Timeout (20s)
         └─── Error handling
         │
         ▼
Backend receives request
         │
         ▼
app.py:chat_with_bot()
         │
         ├─── 1. Get/Create chat session
         │    └─── Check Supabase first
         │         └─── Fallback to in-memory
         │
         ├─── 2. Save user message
         │    ├─── Save to Supabase
         │    └─── Save to memory
         │
         ├─── 3. Classify intent
         │    └─── SimpleChatEngine
         │         ├─── Pattern matching
         │         ├─── Keyword analysis
         │         └─── Confidence scoring
         │
         ├─── 4. Check escalation
         │    └─── should_escalate()
         │         ├─── Low confidence? (<40%)
         │         ├─── Frustrated user?
         │         ├─── Complex query?
         │         └─── Legal issue?
         │
         ├─── 5. Generate response
         │    ├─── If escalate: AgentFallbackService
         │    └─── If not: Knowledge base response
         │
         ├─── 6. Save bot response
         │    ├─── Save to Supabase
         │    └─── Save to memory
         │
         └─── 7. Return response
              └─── JSON with chat_id, response, escalated flag
```

### 2. Response Flow

```
Backend returns response
         │
         ▼
Flutter receives JSON
         │
         ▼
ChatWidget parses response
         │
         ├─── Extract chat_id (save for next message)
         ├─── Extract response text
         ├─── Check if escalated
         │    └─── Show agent contact info if yes
         └─── Check for suggested actions
         │
         ▼
Add message to UI
         │
         ├─── User message (right side, black bubble)
         └─── Bot message (left side, gray bubble)
         │
         ▼
Scroll to bottom
         │
         ▼
User sees response
```

## Components Deep Dive

### Frontend (Flutter)

```
lib/presentation/pages/profile/
├── chat_widget.dart
│   ├── ChatMessage (model)
│   │   ├── content: String
│   │   ├── isUser: bool
│   │   ├── timestamp: DateTime
│   │   └── agentName: String?
│   │
│   └── ChatWidget (stateful)
│       ├── State variables:
│       │   ├── _messages: List<ChatMessage>
│       │   ├── _chatId: String?
│       │   ├── _isTyping: bool
│       │   ├── _isLoading: bool
│       │   └── _retryCount: int
│       │
│       ├── Methods:
│       │   ├── _sendMessage() - Send with retry
│       │   ├── _showErrorMessage() - Display errors
│       │   ├── _scrollToBottom() - Auto-scroll
│       │   ├── _buildMessage() - Message bubble UI
│       │   └── _buildTypingIndicator() - Loading animation
│       │
│       └── UI Components:
│           ├── Header (Support Chat title)
│           ├── Message list (scrollable)
│           ├── Typing indicator
│           └── Input field with send button

lib/core/
└── config.dart
    ├── chatServiceUrl (environment-based)
    ├── productionChatUrl
    ├── apiTimeout
    ├── maxRetries
    └── enableLogging
```

### Backend (Python/FastAPI)

```
src/chat-service/
├── app.py (Main application)
│   ├── FastAPI initialization
│   ├── CORS middleware
│   ├── Service initialization:
│   │   ├── SimpleChatEngine
│   │   ├── AgentFallbackService
│   │   └── DatabaseService
│   │
│   ├── Endpoints:
│   │   ├── POST /chat - Main chat endpoint
│   │   ├── GET /chat/{id}/history - Get history
│   │   ├── POST /chat/{id}/escalate - Manual escalate
│   │   ├── GET /agents/available - List agents
│   │   ├── GET /health - Health check
│   │   └── POST /twilio/* - Twilio webhooks
│   │
│   └── Logging:
│       ├── File: chat_service.log
│       ├── Console: stdout
│       └── Format: timestamp - level - message
│
├── database.py (Supabase integration)
│   ├── DatabaseService class
│   ├── Methods:
│   │   ├── create_chat_session()
│   │   ├── update_chat_session()
│   │   ├── get_chat_session()
│   │   ├── save_message()
│   │   ├── get_chat_messages()
│   │   ├── get_user_chat_sessions()
│   │   └── delete_old_sessions()
│   │
│   └── Error handling & logging
│
├── chat_engine_simple.py (NLP engine)
│   ├── SimpleChatEngine class
│   ├── Knowledge base:
│   │   ├── Booking queries
│   │   ├── Payment queries
│   │   ├── Vehicle queries
│   │   ├── Account queries
│   │   ├── Technical queries
│   │   └── General queries
│   │
│   ├── classify_intent():
│   │   ├── 1. Pattern matching (regex)
│   │   ├── 2. Keyword matching
│   │   └── 3. Confidence scoring
│   │
│   └── should_escalate():
│       ├── Check confidence
│       ├── Detect frustration
│       ├── Count failed attempts
│       └── Detect legal keywords
│
├── agent_fallback.py (Escalation service)
│   ├── AgentFallbackService class
│   ├── Twilio integration
│   ├── Redis integration
│   ├── Socket.IO integration
│   │
│   ├── Methods:
│   │   ├── is_business_hours()
│   │   ├── get_available_agents()
│   │   ├── select_best_agent()
│   │   ├── initiate_agent_call()
│   │   ├── send_agent_notification()
│   │   └── handle_escalation()
│   │
│   └── Agent selection logic:
│       ├── Category-based routing
│       ├── Availability checking
│       └── Conference call creation
│
└── models.py (Data models)
    ├── MessageType: USER | BOT | AGENT
    ├── ChatStatus: ACTIVE | RESOLVED | ESCALATED
    ├── QueryCategory: BOOKING | PAYMENT | VEHICLE | ACCOUNT | TECHNICAL | GENERAL
    ├── Message model
    ├── ChatSession model
    ├── QueryIntent model
    └── ChatResponse model
```

### Database (Supabase/PostgreSQL)

```
chat_sessions table:
├── id (TEXT, PK)
├── user_id (TEXT, indexed)
├── status (TEXT) - active/resolved/escalated
├── category (TEXT) - booking/payment/vehicle/account/technical/general
├── escalated_to_agent (BOOLEAN)
├── agent_id (TEXT, nullable)
├── created_at (TIMESTAMPTZ, indexed)
└── updated_at (TIMESTAMPTZ)

chat_messages table:
├── id (TEXT, PK)
├── chat_id (TEXT, FK -> chat_sessions, indexed)
├── content (TEXT)
├── message_type (TEXT) - user/bot/agent
├── timestamp (TIMESTAMPTZ, indexed)
└── metadata (JSONB, nullable)

Indexes:
├── idx_chat_sessions_user_id
├── idx_chat_sessions_created_at
├── idx_chat_sessions_status
├── idx_chat_messages_chat_id
└── idx_chat_messages_timestamp

RLS Policies:
├── Users can view own chat sessions
├── Users can view own chat messages
├── Service role has full access
└── Anon users blocked
```

## Security Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     Security Layers                           │
└──────────────────────────────────────────────────────────────┘

Layer 1: Network Security
├── HTTPS/TLS encryption
├── Firewall rules (80, 443 only)
├── DDoS protection (Cloudflare recommended)
└── Rate limiting (nginx/Cloudflare)

Layer 2: API Security
├── CORS configuration (allowed origins only)
├── Input validation (Pydantic models)
├── SQL injection prevention (parameterized queries)
└── Error handling (no sensitive data leaked)

Layer 3: Database Security (Supabase)
├── Row Level Security (RLS) policies
├── Service role authentication
├── Connection encryption
└── Automatic backups

Layer 4: Application Security
├── Environment variables (no hardcoded secrets)
├── JWT token validation
├── Session management (Redis)
└── Logging (no sensitive data)

Layer 5: Deployment Security
├── Docker isolation
├── Non-root user in container
├── Read-only filesystem where possible
└── Health check monitoring
```

## Deployment Architecture

### Development

```
Developer Machine
├── Python 3.11 venv
├── Supabase (dev project)
├── Redis (optional, local)
└── Port 8000 (localhost)

Flutter App
└── localhost:8000
```

### Production (Docker)

```
Server (VPS/Cloud)
├── Docker Engine
│   ├── chat-service container
│   │   ├── Python 3.11
│   │   ├── FastAPI app
│   │   ├── 4 workers (uvicorn)
│   │   └── Port 8000 (internal)
│   │
│   └── Redis container
│       ├── Redis 7
│       ├── Port 6379 (internal)
│       └── Persistent volume
│
├── Nginx (reverse proxy)
│   ├── SSL termination
│   ├── Port 80 → 443 redirect
│   ├── Port 443 → localhost:8000
│   └── Static file serving
│
└── Let's Encrypt (SSL)
    └── Auto-renewal

External Services
├── Supabase (production project)
├── Twilio (optional)
└── Uptime monitoring
```

## Scaling Strategy

### Vertical Scaling (Single Server)
```
Current: 1GB RAM, 1 CPU
    ↓
Upgrade: 2GB RAM, 2 CPUs
    ↓
Upgrade: 4GB RAM, 4 CPUs
    ↓
Limit: ~8GB RAM, 8 CPUs
```

### Horizontal Scaling (Multiple Servers)
```
                    Load Balancer (nginx)
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
    Server 1           Server 2           Server 3
    (chat-service)     (chat-service)     (chat-service)
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                           ▼
                    Shared Services
                    ├── Supabase (shared DB)
                    ├── Redis (shared cache)
                    └── Twilio (shared API)
```

## Monitoring & Observability

```
Logs
├── Application logs (chat_service.log)
│   ├── INFO: Normal operations
│   ├── WARNING: Non-critical issues
│   └── ERROR: Errors with stack traces
│
├── Docker logs (docker-compose logs)
│   ├── Container stdout/stderr
│   └── Health check results
│
└── Nginx logs (access.log, error.log)
    ├── Request logs
    └── Proxy errors

Metrics
├── Health endpoint (/health)
│   ├── Service status
│   ├── Database connection
│   └── Business hours flag
│
├── Supabase Dashboard
│   ├── Table sizes
│   ├── Query performance
│   └── API usage
│
└── Uptime monitoring (external)
    ├── Endpoint availability
    ├── Response time
    └── Alert on downtime

Alerting
├── UptimeRobot/Pingdom
│   └── Email/SMS on downtime
│
├── Supabase alerts
│   └── Database errors
│
└── Log monitoring
    └── ERROR pattern detection
```

## Error Handling Flow

```
Error occurs
    │
    ├─── Network error (ClientException)
    │    └─── Retry with exponential backoff
    │         ├─── Attempt 1 (immediate)
    │         ├─── Attempt 2 (+2s delay)
    │         ├─── Attempt 3 (+4s delay)
    │         └─── Show error to user
    │
    ├─── Server error (5xx)
    │    └─── Retry if attempts remaining
    │         └─── Show error to user
    │
    ├─── Client error (4xx)
    │    └─── Log and show error to user
    │         └─── No retry
    │
    ├─── Database error
    │    └─── Fallback to in-memory storage
    │         └─── Log warning
    │
    └─── Unexpected error
         └─── Log with stack trace
              └─── Generic error to user
```

---

This architecture supports:
- ✅ **High availability** - Multiple fallback layers
- ✅ **Scalability** - Horizontal & vertical scaling
- ✅ **Security** - Multiple security layers
- ✅ **Observability** - Comprehensive logging & monitoring
- ✅ **Maintainability** - Clear separation of concerns
- ✅ **Performance** - Caching, indexing, efficient queries
