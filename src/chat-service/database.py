import os
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from models import ChatSession, Message, MessageType, ChatStatus, QueryCategory
import logging

# Optional import - Supabase
try:
    from supabase import create_client, Client
    SUPABASE_AVAILABLE = True
except ImportError:
    SUPABASE_AVAILABLE = False
    Client = None  # Type hint

logger = logging.getLogger(__name__)

class DatabaseService:
    """Service for persisting chat data to Supabase"""

    def __init__(self):
        if not SUPABASE_AVAILABLE:
            logger.warning("Supabase not installed. Using in-memory storage.")
            self.client = None
            return

        supabase_url = os.getenv('SUPABASE_URL')
        supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')  # Use service role for backend

        if not supabase_url or not supabase_key:
            logger.warning("Supabase credentials not configured. Using in-memory storage.")
            self.client = None
        else:
            try:
                self.client = create_client(supabase_url, supabase_key)
                logger.info("Supabase database connected successfully")
            except Exception as e:
                logger.error(f"Failed to connect to Supabase: {e}")
                self.client = None

    def is_connected(self) -> bool:
        """Check if database is connected"""
        return self.client is not None

    async def create_chat_session(self, session: ChatSession) -> Optional[ChatSession]:
        """Create a new chat session"""
        if not self.client:
            return None

        try:
            data = {
                'id': session.id,
                'user_id': session.user_id,
                'status': session.status.value,
                'category': session.category.value if session.category else None,
                'escalated_to_agent': session.escalated_to_agent,
                'agent_id': session.agent_id,
                'created_at': session.created_at.isoformat(),
                'updated_at': session.updated_at.isoformat()
            }

            response = self.client.table('chat_sessions').insert(data).execute()
            logger.info(f"Created chat session: {session.id}")
            return session
        except Exception as e:
            logger.error(f"Failed to create chat session: {e}")
            return None

    async def update_chat_session(self, session: ChatSession) -> Optional[ChatSession]:
        """Update an existing chat session"""
        if not self.client:
            return None

        try:
            data = {
                'status': session.status.value,
                'category': session.category.value if session.category else None,
                'escalated_to_agent': session.escalated_to_agent,
                'agent_id': session.agent_id,
                'updated_at': datetime.utcnow().isoformat()
            }

            response = self.client.table('chat_sessions').update(data).eq('id', session.id).execute()
            logger.info(f"Updated chat session: {session.id}")
            return session
        except Exception as e:
            logger.error(f"Failed to update chat session: {e}")
            return None

    async def get_chat_session(self, chat_id: str) -> Optional[ChatSession]:
        """Get a chat session by ID"""
        if not self.client:
            return None

        try:
            response = self.client.table('chat_sessions').select('*').eq('id', chat_id).single().execute()

            if response.data:
                data = response.data
                return ChatSession(
                    id=data['id'],
                    user_id=data['user_id'],
                    status=ChatStatus(data['status']),
                    category=QueryCategory(data['category']) if data.get('category') else None,
                    escalated_to_agent=data['escalated_to_agent'],
                    agent_id=data.get('agent_id'),
                    created_at=datetime.fromisoformat(data['created_at']),
                    updated_at=datetime.fromisoformat(data['updated_at'])
                )
        except Exception as e:
            logger.error(f"Failed to get chat session: {e}")
            return None

    async def save_message(self, message: Message) -> Optional[Message]:
        """Save a chat message"""
        if not self.client:
            return None

        try:
            data = {
                'id': message.id,
                'chat_id': message.chat_id,
                'content': message.content,
                'message_type': message.message_type.value,
                'timestamp': message.timestamp.isoformat(),
                'metadata': message.metadata
            }

            response = self.client.table('chat_messages').insert(data).execute()
            logger.debug(f"Saved message: {message.id}")
            return message
        except Exception as e:
            logger.error(f"Failed to save message: {e}")
            return None

    async def get_chat_messages(self, chat_id: str, limit: int = 50) -> List[Message]:
        """Get messages for a chat session"""
        if not self.client:
            return []

        try:
            response = (
                self.client.table('chat_messages')
                .select('*')
                .eq('chat_id', chat_id)
                .order('timestamp', desc=False)
                .limit(limit)
                .execute()
            )

            messages = []
            for data in response.data:
                messages.append(Message(
                    id=data['id'],
                    chat_id=data['chat_id'],
                    content=data['content'],
                    message_type=MessageType(data['message_type']),
                    timestamp=datetime.fromisoformat(data['timestamp']),
                    metadata=data.get('metadata')
                ))

            return messages
        except Exception as e:
            logger.error(f"Failed to get chat messages: {e}")
            return []

    async def get_user_chat_sessions(self, user_id: str, limit: int = 10) -> List[ChatSession]:
        """Get all chat sessions for a user"""
        if not self.client:
            return []

        try:
            response = (
                self.client.table('chat_sessions')
                .select('*')
                .eq('user_id', user_id)
                .order('created_at', desc=True)
                .limit(limit)
                .execute()
            )

            sessions = []
            for data in response.data:
                sessions.append(ChatSession(
                    id=data['id'],
                    user_id=data['user_id'],
                    status=ChatStatus(data['status']),
                    category=QueryCategory(data['category']) if data.get('category') else None,
                    escalated_to_agent=data['escalated_to_agent'],
                    agent_id=data.get('agent_id'),
                    created_at=datetime.fromisoformat(data['created_at']),
                    updated_at=datetime.fromisoformat(data['updated_at'])
                ))

            return sessions
        except Exception as e:
            logger.error(f"Failed to get user chat sessions: {e}")
            return []

    async def delete_old_sessions(self, days: int = 30) -> int:
        """Delete chat sessions older than specified days"""
        if not self.client:
            return 0

        try:
            cutoff_date = datetime.utcnow() - timedelta(days=days)

            # Delete old messages first (foreign key constraint)
            self.client.table('chat_messages').delete().lt('timestamp', cutoff_date.isoformat()).execute()

            # Delete old sessions
            response = self.client.table('chat_sessions').delete().lt('created_at', cutoff_date.isoformat()).execute()

            deleted_count = len(response.data) if response.data else 0
            logger.info(f"Deleted {deleted_count} old chat sessions")
            return deleted_count
        except Exception as e:
            logger.error(f"Failed to delete old sessions: {e}")
            return 0
