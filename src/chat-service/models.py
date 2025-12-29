from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class MessageType(str, Enum):
    USER = "user"
    BOT = "bot"
    AGENT = "agent"

class ChatStatus(str, Enum):
    ACTIVE = "active"
    RESOLVED = "resolved"
    ESCALATED = "escalated"

class QueryCategory(str, Enum):
    BOOKING = "booking"
    PAYMENT = "payment"
    VEHICLE = "vehicle"
    ACCOUNT = "account"
    GENERAL = "general"
    TECHNICAL = "technical"

class Message(BaseModel):
    id: Optional[str] = None
    chat_id: str
    content: str
    message_type: MessageType
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    metadata: Optional[Dict[str, Any]] = None

class ChatSession(BaseModel):
    id: Optional[str] = None
    user_id: str
    status: ChatStatus = ChatStatus.ACTIVE
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    category: Optional[QueryCategory] = None
    escalated_to_agent: bool = False
    agent_id: Optional[str] = None

class QueryIntent(BaseModel):
    category: QueryCategory
    confidence: float
    keywords: List[str]
    suggested_response: Optional[str] = None

class ChatRequest(BaseModel):
    user_id: str
    message: str
    chat_id: Optional[str] = None

class ChatResponse(BaseModel):
    chat_id: str
    response: str
    message_type: MessageType = MessageType.BOT
    category: Optional[QueryCategory] = None
    escalated: bool = False
    agent_contact_info: Optional[Dict[str, str]] = None
    suggested_actions: Optional[List[str]] = None

class AgentContact(BaseModel):
    phone_number: str
    name: str
    department: str
    available: bool = True

class EscalationRequest(BaseModel):
    chat_id: str
    user_id: str
    reason: str
    category: QueryCategory
    message_history: List[Message]
