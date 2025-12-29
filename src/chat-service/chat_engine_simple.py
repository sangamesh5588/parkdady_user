import re
from typing import List, Dict, Optional, Tuple
from models import QueryCategory, QueryIntent

class SimpleChatEngine:
    def __init__(self):
        self.stop_words = set(['i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you', 'your', 'yours',
                              'yourself', 'yourselves', 'he', 'him', 'his', 'himself', 'she', 'her', 'hers',
                              'herself', 'it', 'its', 'itself', 'they', 'them', 'their', 'theirs', 'themselves',
                              'what', 'which', 'who', 'whom', 'this', 'that', 'these', 'those', 'am', 'is', 'are',
                              'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'having', 'do', 'does',
                              'did', 'doing', 'a', 'an', 'the', 'and', 'but', 'if', 'or', 'because', 'as', 'until',
                              'while', 'of', 'at', 'by', 'for', 'with', 'about', 'against', 'between', 'into',
                              'through', 'during', 'before', 'after', 'above', 'below', 'to', 'from', 'up', 'down',
                              'in', 'out', 'on', 'off', 'over', 'under', 'again', 'further', 'then', 'once'])

        # Knowledge base for parking app queries
        self.knowledge_base = {
            QueryCategory.BOOKING: {
                "patterns": [
                    r"how.*book.*parking",
                    r"book.*parking.*space",
                    r"reserve.*parking",
                    r"make.*booking",
                    r"cancel.*booking",
                    r"modify.*booking",
                    r"change.*booking",
                    r"booking.*process",
                    r"steps.*to.*book",
                    r"find.*parking.*space",
                    r"available.*parking",
                    r"parking.*availability",
                    r"book.*in.*advance",
                    r"booking.*time.*limit",
                    r"late.*arrival",
                    r"arrive.*late",
                    r"extend.*booking",
                    r"booking.*duration"
                ],
                "responses": {
                    "booking_process": "To book a parking space:\n1. Open the app and explore available spaces\n2. Select date and time range\n3. Choose your vehicle\n4. Review details and complete payment\n5. Receive QR code for access",
                    "cancel_modify": "Bookings can be modified or cancelled up to 2 hours before start time for a full refund. 1-2 hours before: 50% refund. Less than 1 hour: no refund.",
                    "late_arrival": "Late arrivals may result in space reassignment or cancellation. Please arrive on time to avoid penalties.",
                    "availability": "Parking availability is shown in real-time. Book in advance for best rates and guaranteed spaces."
                }
            },
            QueryCategory.PAYMENT: {
                "patterns": [
                    r"payment.*method",
                    r"pay.*with",
                    r"accepted.*payment",
                    r"credit.*card",
                    r"debit.*card",
                    r"upi.*payment",
                    r"digital.*wallet",
                    r"payment.*issue",
                    r"payment.*fail",
                    r"payment.*decline",
                    r"refund.*policy",
                    r"get.*refund",
                    r"refund.*time",
                    r"billing.*issue",
                    r"charge.*wrong",
                    r"double.*charge",
                    r"payment.*timeout",
                    r"connection.*error.*payment"
                ],
                "responses": {
                    "payment_methods": "We accept credit cards, debit cards, UPI, and digital wallets like Paytm, PhonePe, and Google Pay.",
                    "payment_issues": "Common payment issues:\n• Check card balance and expiration\n• Ensure stable internet connection\n• Try different payment method\n• Contact your bank if card is declined",
                    "refund_policy": "Refunds are processed within 5-7 business days. Full refund for cancellations 2+ hours before booking start time.",
                    "billing_problems": "For billing issues, please contact support with your booking reference number."
                }
            },
            QueryCategory.VEHICLE: {
                "patterns": [
                    r"add.*vehicle",
                    r"register.*car",
                    r"vehicle.*information",
                    r"change.*vehicle",
                    r"update.*vehicle",
                    r"default.*vehicle",
                    r"multiple.*vehicle",
                    r"vehicle.*size",
                    r"large.*vehicle",
                    r"electric.*vehicle",
                    r"ev.*charging",
                    r"vehicle.*insurance",
                    r"vehicle.*requirement",
                    r"parking.*for.*truck",
                    r"motorcycle.*parking"
                ],
                "responses": {
                    "add_vehicle": "To add a vehicle:\n1. Go to Profile > Vehicles\n2. Tap 'Add Vehicle'\n3. Enter license plate, make, model, and color\n4. Set as default if preferred",
                    "vehicle_requirements": "Vehicles must be street-legal and insured. Maximum size restrictions apply. EV charging available in designated areas only.",
                    "multiple_vehicles": "You can register multiple vehicles. Select the appropriate vehicle when booking.",
                    "insurance": "We recommend your own vehicle insurance. We are not responsible for vehicle damage or theft."
                }
            },
            QueryCategory.ACCOUNT: {
                "patterns": [
                    r"create.*account",
                    r"sign.*up",
                    r"register.*account",
                    r"login.*issue",
                    r"forgot.*password",
                    r"reset.*password",
                    r"change.*password",
                    r"update.*profile",
                    r"edit.*information",
                    r"delete.*account",
                    r"account.*verification",
                    r"email.*verification"
                ],
                "responses": {
                    "signup": "To create an account:\n1. Download the app\n2. Tap 'Sign Up'\n3. Enter phone number and email\n4. Verify with OTP\n5. Complete your profile",
                    "login_issues": "If you can't login:\n• Check email/phone and password\n• Reset password if forgotten\n• Clear app cache\n• Contact support if issues persist",
                    "profile_update": "Update your profile in Settings > Profile. You can change name, phone, email, and add vehicles.",
                    "verification": "Account verification requires valid phone number and email. Check spam folder for verification emails."
                }
            },
            QueryCategory.TECHNICAL: {
                "patterns": [
                    r"app.*crash",
                    r"app.*not.*work",
                    r"login.*error",
                    r"qr.*code.*not.*work",
                    r"scan.*qr",
                    r"location.*permission",
                    r"gps.*not.*work",
                    r"notification.*not.*work",
                    r"update.*app",
                    r"app.*version",
                    r"device.*not.*support",
                    r"android.*version",
                    r"ios.*version"
                ],
                "responses": {
                    "app_crash": "If the app crashes:\n• Restart the app\n• Clear cache and data\n• Update to latest version\n• Restart your device\n• Reinstall if issues persist",
                    "qr_issues": "QR code issues:\n• Ensure good lighting\n• Hold phone steady\n• Clean camera lens\n• Update app to latest version",
                    "permissions": "Enable location permissions in device settings for the app to find nearby parking spaces.",
                    "compatibility": "Minimum requirements: Android 8.0+, iOS 12.0+. Update your device OS for best performance."
                }
            },
            QueryCategory.GENERAL: {
                "patterns": [
                    r"contact.*support",
                    r"customer.*service",
                    r"help.*center",
                    r"support.*hour",
                    r"available.*time",
                    r"business.*hour",
                    r"emergency.*contact",
                    r"urgent.*issue",
                    r"how.*contact",
                    r"support.*number",
                    r"support.*email"
                ],
                "responses": {
                    "contact_info": "Contact us:\n• Live Chat: Available Mon-Fri 9AM-6PM\n• Email: support@parkingapp.com\n• Phone: +1 (555) 123-4567\n• Emergency: +1 (555) 911-PARK",
                    "support_hours": "Support is available Monday to Friday, 9 AM to 6 PM (local time). For urgent issues outside business hours, use emergency contact.",
                    "emergency": "For urgent parking issues only. Regular support requests should use live chat or email during business hours."
                }
            }
        }

        # Pre-compile patterns for faster matching
        self.compiled_patterns = {}
        for category, data in self.knowledge_base.items():
            self.compiled_patterns[category] = [
                (re.compile(pattern, re.IGNORECASE), response_type)
                for pattern in data["patterns"]
                for response_type, _ in data["responses"].items()
            ]

    def classify_intent(self, message: str) -> QueryIntent:
        """Classify user intent using pattern matching and keyword analysis"""
        message_lower = message.lower()

        # Method 1: Pattern matching
        pattern_result = self._classify_by_patterns(message)
        if pattern_result:
            return pattern_result

        # Method 2: Keyword matching
        keyword_result = self._classify_by_keywords(message_lower)
        if keyword_result:
            return keyword_result

        # Default fallback
        return QueryIntent(
            category=QueryCategory.GENERAL,
            confidence=0.3,
            keywords=[],
            suggested_response="I'm not sure about that. Let me connect you with a support agent who can help you better."
        )

    def _classify_by_patterns(self, message: str) -> Optional[QueryIntent]:
        """Classify using regex patterns"""
        message_lower = message.lower()

        for category, patterns in self.compiled_patterns.items():
            matched_patterns = []
            for pattern, response_type in patterns:
                if pattern.search(message_lower):
                    matched_patterns.append(response_type)

            if matched_patterns:
                confidence = min(0.9, 0.6 + (len(matched_patterns) * 0.1))
                return QueryIntent(
                    category=category,
                    confidence=confidence,
                    keywords=matched_patterns,
                    suggested_response=self._get_response(category, matched_patterns[0])
                )

        return None

    def _classify_by_keywords(self, message: str) -> Optional[QueryIntent]:
        """Classify using keyword matching"""
        keyword_map = {
            QueryCategory.BOOKING: ["book", "booking", "reserve", "reservation", "cancel", "modify", "change"],
            QueryCategory.PAYMENT: ["pay", "payment", "refund", "billing", "charge", "money", "cost"],
            QueryCategory.VEHICLE: ["car", "vehicle", "truck", "motorcycle", "license", "plate"],
            QueryCategory.ACCOUNT: ["login", "password", "account", "profile", "sign up", "register"],
            QueryCategory.TECHNICAL: ["app", "crash", "error", "bug", "not working", "qr", "scan"],
            QueryCategory.GENERAL: ["help", "support", "contact", "emergency", "urgent"]
        }

        category_scores = {}
        message_words = set(message.split())

        for category, keywords in keyword_map.items():
            score = sum(1 for keyword in keywords if keyword in message)
            if score > 0:
                category_scores[category] = score

        if category_scores:
            best_category = max(category_scores, key=category_scores.get)
            confidence = min(0.8, 0.4 + (category_scores[best_category] * 0.1))

            return QueryIntent(
                category=best_category,
                confidence=confidence,
                keywords=[k for k in keyword_map[best_category] if k in message],
                suggested_response=self._get_default_response(best_category)
            )

        return None

    def _get_response(self, category: QueryCategory, response_type: str) -> str:
        """Get specific response from knowledge base"""
        if category in self.knowledge_base and response_type in self.knowledge_base[category]["responses"]:
            return self.knowledge_base[category]["responses"][response_type]
        return self._get_default_response(category)

    def _get_default_response(self, category: QueryCategory) -> str:
        """Get default response for category"""
        defaults = {
            QueryCategory.BOOKING: "I can help you with booking-related questions. Could you please provide more details about what you need assistance with?",
            QueryCategory.PAYMENT: "I can assist with payment and billing questions. What specific payment issue are you experiencing?",
            QueryCategory.VEHICLE: "I can help with vehicle registration and management questions. What would you like to know?",
            QueryCategory.ACCOUNT: "I can assist with account and profile related questions. How can I help you today?",
            QueryCategory.TECHNICAL: "I can help troubleshoot technical issues. Please describe the problem you're experiencing.",
            QueryCategory.GENERAL: "I'm here to help! Please let me know what you need assistance with."
        }
        return defaults.get(category, "How can I assist you today?")

    def should_escalate(self, message: str, intent: QueryIntent, conversation_history: List[str]) -> Tuple[bool, str]:
        """Determine if query should be escalated to human agent"""
        reasons_to_escalate = [
            # Low confidence
            intent.confidence < 0.4,

            # Complex or unclear queries
            any(word in message.lower() for word in ["complaint", "angry", "frustrated", "urgent", "emergency"]),

            # Multiple failed attempts
            len([msg for msg in conversation_history if "sorry" in msg.lower() or "don't know" in msg.lower()]) > 2,

            # Specific complex topics
            any(word in message.lower() for word in ["lawsuit", "legal", "court", "police", "insurance claim"]),
        ]

        if any(reasons_to_escalate):
            reason = "Low confidence in automated response"
            if intent.confidence < 0.4:
                reason = "Unable to understand your query clearly"
            elif any(word in message.lower() for word in ["complaint", "angry", "frustrated"]):
                reason = "Detected user frustration or complaint"
            elif any(word in message.lower() for word in ["lawsuit", "legal", "court"]):
                reason = "Legal or complex issue requiring human attention"

            return True, reason

        return False, ""
