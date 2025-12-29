from fastapi import FastAPI, HTTPException, BackgroundTasks, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
import uvicorn
import uuid
from typing import Optional
import os
from dotenv import load_dotenv
import logging
from datetime import datetime, timezone

from models import ChatRequest, ChatResponse, Message, MessageType, ChatSession, QueryCategory, EscalationRequest
from chat_engine_simple import SimpleChatEngine
from agent_fallback import AgentFallbackService
from database import DatabaseService

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('chat_service.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Parking Chat Service",
    description="AI-powered chat service for parking app support",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
chat_engine = SimpleChatEngine()
agent_service = AgentFallbackService()
db_service = DatabaseService()

# In-memory storage (fallback if database is not available)
chat_sessions = {}
chat_messages = {}

logger.info("Chat service initialized")
logger.info(f"Database connected: {db_service.is_connected()}")

@app.get("/", response_class=HTMLResponse)
async def root():
    return """
    <html>
        <head>
            <title>Parking Chat Service</title>
        </head>
        <body>
            <h1>Parking Chat Service</h1>
            <p>AI-powered customer support for parking applications</p>
            <p><a href="/docs">API Documentation</a></p>
        </body>
    </html>
    """

@app.post("/chat", response_model=ChatResponse)
async def chat_with_bot(request: ChatRequest, background_tasks: BackgroundTasks):
    """Main chat endpoint for user queries"""
    try:
        logger.info(f"Chat request from user {request.user_id}: {request.message[:50]}...")

        # Get or create chat session
        chat_id = request.chat_id or str(uuid.uuid4())

        # Try to get from database first
        session = None
        if db_service.is_connected() and request.chat_id:
            session = await db_service.get_chat_session(chat_id)

        # Fallback to in-memory or create new
        if not session:
            if chat_id not in chat_sessions:
                session = ChatSession(
                    id=chat_id,
                    user_id=request.user_id,
                    category=None,
                    escalated_to_agent=False
                )
                chat_sessions[chat_id] = session
                chat_messages[chat_id] = []

                # Save to database
                if db_service.is_connected():
                    await db_service.create_chat_session(session)
                    logger.info(f"Created new chat session: {chat_id}")
            else:
                session = chat_sessions[chat_id]

        # Add user message to history
        user_message = Message(
            id=str(uuid.uuid4()),
            chat_id=chat_id,
            content=request.message,
            message_type=MessageType.USER
        )

        # Save to database and memory
        if db_service.is_connected():
            await db_service.save_message(user_message)

        if chat_id not in chat_messages:
            chat_messages[chat_id] = []
        chat_messages[chat_id].append(user_message)

        # Get conversation history for context
        conversation_history = [msg.content for msg in chat_messages[chat_id][-10:]]  # Last 10 messages

        # Classify user intent
        intent = chat_engine.classify_intent(request.message)

        # Check if should escalate to agent
        should_escalate, escalation_reason = chat_engine.should_escalate(
            request.message,
            intent,
            conversation_history
        )

        response_content = ""
        escalated = False
        agent_contact_info = None
        suggested_actions = None

        if should_escalate and not session.escalated_to_agent:
            # Handle escalation
            escalation_request = EscalationRequest(
                chat_id=chat_id,
                user_id=request.user_id,
                reason=escalation_reason,
                category=intent.category,
                message_history=chat_messages[chat_id]
            )

            escalation_result = await agent_service.handle_escalation(escalation_request)

            if escalation_result['escalated']:
                session.escalated_to_agent = True
                session.status = "escalated"
                response_content = escalation_result['message']
                escalated = True

                if 'agent_info' in escalation_result:
                    agent_contact_info = {
                        'name': escalation_result['agent_info']['name'],
                        'department': escalation_result['agent_info']['department'],
                        'estimated_wait': escalation_result['agent_info']['estimated_wait']
                    }

                if 'suggested_actions' in escalation_result:
                    suggested_actions = escalation_result['suggested_actions']
            else:
                # Fallback response if escalation fails
                response_content = escalation_result.get('message', intent.suggested_response or "I apologize, but I'm unable to assist with this right now. Please contact our support team directly.")

        else:
            # Handle with bot
            if intent.suggested_response:
                response_content = intent.suggested_response
            else:
                # Generate contextual response based on category
                response_content = _generate_contextual_response(intent.category, request.message)

        # Update session category if not set
        if not session.category and intent.category != QueryCategory.GENERAL:
            session.category = intent.category

            # Update in database
            if db_service.is_connected():
                await db_service.update_chat_session(session)

        # Add bot response to history
        bot_message = Message(
            id=str(uuid.uuid4()),
            chat_id=chat_id,
            content=response_content,
            message_type=MessageType.BOT if not escalated else MessageType.AGENT
        )

        # Save to database and memory
        if db_service.is_connected():
            await db_service.save_message(bot_message)

        chat_messages[chat_id].append(bot_message)

        logger.info(f"Response sent to {request.user_id}: escalated={escalated}, category={intent.category.value}")

        # Prepare response
        chat_response = ChatResponse(
            chat_id=chat_id,
            response=response_content,
            category=intent.category,
            escalated=escalated,
            agent_contact_info=agent_contact_info,
            suggested_actions=suggested_actions
        )

        return chat_response

    except Exception as e:
        logger.error(f"Chat error for user {request.user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error. Please try again.")

@app.get("/chat/{chat_id}/history")
async def get_chat_history(chat_id: str):
    """Get chat message history"""
    try:
        # Try to get from database first
        if db_service.is_connected():
            messages = await db_service.get_chat_messages(chat_id)
            if messages:
                logger.info(f"Retrieved {len(messages)} messages for chat {chat_id} from database")
                return {
                    "chat_id": chat_id,
                    "messages": [
                        {
                            "id": msg.id,
                            "content": msg.content,
                            "message_type": msg.message_type.value,
                            "timestamp": msg.timestamp.isoformat()
                        }
                        for msg in messages
                    ]
                }

        # Fallback to in-memory
        if chat_id not in chat_messages:
            logger.warning(f"Chat session {chat_id} not found")
            raise HTTPException(status_code=404, detail="Chat session not found")

        logger.info(f"Retrieved {len(chat_messages[chat_id])} messages for chat {chat_id} from memory")
        return {
            "chat_id": chat_id,
            "messages": [
                {
                    "id": msg.id,
                    "content": msg.content,
                    "message_type": msg.message_type.value,
                    "timestamp": msg.timestamp.isoformat()
                }
                for msg in chat_messages[chat_id]
            ]
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving chat history for {chat_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Error retrieving chat history")

@app.post("/chat/{chat_id}/escalate")
async def manually_escalate_chat(chat_id: str, request: Request):
    """Manually escalate a chat to human agent"""
    if chat_id not in chat_sessions:
        raise HTTPException(status_code=404, detail="Chat session not found")

    session = chat_sessions[chat_id]

    if session.escalated_to_agent:
        return {"message": "Chat already escalated", "escalated": True}

    # Get last few messages for context
    recent_messages = chat_messages[chat_id][-5:] if chat_id in chat_messages else []

    escalation_request = EscalationRequest(
        chat_id=chat_id,
        user_id=session.user_id,
        reason="Manual escalation requested",
        category=session.category or QueryCategory.GENERAL,
        message_history=recent_messages
    )

    result = await agent_service.handle_escalation(escalation_request)

    if result['escalated']:
        session.escalated_to_agent = True
        session.status = "escalated"

    return result

@app.get("/agents/available")
async def get_available_agents(department: Optional[str] = None):
    """Get list of available agents"""
    agents = agent_service.get_available_agents(department)
    return {
        "agents": [
            {
                "name": agent.name,
                "department": agent.department,
                "phone_number": agent.phone_number,
                "available": agent.available
            }
            for agent in agents
        ]
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    database_status = "connected" if db_service.is_connected() else "disconnected"

    health_status = {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "services": {
            "chat_engine": "operational",
            "agent_service": "operational",
            "database": database_status,
            "business_hours": agent_service.is_business_hours()
        }
    }

    logger.debug(f"Health check: {health_status}")
    return health_status

def _generate_contextual_response(category: QueryCategory, user_message: str) -> str:
    """Generate contextual response based on category"""
    responses = {
        QueryCategory.BOOKING: [
            "I can help you with booking-related questions. Could you please provide more details about what you need assistance with?",
            "For booking inquiries, I can assist with reservations, cancellations, and modifications. What specific booking issue are you facing?",
            "Let me help you with your parking booking. Are you looking to make a new reservation, modify an existing one, or cancel a booking?"
        ],
        QueryCategory.PAYMENT: [
            "I can assist with payment and billing questions. What specific payment issue are you experiencing?",
            "For payment-related concerns, I can help with refunds, billing disputes, and payment methods. Please describe your issue.",
            "Payment support is available. Are you having trouble with a transaction, need a refund, or have questions about billing?"
        ],
        QueryCategory.VEHICLE: [
            "I can help with vehicle registration and management. What would you like to know about adding or managing your vehicles?",
            "For vehicle-related questions, I can assist with registration, updates, and vehicle requirements. How can I help?",
            "Vehicle management support is available. Are you looking to add a new vehicle, update information, or check requirements?"
        ],
        QueryCategory.ACCOUNT: [
            "I can assist with account and profile related questions. What account issue are you experiencing?",
            "For account support, I can help with login issues, profile updates, and account settings. Please describe your concern.",
            "Account management assistance is available. Are you having trouble logging in, updating your profile, or managing your account?"
        ],
        QueryCategory.TECHNICAL: [
            "I can help troubleshoot technical issues. Please describe the problem you're experiencing with the app.",
            "Technical support is available for app crashes, login issues, and other technical problems. What seems to be the issue?",
            "For technical difficulties, I can provide guidance on common issues. Please tell me more about what's happening."
        ],
        QueryCategory.GENERAL: [
            "I'm here to help! Could you please tell me what you need assistance with today?",
            "How can I assist you with your parking app experience?",
            "I'm ready to help. What questions do you have about our parking services?"
        ]
    }

    import random
    category_responses = responses.get(category, responses[QueryCategory.GENERAL])
    return random.choice(category_responses)

# Twilio webhook endpoints for call handling
@app.post("/twilio/connect_agent/{conference_name}")
async def connect_agent_to_conference(conference_name: str):
    """Connect agent to conference call"""
    twiml_response = f"""<?xml version="1.0" encoding="UTF-8"?>
    <Response>
        <Dial>
            <Conference>{conference_name}</Conference>
        </Dial>
    </Response>"""
    return HTMLResponse(content=twiml_response, media_type="application/xml")

@app.post("/twilio/connect_user/{conference_name}")
async def connect_user_to_conference(conference_name: str):
    """Connect user to conference call"""
    twiml_response = f"""<?xml version="1.0" encoding="UTF-8"?>
    <Response>
        <Dial>
            <Conference>{conference_name}</Conference>
        </Dial>
    </Response>"""
    return HTMLResponse(content=twiml_response, media_type="application/xml")

@app.post("/twilio/call_status")
async def handle_call_status(request: Request):
    """Handle call status updates from Twilio"""
    form_data = await request.form()
    print(f"Call status update: {dict(form_data)}")
    return {"status": "received"}

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=port,
        reload=True,
        log_level="info"
    )
