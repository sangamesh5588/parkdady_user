import os
import json
from typing import Dict, List, Optional
from datetime import datetime, timedelta
import asyncio

# Optional imports - gracefully handle if not installed
try:
    from twilio.rest import Client
    from twilio.base.exceptions import TwilioException
    TWILIO_AVAILABLE = True
except ImportError:
    TWILIO_AVAILABLE = False
    print("Warning: Twilio not installed. Voice call escalation disabled.")

try:
    import redis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False
    print("Warning: Redis not installed. Session management disabled.")

try:
    import socketio
    SOCKETIO_AVAILABLE = True
except ImportError:
    SOCKETIO_AVAILABLE = False
    print("Warning: Socket.IO not installed. Real-time notifications disabled.")

from models import AgentContact, EscalationRequest, Message

class AgentFallbackService:
    def __init__(self):
        # Twilio configuration for calling
        self.twilio_account_sid = os.getenv('TWILIO_ACCOUNT_SID')
        self.twilio_auth_token = os.getenv('TWILIO_AUTH_TOKEN')
        self.twilio_phone_number = os.getenv('TWILIO_PHONE_NUMBER', '+1234567890')

        # Redis for session management
        if REDIS_AVAILABLE:
            try:
                self.redis_client = redis.Redis(
                    host=os.getenv('REDIS_HOST', 'localhost'),
                    port=int(os.getenv('REDIS_PORT', 6379)),
                    db=int(os.getenv('REDIS_DB', 0)),
                    decode_responses=True
                )
            except Exception as e:
                print(f"Redis connection failed: {e}")
                self.redis_client = None
        else:
            self.redis_client = None

        # Socket.IO for real-time communication
        if SOCKETIO_AVAILABLE:
            self.sio = socketio.AsyncClient()
        else:
            self.sio = None

        # Agent configuration
        self.agents = self._load_agent_config()
        self.business_hours = {
            'start': 9,  # 9 AM
            'end': 18,   # 6 PM
            'timezone': 'Asia/Kolkata'  # Adjust based on your location
        }

    def _load_agent_config(self) -> Dict[str, AgentContact]:
        """Load agent configuration"""
        # Default agent configuration
        default_agents = {
            'general_support': AgentContact(
                phone_number='+15551234567',
                name='General Support',
                department='Customer Service',
                available=True
            ),
            'technical_support': AgentContact(
                phone_number='+15559876543',
                name='Technical Support',
                department='Technical Team',
                available=True
            ),
            'emergency': AgentContact(
                phone_number='+15559111222',
                name='Emergency Response',
                department='Emergency Services',
                available=True
            ),
            'billing_support': AgentContact(
                phone_number='+15553456789',
                name='Billing Support',
                department='Finance',
                available=True
            )
        }

        # Try to load from config file
        config_file = os.path.join(os.path.dirname(__file__), 'agents_config.json')
        if os.path.exists(config_file):
            try:
                with open(config_file, 'r') as f:
                    config_data = json.load(f)
                    for agent_id, agent_data in config_data.items():
                        default_agents[agent_id] = AgentContact(**agent_data)
            except Exception as e:
                print(f"Error loading agent config: {e}")

        return default_agents

    def is_business_hours(self) -> bool:
        """Check if current time is within business hours"""
        now = datetime.now()
        current_hour = now.hour

        # Consider Monday-Friday as business days (0=Monday, 4=Friday)
        is_weekday = now.weekday() < 5

        return is_weekday and self.business_hours['start'] <= current_hour < self.business_hours['end']

    def get_available_agents(self, department: Optional[str] = None) -> List[AgentContact]:
        """Get list of available agents"""
        available_agents = []

        for agent in self.agents.values():
            if agent.available:
                if department is None or agent.department.lower() == department.lower():
                    available_agents.append(agent)

        return available_agents

    def select_best_agent(self, escalation_request: EscalationRequest) -> Optional[AgentContact]:
        """Select the best agent for the escalation"""
        available_agents = self.get_available_agents()

        if not available_agents:
            return None

        # Priority based on category
        category_priorities = {
            'emergency': ['emergency'],
            'technical': ['technical_support', 'general_support'],
            'billing': ['billing_support', 'general_support'],
            'general': ['general_support']
        }

        preferred_departments = category_priorities.get(
            escalation_request.category.value.lower(),
            ['general_support']
        )

        # Find agent in preferred departments
        for dept in preferred_departments:
            for agent in available_agents:
                if agent.department.lower().replace(' ', '_') == dept:
                    return agent

        # Fallback to any available agent
        return available_agents[0] if available_agents else None

    async def initiate_agent_call(self, user_phone: str, agent: AgentContact) -> Dict[str, str]:
        """Initiate a call between user and agent using Twilio"""
        try:
            if not self.twilio_account_sid or not self.twilio_auth_token:
                return {
                    'status': 'error',
                    'message': 'Twilio not configured. Please call directly.',
                    'direct_number': agent.phone_number
                }

            client = Client(self.twilio_account_sid, self.twilio_auth_token)

            # Create a conference call
            conference_name = f"support_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

            # Call the agent first
            agent_call = client.calls.create(
                to=agent.phone_number,
                from_=self.twilio_phone_number,
                url=f"{os.getenv('BASE_URL', 'http://localhost:8000')}/twilio/connect_agent/{conference_name}",
                status_callback=f"{os.getenv('BASE_URL', 'http://localhost:8000')}/twilio/call_status",
                status_callback_event=['completed', 'busy', 'no-answer']
            )

            # Call the user
            user_call = client.calls.create(
                to=user_phone,
                from_=self.twilio_phone_number,
                url=f"{os.getenv('BASE_URL', 'http://localhost:8000')}/twilio/connect_user/{conference_name}",
                status_callback=f"{os.getenv('BASE_URL', 'http://localhost:8000')}/twilio/call_status",
                status_callback_event=['completed', 'busy', 'no-answer']
            )

            return {
                'status': 'success',
                'message': f'Connecting you to {agent.name}...',
                'conference_id': conference_name,
                'agent_call_sid': agent_call.sid,
                'user_call_sid': user_call.sid
            }

        except TwilioException as e:
            print(f"Twilio error: {e}")
            return {
                'status': 'error',
                'message': 'Unable to initiate call. Please call directly.',
                'direct_number': agent.phone_number
            }
        except Exception as e:
            print(f"Call initiation error: {e}")
            return {
                'status': 'error',
                'message': 'Service temporarily unavailable. Please try again.',
                'direct_number': agent.phone_number
            }

    async def send_agent_notification(self, escalation_request: EscalationRequest, agent: AgentContact) -> bool:
        """Send notification to agent about new escalation"""
        try:
            # Store escalation in Redis for agent dashboard
            escalation_key = f"escalation:{escalation_request.chat_id}"
            escalation_data = {
                'chat_id': escalation_request.chat_id,
                'user_id': escalation_request.user_id,
                'category': escalation_request.category.value,
                'reason': escalation_request.reason,
                'agent_id': agent.phone_number,
                'timestamp': datetime.now().isoformat(),
                'status': 'pending'
            }

            self.redis_client.setex(
                escalation_key,
                3600,  # 1 hour expiry
                json.dumps(escalation_data)
            )

            # Notify agent via Socket.IO if connected
            await self._notify_agent_via_socket(agent, escalation_request)

            return True

        except Exception as e:
            print(f"Agent notification error: {e}")
            return False

    async def _notify_agent_via_socket(self, agent: AgentContact, escalation_request: EscalationRequest):
        """Send real-time notification to agent via Socket.IO"""
        try:
            if not self.sio.connected:
                await self.sio.connect(os.getenv('AGENT_SOCKET_URL', 'http://localhost:3001'))

            notification_data = {
                'type': 'new_escalation',
                'escalation': {
                    'chat_id': escalation_request.chat_id,
                    'user_id': escalation_request.user_id,
                    'category': escalation_request.category.value,
                    'reason': escalation_request.reason,
                    'message_count': len(escalation_request.message_history),
                    'timestamp': datetime.now().isoformat()
                }
            }

            await self.sio.emit('agent_notification', notification_data)

        except Exception as e:
            print(f"Socket notification error: {e}")

    def get_escalation_history(self, chat_id: str) -> Optional[Dict]:
        """Get escalation history for a chat"""
        try:
            escalation_key = f"escalation:{chat_id}"
            data = self.redis_client.get(escalation_key)
            return json.loads(data) if data else None
        except Exception as e:
            print(f"Error retrieving escalation history: {e}")
            return None

    def update_escalation_status(self, chat_id: str, status: str, agent_notes: Optional[str] = None):
        """Update escalation status"""
        try:
            escalation_key = f"escalation:{chat_id}"
            data = self.redis_client.get(escalation_key)

            if data:
                escalation_data = json.loads(data)
                escalation_data['status'] = status
                escalation_data['updated_at'] = datetime.now().isoformat()
                if agent_notes:
                    escalation_data['agent_notes'] = agent_notes

                self.redis_client.setex(escalation_key, 3600, json.dumps(escalation_data))

        except Exception as e:
            print(f"Error updating escalation status: {e}")

    async def handle_escalation(self, escalation_request: EscalationRequest, user_phone: Optional[str] = None) -> Dict[str, any]:
        """Main method to handle escalation to human agent"""
        try:
            # Check if within business hours
            if not self.is_business_hours():
                return {
                    'escalated': True,
                    'message': 'Our agents are currently unavailable. Please leave a message or call back during business hours (Mon-Fri 9AM-6PM).',
                    'agent_contact': {
                        'phone': '+15551234567',
                        'name': 'General Support',
                        'available_hours': 'Mon-Fri 9AM-6PM'
                    },
                    'suggested_actions': ['Leave voicemail', 'Send email', 'Try again during business hours']
                }

            # Select best agent
            agent = self.select_best_agent(escalation_request)
            if not agent:
                return {
                    'escalated': False,
                    'message': 'All agents are currently busy. Please try again in a few minutes or call our main support line.',
                    'fallback_contact': '+15551234567'
                }

            # Notify agent
            notification_sent = await self.send_agent_notification(escalation_request, agent)

            # Initiate call if user phone is provided
            call_result = None
            if user_phone:
                call_result = await self.initiate_agent_call(user_phone, agent)

            response = {
                'escalated': True,
                'message': f'Connecting you with {agent.name} from {agent.department}...',
                'agent_info': {
                    'name': agent.name,
                    'department': agent.department,
                    'estimated_wait': 'Less than 2 minutes'
                },
                'notification_sent': notification_sent
            }

            if call_result:
                response['call_status'] = call_result

            return response

        except Exception as e:
            print(f"Escalation handling error: {e}")
            return {
                'escalated': False,
                'message': 'Unable to connect to agent at this time. Please call our support line directly.',
                'direct_contact': '+15551234567'
            }

    async def get_chat_transcript(self, chat_id: str) -> List[Dict]:
        """Get chat transcript for agent reference"""
        try:
            # This would typically fetch from database
            # For now, return mock data
            return [
                {
                    'timestamp': datetime.now().isoformat(),
                    'sender': 'user',
                    'message': 'I need help with my booking'
                },
                {
                    'timestamp': datetime.now().isoformat(),
                    'sender': 'bot',
                    'message': 'I understand you need help with booking. Let me assist you.'
                }
            ]
        except Exception as e:
            print(f"Error getting chat transcript: {e}")
            return []
