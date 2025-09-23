# Notification Systems: Keeping Everyone in the Loop

## 🎯 What are Notification Systems?

A notification system is like a modern postal service combined with an emergency broadcast system. Just as the postal service delivers letters to specific addresses while emergency broadcasts reach everyone simultaneously, notification systems deliver targeted messages to individual users while also supporting mass communications. They ensure important information reaches the right people at the right time through their preferred channels.

## 🏗️ Core Concepts

### The Modern Communication Network Analogy
- **Notification Service**: Central communication hub (like a TV/radio station)
- **Delivery Channels**: Different ways to reach people (SMS, email, push, in-app)
- **Targeting**: Knowing who should receive what messages
- **Delivery Guarantees**: Ensuring messages actually reach recipients
- **Preferences**: Respecting how people want to be contacted
- **Rate Limiting**: Preventing message spam and overload

### Why Notification Systems Matter
1. **User Engagement**: Keep users informed and engaged with your application
2. **Critical Alerts**: Deliver time-sensitive information like security alerts
3. **Business Communication**: Marketing campaigns, product updates, announcements
4. **System Monitoring**: Alert operations teams about system issues
5. **User Experience**: Provide feedback and confirmation for user actions

## 📱 Core Notification Architecture

```python
import time
import threading
import json
import random
from typing import Dict, List, Optional, Set, Any, Callable
from enum import Enum
from dataclasses import dataclass, asdict
from collections import defaultdict, deque
import heapq
from abc import ABC, abstractmethod

class NotificationType(Enum):
    PUSH = "push"
    EMAIL = "email"
    SMS = "sms"
    IN_APP = "in_app"
    WEBHOOK = "webhook"
    SLACK = "slack"

class Priority(Enum):
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    CRITICAL = 4

class NotificationStatus(Enum):
    PENDING = "pending"
    SENT = "sent"
    DELIVERED = "delivered"
    FAILED = "failed"
    EXPIRED = "expired"

@dataclass
class User:
    user_id: str
    email: str
    phone: str
    push_tokens: List[str]
    preferences: Dict[str, Any]
    timezone: str
    active_sessions: List[str]

@dataclass
class NotificationTemplate:
    template_id: str
    name: str
    subject_template: str
    body_template: str
    supported_channels: List[NotificationType]
    default_priority: Priority
    metadata: Dict[str, Any]

@dataclass
class Notification:
    notification_id: str
    user_id: str
    template_id: str
    channel: NotificationType
    priority: Priority
    subject: str
    body: str
    data: Dict[str, Any]
    created_at: float
    scheduled_at: Optional[float]
    expires_at: Optional[float]
    status: NotificationStatus
    attempts: int
    last_attempt_at: Optional[float]
    delivered_at: Optional[float]
    error_message: Optional[str]

class NotificationChannel(ABC):
    """Abstract base class for notification channels"""
    
    def __init__(self, channel_type: NotificationType):
        self.channel_type = channel_type
        self.rate_limiter = RateLimiter(max_requests=100, window_seconds=60)
        self.delivery_stats = {
            'sent': 0,
            'delivered': 0,
            'failed': 0
        }
    
    @abstractmethod
    def send_notification(self, notification: Notification, user: User) -> Dict[str, Any]:
        """Send notification through this channel"""
        pass
    
    @abstractmethod
    def validate_user_data(self, user: User) -> bool:
        """Validate that user has required data for this channel"""
        pass
    
    def can_send(self, user: User) -> bool:
        """Check if we can send to this user through this channel"""
        return (self.rate_limiter.can_proceed(user.user_id) and 
                self.validate_user_data(user))

class PushNotificationChannel(NotificationChannel):
    def __init__(self):
        super().__init__(NotificationType.PUSH)
        self.fcm_client = FCMClient()  # Firebase Cloud Messaging client
    
    def send_notification(self, notification: Notification, user: User) -> Dict[str, Any]:
        """Send push notification"""
        
        if not user.push_tokens:
            return {
                'success': False,
                'error': 'No push tokens available for user'
            }
        
        # Prepare push notification payload
        payload = {
            'title': notification.subject,
            'body': notification.body,
            'data': notification.data,
            'priority': 'high' if notification.priority in [Priority.HIGH, Priority.CRITICAL] else 'normal'
        }
        
        successful_tokens = []
        failed_tokens = []
        
        # Send to all user's devices
        for token in user.push_tokens:
            try:
                result = self.fcm_client.send_to_token(token, payload)
                
                if result['success']:
                    successful_tokens.append(token)
                    self.delivery_stats['delivered'] += 1
                else:
                    failed_tokens.append(token)
                    self.delivery_stats['failed'] += 1
                    
            except Exception as e:
                failed_tokens.append(token)
                self.delivery_stats['failed'] += 1
        
        self.delivery_stats['sent'] += 1
        
        return {
            'success': len(successful_tokens) > 0,
            'successful_tokens': successful_tokens,
            'failed_tokens': failed_tokens,
            'total_sent': len(user.push_tokens)
        }
    
    def validate_user_data(self, user: User) -> bool:
        """Validate user has push tokens"""
        return bool(user.push_tokens)

class EmailNotificationChannel(NotificationChannel):
    def __init__(self):
        super().__init__(NotificationType.EMAIL)
        self.smtp_client = SMTPClient()
    
    def send_notification(self, notification: Notification, user: User) -> Dict[str, Any]:
        """Send email notification"""
        
        try:
            # Prepare email
            email_data = {
                'to': user.email,
                'subject': notification.subject,
                'body': notification.body,
                'html': notification.data.get('html_body'),
                'attachments': notification.data.get('attachments', [])
            }
            
            # Send email
            result = self.smtp_client.send_email(email_data)
            
            if result['success']:
                self.delivery_stats['delivered'] += 1
                return {
                    'success': True,
                    'message_id': result['message_id']
                }
            else:
                self.delivery_stats['failed'] += 1
                return {
                    'success': False,
                    'error': result['error']
                }
                
        except Exception as e:
            self.delivery_stats['failed'] += 1
            return {
                'success': False,
                'error': str(e)
            }
        finally:
            self.delivery_stats['sent'] += 1
    
    def validate_user_data(self, user: User) -> bool:
        """Validate user has email address"""
        return bool(user.email and '@' in user.email)

class SMSNotificationChannel(NotificationChannel):
    def __init__(self):
        super().__init__(NotificationType.SMS)
        self.sms_client = SMSClient()
    
    def send_notification(self, notification: Notification, user: User) -> Dict[str, Any]:
        """Send SMS notification"""
        
        try:
            # SMS messages are typically short
            sms_body = notification.body[:160]  # Limit to 160 characters
            
            result = self.sms_client.send_sms(user.phone, sms_body)
            
            if result['success']:
                self.delivery_stats['delivered'] += 1
                return {
                    'success': True,
                    'message_id': result['message_id']
                }
            else:
                self.delivery_stats['failed'] += 1
                return {
                    'success': False,
                    'error': result['error']
                }
                
        except Exception as e:
            self.delivery_stats['failed'] += 1
            return {
                'success': False,
                'error': str(e)
            }
        finally:
            self.delivery_stats['sent'] += 1
    
    def validate_user_data(self, user: User) -> bool:
        """Validate user has phone number"""
        return bool(user.phone and len(user.phone) >= 10)

class InAppNotificationChannel(NotificationChannel):
    def __init__(self):
        super().__init__(NotificationType.IN_APP)
        self.active_connections = {}  # user_id -> websocket connections
        self.notification_storage = defaultdict(list)  # user_id -> notifications
    
    def send_notification(self, notification: Notification, user: User) -> Dict[str, Any]:
        """Send in-app notification"""
        
        # Store notification for user
        self.notification_storage[user.user_id].append({
            'id': notification.notification_id,
            'subject': notification.subject,
            'body': notification.body,
            'data': notification.data,
            'timestamp': time.time(),
            'read': False
        })
        
        # Send real-time notification if user is online
        if user.user_id in self.active_connections:
            try:
                websocket_payload = {
                    'type': 'notification',
                    'notification': {
                        'id': notification.notification_id,
                        'subject': notification.subject,
                        'body': notification.body,
                        'data': notification.data
                    }
                }
                
                # Send to all active sessions
                sent_count = 0
                for session_id in user.active_sessions:
                    if session_id in self.active_connections[user.user_id]:
                        connection = self.active_connections[user.user_id][session_id]
                        connection.send(json.dumps(websocket_payload))
                        sent_count += 1
                
                self.delivery_stats['delivered'] += 1
                return {
                    'success': True,
                    'sent_to_sessions': sent_count,
                    'stored': True
                }
                
            except Exception as e:
                # Even if real-time delivery fails, notification is stored
                self.delivery_stats['delivered'] += 1
                return {
                    'success': True,
                    'sent_to_sessions': 0,
                    'stored': True,
                    'error': str(e)
                }
        else:
            # User offline, but notification is stored
            self.delivery_stats['delivered'] += 1
            return {
                'success': True,
                'sent_to_sessions': 0,
                'stored': True
            }
    
    def validate_user_data(self, user: User) -> bool:
        """In-app notifications don't require specific user data"""
        return True
    
    def get_user_notifications(self, user_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Get stored notifications for user"""
        notifications = self.notification_storage.get(user_id, [])
        return sorted(notifications, key=lambda x: x['timestamp'], reverse=True)[:limit]
    
    def mark_as_read(self, user_id: str, notification_id: str) -> bool:
        """Mark notification as read"""
        notifications = self.notification_storage.get(user_id, [])
        
        for notification in notifications:
            if notification['id'] == notification_id:
                notification['read'] = True
                return True
        
        return False

class RateLimiter:
    def __init__(self, max_requests: int, window_seconds: int):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests = defaultdict(deque)  # user_id -> deque of timestamps
    
    def can_proceed(self, user_id: str) -> bool:
        """Check if request can proceed without hitting rate limit"""
        current_time = time.time()
        user_requests = self.requests[user_id]
        
        # Remove old requests outside the window
        while user_requests and user_requests[0] < current_time - self.window_seconds:
            user_requests.popleft()
        
        # Check if under limit
        if len(user_requests) < self.max_requests:
            user_requests.append(current_time)
            return True
        
        return False

class NotificationService:
    def __init__(self):
        self.channels: Dict[NotificationType, NotificationChannel] = {
            NotificationType.PUSH: PushNotificationChannel(),
            NotificationType.EMAIL: EmailNotificationChannel(),
            NotificationType.SMS: SMSNotificationChannel(),
            NotificationType.IN_APP: InAppNotificationChannel()
        }
        
        self.users: Dict[str, User] = {}
        self.templates: Dict[str, NotificationTemplate] = {}
        self.notifications: Dict[str, Notification] = {}
        self.notification_queue = []  # Priority queue
        self.failed_queue = deque()  # Failed notifications for retry
        
        # Background workers
        self.running = True
        self.worker_threads = []
        self.retry_thread = None
        
        # Statistics
        self.stats = {
            'total_sent': 0,
            'total_delivered': 0,
            'total_failed': 0,
            'channel_stats': defaultdict(dict)
        }
        
        self._start_workers()
    
    def _start_workers(self):
        """Start background worker threads"""
        
        # Main notification processor
        for i in range(3):  # 3 worker threads
            worker = threading.Thread(target=self._notification_worker, args=(i,))
            worker.daemon = True
            worker.start()
            self.worker_threads.append(worker)
        
        # Retry processor
        self.retry_thread = threading.Thread(target=self._retry_worker)
        self.retry_thread.daemon = True
        self.retry_thread.start()
        
        print("Notification service workers started")
    
    def register_user(self, user: User):
        """Register a user with the notification service"""
        self.users[user.user_id] = user
        print(f"Registered user {user.user_id}")
    
    def register_template(self, template: NotificationTemplate):
        """Register a notification template"""
        self.templates[template.template_id] = template
        print(f"Registered template {template.template_id}")
    
    def send_notification(self, user_id: str, template_id: str, 
                         channels: List[NotificationType] = None,
                         data: Dict[str, Any] = None,
                         priority: Priority = None,
                         scheduled_at: float = None,
                         expires_at: float = None) -> List[str]:
        """Send notification to user"""
        
        if user_id not in self.users:
            raise ValueError(f"User {user_id} not found")
        
        if template_id not in self.templates:
            raise ValueError(f"Template {template_id} not found")
        
        user = self.users[user_id]
        template = self.templates[template_id]
        
        # Determine channels to use
        if channels is None:
            channels = self._get_user_preferred_channels(user, template)
        
        # Filter by user preferences and channel availability
        channels = self._filter_channels(user, channels, template)
        
        # Create notifications for each channel
        notification_ids = []
        
        for channel in channels:
            notification_id = f"notif_{int(time.time() * 1000)}_{random.randint(1000, 9999)}"
            
            # Render template with data
            subject, body = self._render_template(template, data or {})
            
            notification = Notification(
                notification_id=notification_id,
                user_id=user_id,
                template_id=template_id,
                channel=channel,
                priority=priority or template.default_priority,
                subject=subject,
                body=body,
                data=data or {},
                created_at=time.time(),
                scheduled_at=scheduled_at,
                expires_at=expires_at,
                status=NotificationStatus.PENDING,
                attempts=0,
                last_attempt_at=None,
                delivered_at=None,
                error_message=None
            )
            
            self.notifications[notification_id] = notification
            
            # Add to priority queue
            priority_value = notification.priority.value
            scheduled_time = scheduled_at or time.time()
            
            heapq.heappush(self.notification_queue, (priority_value, scheduled_time, notification_id))
            
            notification_ids.append(notification_id)
        
        print(f"Queued {len(notification_ids)} notifications for user {user_id}")
        return notification_ids
    
    def send_bulk_notification(self, user_ids: List[str], template_id: str,
                              channels: List[NotificationType] = None,
                              data: Dict[str, Any] = None,
                              priority: Priority = None) -> Dict[str, List[str]]:
        """Send notification to multiple users"""
        
        results = {}
        
        for user_id in user_ids:
            try:
                notification_ids = self.send_notification(
                    user_id, template_id, channels, data, priority
                )
                results[user_id] = notification_ids
            except Exception as e:
                print(f"Failed to send notification to {user_id}: {e}")
                results[user_id] = []
        
        return results
    
    def _get_user_preferred_channels(self, user: User, template: NotificationTemplate) -> List[NotificationType]:
        """Get user's preferred channels for this template"""
        
        # Check user preferences
        template_prefs = user.preferences.get('templates', {}).get(template.template_id, {})
        
        if 'channels' in template_prefs:
            preferred = [NotificationType(ch) for ch in template_prefs['channels']]
            # Filter by template supported channels
            return [ch for ch in preferred if ch in template.supported_channels]
        
        # Use global preferences
        global_prefs = user.preferences.get('channels', {})
        enabled_channels = [NotificationType(ch) for ch, enabled in global_prefs.items() if enabled]
        
        if enabled_channels:
            return [ch for ch in enabled_channels if ch in template.supported_channels]
        
        # Default to all supported channels
        return template.supported_channels
    
    def _filter_channels(self, user: User, channels: List[NotificationType], 
                        template: NotificationTemplate) -> List[NotificationType]:
        """Filter channels based on availability and user data"""
        
        filtered = []
        
        for channel in channels:
            if channel in self.channels:
                channel_handler = self.channels[channel]
                if channel_handler.can_send(user):
                    filtered.append(channel)
                else:
                    print(f"Cannot send {channel.value} to user {user.user_id} - rate limited or missing data")
        
        return filtered
    
    def _render_template(self, template: NotificationTemplate, data: Dict[str, Any]) -> tuple[str, str]:
        """Render template with provided data"""
        
        # Simple template rendering (in production, use proper template engine)
        subject = template.subject_template
        body = template.body_template
        
        for key, value in data.items():
            placeholder = f"{{{key}}}"
            subject = subject.replace(placeholder, str(value))
            body = body.replace(placeholder, str(value))
        
        return subject, body
    
    def _notification_worker(self, worker_id: int):
        """Background worker to process notification queue"""
        
        print(f"Notification worker {worker_id} started")
        
        while self.running:
            try:
                if self.notification_queue:
                    # Get next notification
                    priority, scheduled_time, notification_id = heapq.heappop(self.notification_queue)
                    
                    # Check if it's time to send
                    if scheduled_time > time.time():
                        # Put it back and wait
                        heapq.heappush(self.notification_queue, (priority, scheduled_time, notification_id))
                        time.sleep(1)
                        continue
                    
                    # Process notification
                    if notification_id in self.notifications:
                        notification = self.notifications[notification_id]
                        self._process_notification(notification)
                
                time.sleep(0.1)  # Brief pause
                
            except Exception as e:
                print(f"Worker {worker_id} error: {e}")
                time.sleep(1)
    
    def _process_notification(self, notification: Notification):
        """Process a single notification"""
        
        # Check if expired
        if notification.expires_at and time.time() > notification.expires_at:
            notification.status = NotificationStatus.EXPIRED
            print(f"Notification {notification.notification_id} expired")
            return
        
        # Get user and channel
        user = self.users.get(notification.user_id)
        if not user:
            notification.status = NotificationStatus.FAILED
            notification.error_message = "User not found"
            return
        
        channel_handler = self.channels.get(notification.channel)
        if not channel_handler:
            notification.status = NotificationStatus.FAILED
            notification.error_message = f"Channel {notification.channel.value} not available"
            return
        
        # Update attempt tracking
        notification.attempts += 1
        notification.last_attempt_at = time.time()
        
        try:
            # Send notification
            result = channel_handler.send_notification(notification, user)
            
            if result['success']:
                notification.status = NotificationStatus.DELIVERED
                notification.delivered_at = time.time()
                self.stats['total_delivered'] += 1
                
                print(f"Delivered notification {notification.notification_id} via {notification.channel.value}")
            else:
                notification.status = NotificationStatus.FAILED
                notification.error_message = result.get('error', 'Unknown error')
                
                # Add to retry queue if not too many attempts
                if notification.attempts < 3:
                    self.failed_queue.append(notification.notification_id)
                
                self.stats['total_failed'] += 1
                print(f"Failed to deliver notification {notification.notification_id}: {notification.error_message}")
            
            self.stats['total_sent'] += 1
            
        except Exception as e:
            notification.status = NotificationStatus.FAILED
            notification.error_message = str(e)
            
            if notification.attempts < 3:
                self.failed_queue.append(notification.notification_id)
            
            self.stats['total_failed'] += 1
            print(f"Exception processing notification {notification.notification_id}: {e}")
    
    def _retry_worker(self):
        """Worker to retry failed notifications"""
        
        print("Retry worker started")
        
        while self.running:
            try:
                if self.failed_queue:
                    notification_id = self.failed_queue.popleft()
                    
                    if notification_id in self.notifications:
                        notification = self.notifications[notification_id]
                        
                        # Wait before retry (exponential backoff)
                        retry_delay = 2 ** notification.attempts  # 2, 4, 8 seconds
                        
                        if time.time() - notification.last_attempt_at >= retry_delay:
                            print(f"Retrying notification {notification_id} (attempt {notification.attempts + 1})")
                            
                            # Reset status and requeue
                            notification.status = NotificationStatus.PENDING
                            
                            priority_value = notification.priority.value
                            heapq.heappush(self.notification_queue, (priority_value, time.time(), notification_id))
                        else:
                            # Put back in retry queue
                            self.failed_queue.append(notification_id)
                
                time.sleep(1)
                
            except Exception as e:
                print(f"Retry worker error: {e}")
                time.sleep(5)
    
    def get_notification_status(self, notification_id: str) -> Optional[Dict[str, Any]]:
        """Get status of a notification"""
        
        if notification_id not in self.notifications:
            return None
        
        notification = self.notifications[notification_id]
        
        return {
            'notification_id': notification_id,
            'user_id': notification.user_id,
            'channel': notification.channel.value,
            'status': notification.status.value,
            'attempts': notification.attempts,
            'created_at': notification.created_at,
            'delivered_at': notification.delivered_at,
            'error_message': notification.error_message
        }
    
    def get_user_notifications(self, user_id: str, channel: NotificationType = NotificationType.IN_APP) -> List[Dict[str, Any]]:
        """Get notifications for a user"""
        
        if channel == NotificationType.IN_APP:
            in_app_channel = self.channels[NotificationType.IN_APP]
            return in_app_channel.get_user_notifications(user_id)
        
        # For other channels, return from notification history
        user_notifications = []
        
        for notification in self.notifications.values():
            if notification.user_id == user_id and notification.channel == channel:
                user_notifications.append({
                    'id': notification.notification_id,
                    'subject': notification.subject,
                    'body': notification.body,
                    'status': notification.status.value,
                    'created_at': notification.created_at,
                    'delivered_at': notification.delivered_at
                })
        
        return sorted(user_notifications, key=lambda x: x['created_at'], reverse=True)
    
    def get_service_stats(self) -> Dict[str, Any]:
        """Get notification service statistics"""
        
        # Update channel stats
        for channel_type, channel in self.channels.items():
            self.stats['channel_stats'][channel_type.value] = channel.delivery_stats
        
        return {
            'total_notifications': len(self.notifications),
            'queue_size': len(self.notification_queue),
            'retry_queue_size': len(self.failed_queue),
            'delivery_stats': {
                'total_sent': self.stats['total_sent'],
                'total_delivered': self.stats['total_delivered'],
                'total_failed': self.stats['total_failed'],
                'success_rate': (self.stats['total_delivered'] / self.stats['total_sent'] * 100) if self.stats['total_sent'] > 0 else 0
            },
            'channel_stats': dict(self.stats['channel_stats'])
        }

# Mock external service clients
class FCMClient:
    def send_to_token(self, token: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        # Simulate FCM API call
        time.sleep(0.1)  # Simulate network delay
        
        # 95% success rate
        if random.random() < 0.95:
            return {
                'success': True,
                'message_id': f'fcm_{random.randint(100000, 999999)}'
            }
        else:
            return {
                'success': False,
                'error': 'Invalid token or network error'
            }

class SMTPClient:
    def send_email(self, email_data: Dict[str, Any]) -> Dict[str, Any]:
        # Simulate SMTP sending
        time.sleep(0.2)  # Simulate email sending delay
        
        # 98% success rate for emails
        if random.random() < 0.98:
            return {
                'success': True,
                'message_id': f'email_{random.randint(100000, 999999)}'
            }
        else:
            return {
                'success': False,
                'error': 'SMTP server error or invalid email'
            }

class SMSClient:
    def send_sms(self, phone: str, message: str) -> Dict[str, Any]:
        # Simulate SMS API call
        time.sleep(0.15)  # Simulate SMS sending delay
        
        # 90% success rate for SMS
        if random.random() < 0.90:
            return {
                'success': True,
                'message_id': f'sms_{random.randint(100000, 999999)}'
            }
        else:
            return {
                'success': False,
                'error': 'Invalid phone number or carrier error'
            }

# Example usage
print("=== Notification System Demo ===")

# Create notification service
notification_service = NotificationService()

# Register notification templates
welcome_template = NotificationTemplate(
    template_id="welcome",
    name="Welcome Message",
    subject_template="Welcome to {app_name}, {user_name}!",
    body_template="Hi {user_name}, welcome to {app_name}! We're excited to have you on board.",
    supported_channels=[NotificationType.EMAIL, NotificationType.PUSH, NotificationType.IN_APP],
    default_priority=Priority.MEDIUM,
    metadata={"category": "onboarding"}
)

order_confirmation_template = NotificationTemplate(
    template_id="order_confirmation",
    name="Order Confirmation",
    subject_template="Order #{order_id} Confirmed",
    body_template="Your order #{order_id} for ${amount} has been confirmed. Expected delivery: {delivery_date}",
    supported_channels=[NotificationType.EMAIL, NotificationType.SMS, NotificationType.IN_APP],
    default_priority=Priority.HIGH,
    metadata={"category": "transactional"}
)

security_alert_template = NotificationTemplate(
    template_id="security_alert",
    name="Security Alert",
    subject_template="Security Alert: {alert_type}",
    body_template="We detected {alert_type} on your account at {timestamp}. If this wasn't you, please secure your account immediately.",
    supported_channels=[NotificationType.EMAIL, NotificationType.SMS, NotificationType.PUSH],
    default_priority=Priority.CRITICAL,
    metadata={"category": "security"}
)

notification_service.register_template(welcome_template)
notification_service.register_template(order_confirmation_template)
notification_service.register_template(security_alert_template)

# Register users
user1 = User(
    user_id="user_001",
    email="john.doe@example.com",
    phone="+1234567890",
    push_tokens=["fcm_token_123", "fcm_token_456"],
    preferences={
        "channels": {
            "email": True,
            "push": True,
            "sms": False,
            "in_app": True
        }
    },
    timezone="America/New_York",
    active_sessions=["session_1", "session_2"]
)

user2 = User(
    user_id="user_002",
    email="jane.smith@example.com",
    phone="+1987654321",
    push_tokens=["fcm_token_789"],
    preferences={
        "channels": {
            "email": True,
            "push": True,
            "sms": True,
            "in_app": True
        }
    },
    timezone="America/Los_Angeles",
    active_sessions=["session_3"]
)

notification_service.register_user(user1)
notification_service.register_user(user2)

# Send welcome notification
print("\n--- Sending Welcome Notifications ---")
welcome_data = {
    "app_name": "MyApp",
    "user_name": "John"
}

notification_ids = notification_service.send_notification(
    user_id="user_001",
    template_id="welcome",
    data=welcome_data
)

print(f"Sent welcome notification with IDs: {notification_ids}")

# Send order confirmation
print("\n--- Sending Order Confirmation ---")
order_data = {
    "order_id": "ORD-12345",
    "amount": "99.99",
    "delivery_date": "2024-01-15"
}

notification_service.send_notification(
    user_id="user_002",
    template_id="order_confirmation",
    data=order_data,
    priority=Priority.HIGH
)

# Send security alert
print("\n--- Sending Security Alert ---")
security_data = {
    "alert_type": "suspicious login attempt",
    "timestamp": "2024-01-10 14:30:00 UTC"
}

notification_service.send_notification(
    user_id="user_001",
    template_id="security_alert",
    data=security_data,
    channels=[NotificationType.EMAIL, NotificationType.SMS],  # Force specific channels
    priority=Priority.CRITICAL
)

# Send bulk notification
print("\n--- Sending Bulk Notification ---")
bulk_results = notification_service.send_bulk_notification(
    user_ids=["user_001", "user_002"],
    template_id="welcome",
    data={"app_name": "MyApp", "user_name": "Valued Customer"}
)

print(f"Bulk notification results: {bulk_results}")

# Wait for processing
time.sleep(3)

# Check notification statuses
print("\n--- Notification Statuses ---")
for notification_id in notification_ids:
    status = notification_service.get_notification_status(notification_id)
    if status:
        print(f"Notification {notification_id}: {status['status']} via {status['channel']}")

# Get user notifications
print("\n--- User In-App Notifications ---")
user1_notifications = notification_service.get_user_notifications("user_001", NotificationType.IN_APP)
print(f"User 001 has {len(user1_notifications)} in-app notifications")

for notif in user1_notifications[:3]:  # Show first 3
    print(f"  - {notif['subject']}: {notif['body'][:50]}...")

# Get service statistics
print("\n--- Service Statistics ---")
stats = notification_service.get_service_stats()
print(f"Total notifications: {stats['total_notifications']}")
print(f"Queue size: {stats['queue_size']}")
print(f"Success rate: {stats['delivery_stats']['success_rate']:.1f}%")
print("Channel statistics:")
for channel, channel_stats in stats['channel_stats'].items():
    print(f"  {channel}: sent={channel_stats['sent']}, delivered={channel_stats['delivered']}, failed={channel_stats['failed']}")
```

## 📊 Advanced Notification Features

```python
class NotificationAnalytics:
    """Analytics and insights for notification performance"""
    
    def __init__(self, notification_service: NotificationService):
        self.notification_service = notification_service
        self.engagement_data = defaultdict(list)  # user_id -> engagement events
        
    def track_engagement(self, user_id: str, notification_id: str, action: str, timestamp: float = None):
        """Track user engagement with notifications"""
        
        if timestamp is None:
            timestamp = time.time()
        
        engagement_event = {
            'notification_id': notification_id,
            'action': action,  # 'opened', 'clicked', 'dismissed', 'converted'
            'timestamp': timestamp
        }
        
        self.engagement_data[user_id].append(engagement_event)
    
    def calculate_engagement_metrics(self, template_id: str = None, 
                                   channel: NotificationType = None,
                                   days_back: int = 30) -> Dict[str, Any]:
        """Calculate engagement metrics"""
        
        cutoff_time = time.time() - (days_back * 24 * 3600)
        
        # Filter notifications
        relevant_notifications = []
        
        for notification in self.notification_service.notifications.values():
            if notification.created_at < cutoff_time:
                continue
            
            if template_id and notification.template_id != template_id:
                continue
            
            if channel and notification.channel != channel:
                continue
            
            relevant_notifications.append(notification)
        
        if not relevant_notifications:
            return {'message': 'No notifications found for criteria'}
        
        # Calculate metrics
        total_sent = len(relevant_notifications)
        delivered = len([n for n in relevant_notifications if n.status == NotificationStatus.DELIVERED])
        
        # Engagement metrics
        opened = 0
        clicked = 0
        converted = 0
        
        for notification in relevant_notifications:
            user_engagements = self.engagement_data.get(notification.user_id, [])
            
            for engagement in user_engagements:
                if engagement['notification_id'] == notification.notification_id:
                    if engagement['action'] == 'opened':
                        opened += 1
                    elif engagement['action'] == 'clicked':
                        clicked += 1
                    elif engagement['action'] == 'converted':
                        converted += 1
        
        return {
            'period_days': days_back,
            'total_sent': total_sent,
            'delivered': delivered,
            'delivery_rate': (delivered / total_sent * 100) if total_sent > 0 else 0,
            'opened': opened,
            'open_rate': (opened / delivered * 100) if delivered > 0 else 0,
            'clicked': clicked,
            'click_rate': (clicked / delivered * 100) if delivered > 0 else 0,
            'converted': converted,
            'conversion_rate': (converted / delivered * 100) if delivered > 0 else 0,
            'template_id': template_id,
            'channel': channel.value if channel else 'all'
        }
    
    def get_best_performing_templates(self, metric: str = 'open_rate', limit: int = 10) -> List[Dict[str, Any]]:
        """Get best performing templates by metric"""
        
        template_performance = {}
        
        for template_id in self.notification_service.templates.keys():
            metrics = self.calculate_engagement_metrics(template_id=template_id)
            
            if 'message' not in metrics:  # Has data
                template_performance[template_id] = metrics
        
        # Sort by specified metric
        sorted_templates = sorted(template_performance.items(), 
                                key=lambda x: x[1].get(metric, 0), 
                                reverse=True)
        
        return [{'template_id': t[0], **t[1]} for t in sorted_templates[:limit]]
    
    def get_channel_performance(self) -> Dict[str, Dict[str, Any]]:
        """Get performance metrics by channel"""
        
        channel_metrics = {}
        
        for channel in NotificationType:
            metrics = self.calculate_engagement_metrics(channel=channel)
            if 'message' not in metrics:
                channel_metrics[channel.value] = metrics
        
        return channel_metrics
    
    def get_user_engagement_profile(self, user_id: str) -> Dict[str, Any]:
        """Get engagement profile for a user"""
        
        user_notifications = [n for n in self.notification_service.notifications.values() 
                            if n.user_id == user_id]
        
        user_engagements = self.engagement_data.get(user_id, [])
        
        if not user_notifications:
            return {'message': 'No notifications found for user'}
        
        # Calculate user-specific metrics
        total_received = len([n for n in user_notifications if n.status == NotificationStatus.DELIVERED])
        
        engagement_counts = defaultdict(int)
        for engagement in user_engagements:
            engagement_counts[engagement['action']] += 1
        
        # Preferred channels (based on engagement)
        channel_engagement = defaultdict(int)
        for engagement in user_engagements:
            for notification in user_notifications:
                if notification.notification_id == engagement['notification_id']:
                    channel_engagement[notification.channel.value] += 1
                    break
        
        preferred_channel = max(channel_engagement.items(), key=lambda x: x[1])[0] if channel_engagement else None
        
        return {
            'user_id': user_id,
            'total_notifications_received': total_received,
            'total_engagements': len(user_engagements),
            'engagement_breakdown': dict(engagement_counts),
            'engagement_rate': (len(user_engagements) / total_received * 100) if total_received > 0 else 0,
            'preferred_channel': preferred_channel,
            'channel_engagement': dict(channel_engagement)
        }

class PersonalizationEngine:
    """Personalize notifications based on user behavior and preferences"""
    
    def __init__(self, notification_service: NotificationService, analytics: NotificationAnalytics):
        self.notification_service = notification_service
        self.analytics = analytics
        self.user_segments = defaultdict(set)  # segment_name -> user_ids
        self.personalization_rules = {}
        
    def create_user_segment(self, segment_name: str, criteria: Dict[str, Any]):
        """Create user segment based on criteria"""
        
        matching_users = set()
        
        for user_id, user in self.notification_service.users.items():
            if self._user_matches_criteria(user, criteria):
                matching_users.add(user_id)
        
        self.user_segments[segment_name] = matching_users
        print(f"Created segment '{segment_name}' with {len(matching_users)} users")
        
        return matching_users
    
    def _user_matches_criteria(self, user: User, criteria: Dict[str, Any]) -> bool:
        """Check if user matches segmentation criteria"""
        
        # Location-based criteria
        if 'timezone' in criteria:
            if user.timezone != criteria['timezone']:
                return False
        
        # Preference-based criteria
        if 'preferred_channels' in criteria:
            user_channels = [ch for ch, enabled in user.preferences.get('channels', {}).items() if enabled]
            required_channels = criteria['preferred_channels']
            
            if not any(ch in user_channels for ch in required_channels):
                return False
        
        # Engagement-based criteria
        if 'engagement_level' in criteria:
            profile = self.analytics.get_user_engagement_profile(user.user_id)
            
            if 'message' in profile:  # No data
                return False
            
            engagement_rate = profile['engagement_rate']
            required_level = criteria['engagement_level']
            
            if required_level == 'high' and engagement_rate < 70:
                return False
            elif required_level == 'medium' and (engagement_rate < 30 or engagement_rate >= 70):
                return False
            elif required_level == 'low' and engagement_rate >= 30:
                return False
        
        return True
    
    def optimize_send_time(self, user_id: str) -> float:
        """Optimize send time based on user's historical engagement"""
        
        user_engagements = self.analytics.engagement_data.get(user_id, [])
        
        if not user_engagements:
            # Default to 9 AM in user's timezone
            return time.time() + 3600  # 1 hour from now (simplified)
        
        # Analyze engagement times
        engagement_hours = []
        
        for engagement in user_engagements:
            # Convert timestamp to hour of day
            hour = time.localtime(engagement['timestamp']).tm_hour
            engagement_hours.append(hour)
        
        if engagement_hours:
            # Find most common engagement hour
            from collections import Counter
            hour_counts = Counter(engagement_hours)
            optimal_hour = hour_counts.most_common(1)[0][0]
            
            # Calculate next occurrence of optimal hour
            current_time = time.localtime()
            
            if current_time.tm_hour < optimal_hour:
                # Today at optimal hour
                optimal_time = time.mktime((
                    current_time.tm_year, current_time.tm_mon, current_time.tm_mday,
                    optimal_hour, 0, 0, 0, 0, 0
                ))
            else:
                # Tomorrow at optimal hour
                import datetime
                tomorrow = datetime.datetime.now() + datetime.timedelta(days=1)
                optimal_time = time.mktime((
                    tomorrow.year, tomorrow.month, tomorrow.day,
                    optimal_hour, 0, 0, 0, 0, 0
                ))
            
            return optimal_time
        
        return time.time() + 3600  # Default: 1 hour from now
    
    def personalize_content(self, user_id: str, template: NotificationTemplate, 
                          data: Dict[str, Any]) -> Dict[str, Any]:
        """Personalize notification content for user"""
        
        user = self.notification_service.users.get(user_id)
        if not user:
            return data
        
        personalized_data = data.copy()
        
        # Add user-specific data
        personalized_data['user_name'] = user.user_id.replace('_', ' ').title()
        
        # Time-based personalization
        current_hour = time.localtime().tm_hour
        
        if current_hour < 12:
            personalized_data['time_greeting'] = 'Good morning'
        elif current_hour < 18:
            personalized_data['time_greeting'] = 'Good afternoon'
        else:
            personalized_data['time_greeting'] = 'Good evening'
        
        # Engagement-based personalization
        profile = self.analytics.get_user_engagement_profile(user_id)
        
        if 'message' not in profile:
            engagement_rate = profile['engagement_rate']
            
            if engagement_rate > 70:
                personalized_data['engagement_tone'] = 'enthusiastic'
            elif engagement_rate > 30:
                personalized_data['engagement_tone'] = 'friendly'
            else:
                personalized_data['engagement_tone'] = 'gentle'
        
        return personalized_data
    
    def recommend_channels(self, user_id: str, template: NotificationTemplate) -> List[NotificationType]:
        """Recommend best channels for user based on engagement history"""
        
        profile = self.analytics.get_user_engagement_profile(user_id)
        
        if 'message' in profile or not profile.get('channel_engagement'):
            # No engagement data, use template defaults
            return template.supported_channels
        
        # Sort channels by engagement
        channel_engagement = profile['channel_engagement']
        sorted_channels = sorted(channel_engagement.items(), key=lambda x: x[1], reverse=True)
        
        # Convert to NotificationType and filter by template support
        recommended = []
        
        for channel_name, _ in sorted_channels:
            try:
                channel = NotificationType(channel_name)
                if channel in template.supported_channels:
                    recommended.append(channel)
            except ValueError:
                continue
        
        # Add remaining supported channels
        for channel in template.supported_channels:
            if channel not in recommended:
                recommended.append(channel)
        
        return recommended

class A_B_TestingManager:
    """A/B testing for notification optimization"""
    
    def __init__(self, notification_service: NotificationService, analytics: NotificationAnalytics):
        self.notification_service = notification_service
        self.analytics = analytics
        self.active_tests = {}  # test_id -> test_config
        self.test_assignments = {}  # user_id -> {test_id: variant}
        
    def create_ab_test(self, test_id: str, test_config: Dict[str, Any]) -> bool:
        """Create A/B test"""
        
        required_fields = ['name', 'variants', 'traffic_split', 'success_metric']
        
        if not all(field in test_config for field in required_fields):
            print(f"Missing required fields for A/B test: {required_fields}")
            return False
        
        # Validate traffic split
        traffic_split = test_config['traffic_split']
        
        if not isinstance(traffic_split, dict) or sum(traffic_split.values()) != 100:
            print("Traffic split must be a dict with values summing to 100")
            return False
        
        # Validate variants exist
        variants = test_config['variants']
        
        if not all(variant in variants for variant in traffic_split.keys()):
            print("All variants in traffic_split must exist in variants")
            return False
        
        self.active_tests[test_id] = {
            **test_config,
            'created_at': time.time(),
            'status': 'active'
        }
        
        print(f"Created A/B test '{test_id}': {test_config['name']}")
        return True
    
    def assign_user_to_variant(self, user_id: str, test_id: str) -> Optional[str]:
        """Assign user to test variant"""
        
        if test_id not in self.active_tests:
            return None
        
        # Check if user already assigned
        if user_id in self.test_assignments and test_id in self.test_assignments[user_id]:
            return self.test_assignments[user_id][test_id]
        
        # Assign based on traffic split
        test_config = self.active_tests[test_id]
        traffic_split = test_config['traffic_split']
        
        # Use hash of user_id for consistent assignment
        user_hash = hash(user_id) % 100
        
        cumulative = 0
        for variant, percentage in traffic_split.items():
            cumulative += percentage
            
            if user_hash < cumulative:
                # Assign user to this variant
                if user_id not in self.test_assignments:
                    self.test_assignments[user_id] = {}
                
                self.test_assignments[user_id][test_id] = variant
                
                print(f"Assigned user {user_id} to variant '{variant}' for test {test_id}")
                return variant
        
        return None
    
    def send_test_notification(self, user_id: str, test_id: str, base_data: Dict[str, Any]) -> List[str]:
        """Send notification with A/B test variant"""
        
        if test_id not in self.active_tests:
            print(f"Test {test_id} not found")
            return []
        
        # Get user's variant
        variant = self.assign_user_to_variant(user_id, test_id)
        
        if not variant:
            print(f"Could not assign user {user_id} to test {test_id}")
            return []
        
        # Get variant configuration
        test_config = self.active_tests[test_id]
        variant_config = test_config['variants'][variant]
        
        # Merge base data with variant data
        notification_data = {**base_data, **variant_config.get('data', {})}
        
        # Send notification
        notification_ids = self.notification_service.send_notification(
            user_id=user_id,
            template_id=variant_config['template_id'],
            channels=variant_config.get('channels'),
            data=notification_data,
            priority=variant_config.get('priority')
        )
        
        # Track test participation
        self._track_test_event(user_id, test_id, variant, 'sent', notification_ids)
        
        return notification_ids
    
    def _track_test_event(self, user_id: str, test_id: str, variant: str, 
                         event: str, notification_ids: List[str]):
        """Track A/B test event"""
        
        # In a real implementation, this would be stored in a database
        print(f"A/B Test Event - User: {user_id}, Test: {test_id}, Variant: {variant}, Event: {event}")
    
    def analyze_test_results(self, test_id: str) -> Dict[str, Any]:
        """Analyze A/B test results"""
        
        if test_id not in self.active_tests:
            return {'error': 'Test not found'}
        
        test_config = self.active_tests[test_id]
        success_metric = test_config['success_metric']
        
        # Collect data for each variant
        variant_results = {}
        
        for variant in test_config['variants'].keys():
            # Get users assigned to this variant
            variant_users = [
                user_id for user_id, assignments in self.test_assignments.items()
                if assignments.get(test_id) == variant
            ]
            
            if not variant_users:
                variant_results[variant] = {
                    'users': 0,
                    'metric_value': 0,
                    'confidence': 0
                }
                continue
            
            # Calculate metric for these users
            if success_metric == 'engagement_rate':
                total_engagement = 0
                total_users = len(variant_users)
                
                for user_id in variant_users:
                    profile = self.analytics.get_user_engagement_profile(user_id)
                    if 'message' not in profile:
                        total_engagement += profile['engagement_rate']
                
                metric_value = total_engagement / total_users if total_users > 0 else 0
                
            else:
                metric_value = 0  # Placeholder for other metrics
            
            variant_results[variant] = {
                'users': len(variant_users),
                'metric_value': metric_value,
                'confidence': self._calculate_confidence(len(variant_users), metric_value)
            }
        
        return {
            'test_id': test_id,
            'test_name': test_config['name'],
            'success_metric': success_metric,
            'variant_results': variant_results,
            'recommendation': self._get_test_recommendation(variant_results)
        }
    
    def _calculate_confidence(self, sample_size: int, metric_value: float) -> float:
        """Calculate statistical confidence (simplified)"""
        
        if sample_size < 30:
            return 0.0  # Not enough data
        elif sample_size < 100:
            return 0.8
        elif sample_size < 500:
            return 0.9
        else:
            return 0.95
    
    def _get_test_recommendation(self, variant_results: Dict[str, Dict[str, Any]]) -> Dict[str, Any]:
        """Get recommendation based on test results"""
        
        if not variant_results:
            return {'action': 'insufficient_data'}
        
        # Find best performing variant
        best_variant = max(variant_results.items(), key=lambda x: x[1]['metric_value'])
        
        # Check if we have sufficient confidence
        if best_variant[1]['confidence'] < 0.8:
            return {
                'action': 'continue_test',
                'reason': 'Insufficient statistical confidence'
            }
        
        return {
            'action': 'implement_winner',
            'winner': best_variant[0],
            'improvement': best_variant[1]['metric_value'],
            'confidence': best_variant[1]['confidence']
        }

# Example usage of advanced features
print("\n=== Advanced Notification Features Demo ===")

# Create analytics and personalization engines
analytics = NotificationAnalytics(notification_service)
personalization = PersonalizationEngine(notification_service, analytics)
ab_testing = A_B_TestingManager(notification_service, analytics)

# Simulate some user engagement
print("\n--- Simulating User Engagement ---")
for notification_id in notification_ids:
    # Simulate user opening notification
    analytics.track_engagement("user_001", notification_id, "opened")
    
    # 50% chance of clicking
    if random.random() < 0.5:
        analytics.track_engagement("user_001", notification_id, "clicked")
        
        # 20% chance of converting
        if random.random() < 0.2:
            analytics.track_engagement("user_001", notification_id, "converted")

# Calculate engagement metrics
print("\n--- Engagement Metrics ---")
welcome_metrics = analytics.calculate_engagement_metrics(template_id="welcome")
print(f"Welcome template metrics: {welcome_metrics}")

# User engagement profile
print("\n--- User Engagement Profile ---")
user_profile = analytics.get_user_engagement_profile("user_001")
print(f"User 001 profile: {user_profile}")

# Create user segments
print("\n--- User Segmentation ---")
high_engagement_users = personalization.create_user_segment("high_engagement", {
    "engagement_level": "high"
})

email_lovers = personalization.create_user_segment("email_lovers", {
    "preferred_channels": ["email"]
})

# Personalized notification
print("\n--- Personalized Notification ---")
optimal_time = personalization.optimize_send_time("user_001")
print(f"Optimal send time for user_001: {time.ctime(optimal_time)}")

personalized_data = personalization.personalize_content("user_001", welcome_template, {
    "app_name": "MyApp"
})
print(f"Personalized data: {personalized_data}")

# A/B Testing
print("\n--- A/B Testing ---")
ab_test_config = {
    "name": "Subject Line Test",
    "variants": {
        "control": {
            "template_id": "welcome",
            "data": {"subject_variation": "Welcome to MyApp!"}
        },
        "variant_a": {
            "template_id": "welcome", 
            "data": {"subject_variation": "You're in! Welcome to MyApp"}
        },
        "variant_b": {
            "template_id": "welcome",
            "data": {"subject_variation": "MyApp: Your journey starts now"}
        }
    },
    "traffic_split": {
        "control": 34,
        "variant_a": 33,
        "variant_b": 33
    },
    "success_metric": "engagement_rate"
}

ab_testing.create_ab_test("welcome_subject_test", ab_test_config)

# Send A/B test notification
test_notification_ids = ab_testing.send_test_notification("user_002", "welcome_subject_test", {
    "app_name": "MyApp",
    "user_name": "Jane"
})

print(f"Sent A/B test notification: {test_notification_ids}")

# Analyze test (would need more data in real scenario)
time.sleep(1)
test_results = ab_testing.analyze_test_results("welcome_subject_test")
print(f"A/B test results: {test_results}")

print("\n--- Advanced Features Demo Completed ---")
```

## 📚 Conclusion

Notification systems are critical infrastructure that connects applications with users, enabling real-time communication, engagement, and critical alerts. From simple push notifications to sophisticated personalization engines with A/B testing, these systems must balance reliability, performance, and user experience.

**Key Takeaways:**

1. **Multi-Channel Strategy**: Support multiple delivery channels with fallback mechanisms
2. **Respect User Preferences**: Honor notification preferences and quiet hours
3. **Ensure Delivery**: Implement retry logic and delivery confirmations
4. **Measure and Optimize**: Track engagement metrics and continuously improve
5. **Personalize Thoughtfully**: Use data to personalize without being intrusive

The future of notification systems includes AI-powered content optimization, cross-platform synchronization, and advanced privacy controls. Whether you're building a social media app, e-commerce platform, or enterprise system, understanding notification architecture is essential for creating engaging user experiences.

Remember: great notification systems don't just deliver messages—they deliver the right message to the right person at the right time through their preferred channel, enhancing rather than interrupting their experience.
