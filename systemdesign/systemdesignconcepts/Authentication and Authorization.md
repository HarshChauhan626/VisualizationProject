# Authentication and Authorization: Digital Identity and Access Control

## 🎯 What are Authentication and Authorization?

Authentication and authorization are like a sophisticated security system for a high-security building. Authentication is like showing your ID card to prove who you are ("I am John Smith"), while authorization is like the security system checking what floors and rooms you're allowed to access ("John Smith can access floors 1-5 but not the executive suite"). Together, they ensure that only the right people can access the right resources at the right times.

## 🏗️ Core Concepts

### The Security Building Analogy
- **Authentication**: Proving your identity at the front desk
- **Authorization**: Checking your access permissions for specific areas
- **Single Sign-On (SSO)**: One keycard that works throughout the building
- **Multi-Factor Authentication (MFA)**: ID card + fingerprint + PIN
- **Role-Based Access**: Different keycards for employees, visitors, executives
- **Session Management**: Temporary visitor badges that expire

### Why Authentication and Authorization Matter
1. **Security**: Protect sensitive data and resources from unauthorized access
2. **Compliance**: Meet regulatory requirements (GDPR, HIPAA, SOX)
3. **User Experience**: Seamless access to authorized resources
4. **Audit Trail**: Track who accessed what and when
5. **Scalability**: Manage access for thousands or millions of users

## 🔐 Authentication Systems

```python
import hashlib
import hmac
import jwt
import time
import secrets
import base64
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
import threading
from datetime import datetime, timedelta
import re

class AuthMethod(Enum):
    PASSWORD = "password"
    TOKEN = "token"
    OAUTH = "oauth"
    SAML = "saml"
    BIOMETRIC = "biometric"
    MFA = "mfa"

class UserRole(Enum):
    ADMIN = "admin"
    USER = "user"
    MODERATOR = "moderator"
    GUEST = "guest"
    SERVICE = "service"

@dataclass
class User:
    user_id: str
    username: str
    email: str
    password_hash: str
    salt: str
    roles: List[UserRole]
    permissions: List[str]
    created_at: float
    last_login: Optional[float]
    is_active: bool
    mfa_enabled: bool
    mfa_secret: Optional[str]
    failed_login_attempts: int
    account_locked_until: Optional[float]
    metadata: Dict[str, Any]

@dataclass
class Session:
    session_id: str
    user_id: str
    created_at: float
    expires_at: float
    ip_address: str
    user_agent: str
    is_active: bool
    last_activity: float
    permissions: List[str]
    metadata: Dict[str, Any]

class PasswordManager:
    """Secure password hashing and validation"""
    
    def __init__(self):
        self.min_length = 8
        self.require_uppercase = True
        self.require_lowercase = True
        self.require_digits = True
        self.require_special = True
        self.hash_iterations = 100000
    
    def generate_salt(self) -> str:
        """Generate cryptographically secure salt"""
        return base64.b64encode(secrets.token_bytes(32)).decode('utf-8')
    
    def hash_password(self, password: str, salt: str = None) -> Tuple[str, str]:
        """Hash password with salt using PBKDF2"""
        if salt is None:
            salt = self.generate_salt()
        
        # Use PBKDF2 with SHA-256
        password_hash = hashlib.pbkdf2_hmac(
            'sha256',
            password.encode('utf-8'),
            salt.encode('utf-8'),
            self.hash_iterations
        )
        
        hash_b64 = base64.b64encode(password_hash).decode('utf-8')
        return hash_b64, salt
    
    def verify_password(self, password: str, stored_hash: str, salt: str) -> bool:
        """Verify password against stored hash"""
        computed_hash, _ = self.hash_password(password, salt)
        return hmac.compare_digest(computed_hash, stored_hash)
    
    def validate_password_strength(self, password: str) -> Dict[str, Any]:
        """Validate password meets security requirements"""
        
        issues = []
        
        if len(password) < self.min_length:
            issues.append(f"Password must be at least {self.min_length} characters")
        
        if self.require_uppercase and not re.search(r'[A-Z]', password):
            issues.append("Password must contain uppercase letters")
        
        if self.require_lowercase and not re.search(r'[a-z]', password):
            issues.append("Password must contain lowercase letters")
        
        if self.require_digits and not re.search(r'\d', password):
            issues.append("Password must contain digits")
        
        if self.require_special and not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
            issues.append("Password must contain special characters")
        
        # Check for common patterns
        if password.lower() in ['password', '123456', 'qwerty', 'admin']:
            issues.append("Password is too common")
        
        return {
            'valid': len(issues) == 0,
            'issues': issues,
            'strength_score': self._calculate_strength_score(password)
        }
    
    def _calculate_strength_score(self, password: str) -> int:
        """Calculate password strength score (0-100)"""
        score = 0
        
        # Length bonus
        score += min(25, len(password) * 2)
        
        # Character variety bonus
        if re.search(r'[a-z]', password):
            score += 10
        if re.search(r'[A-Z]', password):
            score += 10
        if re.search(r'\d', password):
            score += 10
        if re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
            score += 15
        
        # Complexity bonus
        unique_chars = len(set(password))
        score += min(20, unique_chars)
        
        # Pattern penalty
        if re.search(r'(.)\1{2,}', password):  # Repeated characters
            score -= 10
        if re.search(r'(012|123|234|345|456|567|678|789|890)', password):  # Sequential
            score -= 10
        
        return max(0, min(100, score))

class JWTManager:
    """JSON Web Token management for stateless authentication"""
    
    def __init__(self, secret_key: str, algorithm: str = 'HS256'):
        self.secret_key = secret_key
        self.algorithm = algorithm
        self.default_expiry = 3600  # 1 hour
        self.refresh_expiry = 86400 * 7  # 7 days
    
    def generate_token(self, user_id: str, permissions: List[str], 
                      expires_in: int = None) -> str:
        """Generate JWT token for user"""
        
        if expires_in is None:
            expires_in = self.default_expiry
        
        payload = {
            'user_id': user_id,
            'permissions': permissions,
            'iat': int(time.time()),
            'exp': int(time.time() + expires_in),
            'token_type': 'access'
        }
        
        return jwt.encode(payload, self.secret_key, algorithm=self.algorithm)
    
    def generate_refresh_token(self, user_id: str) -> str:
        """Generate refresh token for token renewal"""
        
        payload = {
            'user_id': user_id,
            'iat': int(time.time()),
            'exp': int(time.time() + self.refresh_expiry),
            'token_type': 'refresh'
        }
        
        return jwt.encode(payload, self.secret_key, algorithm=self.algorithm)
    
    def verify_token(self, token: str) -> Dict[str, Any]:
        """Verify and decode JWT token"""
        
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
            
            return {
                'valid': True,
                'payload': payload,
                'user_id': payload.get('user_id'),
                'permissions': payload.get('permissions', []),
                'token_type': payload.get('token_type', 'access')
            }
            
        except jwt.ExpiredSignatureError:
            return {'valid': False, 'error': 'Token has expired'}
        except jwt.InvalidTokenError:
            return {'valid': False, 'error': 'Invalid token'}
    
    def refresh_access_token(self, refresh_token: str, permissions: List[str]) -> Dict[str, Any]:
        """Generate new access token using refresh token"""
        
        verification = self.verify_token(refresh_token)
        
        if not verification['valid']:
            return verification
        
        if verification['payload'].get('token_type') != 'refresh':
            return {'valid': False, 'error': 'Invalid token type'}
        
        user_id = verification['user_id']
        new_access_token = self.generate_token(user_id, permissions)
        
        return {
            'valid': True,
            'access_token': new_access_token,
            'user_id': user_id
        }

class MFAManager:
    """Multi-Factor Authentication management"""
    
    def __init__(self):
        self.totp_window = 30  # 30 second window
        self.backup_codes_count = 10
        
    def generate_mfa_secret(self) -> str:
        """Generate MFA secret for TOTP"""
        return base64.b32encode(secrets.token_bytes(20)).decode('utf-8')
    
    def generate_totp_code(self, secret: str, timestamp: int = None) -> str:
        """Generate TOTP code for given secret"""
        
        if timestamp is None:
            timestamp = int(time.time())
        
        # Calculate time step
        time_step = timestamp // self.totp_window
        
        # Convert to bytes
        time_bytes = time_step.to_bytes(8, byteorder='big')
        secret_bytes = base64.b32decode(secret)
        
        # Generate HMAC
        hmac_hash = hmac.new(secret_bytes, time_bytes, hashlib.sha1).digest()
        
        # Dynamic truncation
        offset = hmac_hash[-1] & 0x0f
        truncated = hmac_hash[offset:offset + 4]
        code = int.from_bytes(truncated, byteorder='big') & 0x7fffffff
        
        # Return 6-digit code
        return f"{code % 1000000:06d}"
    
    def verify_totp_code(self, secret: str, provided_code: str, 
                        timestamp: int = None) -> bool:
        """Verify TOTP code with time window tolerance"""
        
        if timestamp is None:
            timestamp = int(time.time())
        
        # Check current time and ±1 time step for clock skew
        for time_offset in [-1, 0, 1]:
            check_timestamp = timestamp + (time_offset * self.totp_window)
            expected_code = self.generate_totp_code(secret, check_timestamp)
            
            if hmac.compare_digest(expected_code, provided_code):
                return True
        
        return False
    
    def generate_backup_codes(self) -> List[str]:
        """Generate backup codes for MFA recovery"""
        
        codes = []
        for _ in range(self.backup_codes_count):
            # Generate 8-character alphanumeric code
            code = ''.join(secrets.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789') 
                          for _ in range(8))
            codes.append(code)
        
        return codes

class AuthenticationService:
    """Main authentication service"""
    
    def __init__(self):
        self.users: Dict[str, User] = {}
        self.sessions: Dict[str, Session] = {}
        self.password_manager = PasswordManager()
        self.jwt_manager = JWTManager(secrets.token_urlsafe(32))
        self.mfa_manager = MFAManager()
        
        # Security settings
        self.max_login_attempts = 5
        self.lockout_duration = 900  # 15 minutes
        self.session_timeout = 3600  # 1 hour
        
        # Audit logging
        self.audit_log: List[Dict[str, Any]] = []
        
        self.lock = threading.RLock()
    
    def register_user(self, username: str, email: str, password: str, 
                     roles: List[UserRole] = None) -> Dict[str, Any]:
        """Register new user"""
        
        with self.lock:
            # Validate input
            if not username or not email or not password:
                return {'success': False, 'error': 'Missing required fields'}
            
            # Check if user already exists
            if any(u.username == username or u.email == email for u in self.users.values()):
                return {'success': False, 'error': 'User already exists'}
            
            # Validate password strength
            password_validation = self.password_manager.validate_password_strength(password)
            if not password_validation['valid']:
                return {
                    'success': False, 
                    'error': 'Password does not meet requirements',
                    'issues': password_validation['issues']
                }
            
            # Hash password
            password_hash, salt = self.password_manager.hash_password(password)
            
            # Create user
            user_id = f"user_{int(time.time())}_{secrets.randbelow(10000)}"
            
            user = User(
                user_id=user_id,
                username=username,
                email=email,
                password_hash=password_hash,
                salt=salt,
                roles=roles or [UserRole.USER],
                permissions=self._get_default_permissions(roles or [UserRole.USER]),
                created_at=time.time(),
                last_login=None,
                is_active=True,
                mfa_enabled=False,
                mfa_secret=None,
                failed_login_attempts=0,
                account_locked_until=None,
                metadata={}
            )
            
            self.users[user_id] = user
            
            # Audit log
            self._log_audit_event('user_registered', user_id, {'username': username, 'email': email})
            
            return {
                'success': True,
                'user_id': user_id,
                'message': 'User registered successfully'
            }
    
    def authenticate(self, username: str, password: str, 
                    mfa_code: str = None, ip_address: str = None) -> Dict[str, Any]:
        """Authenticate user with credentials"""
        
        with self.lock:
            # Find user
            user = self._find_user_by_username(username)
            
            if not user:
                self._log_audit_event('login_failed', None, {'username': username, 'reason': 'user_not_found'})
                return {'success': False, 'error': 'Invalid credentials'}
            
            # Check if account is locked
            if user.account_locked_until and time.time() < user.account_locked_until:
                remaining_time = int(user.account_locked_until - time.time())
                return {
                    'success': False, 
                    'error': f'Account locked. Try again in {remaining_time} seconds'
                }
            
            # Check if account is active
            if not user.is_active:
                return {'success': False, 'error': 'Account is disabled'}
            
            # Verify password
            if not self.password_manager.verify_password(password, user.password_hash, user.salt):
                user.failed_login_attempts += 1
                
                if user.failed_login_attempts >= self.max_login_attempts:
                    user.account_locked_until = time.time() + self.lockout_duration
                    self._log_audit_event('account_locked', user.user_id, {'reason': 'too_many_failed_attempts'})
                
                self._log_audit_event('login_failed', user.user_id, {'reason': 'invalid_password'})
                return {'success': False, 'error': 'Invalid credentials'}
            
            # Check MFA if enabled
            if user.mfa_enabled:
                if not mfa_code:
                    return {
                        'success': False, 
                        'error': 'MFA code required',
                        'mfa_required': True
                    }
                
                if not self.mfa_manager.verify_totp_code(user.mfa_secret, mfa_code):
                    user.failed_login_attempts += 1
                    self._log_audit_event('login_failed', user.user_id, {'reason': 'invalid_mfa'})
                    return {'success': False, 'error': 'Invalid MFA code'}
            
            # Successful login
            user.failed_login_attempts = 0
            user.account_locked_until = None
            user.last_login = time.time()
            
            # Create session
            session = self._create_session(user, ip_address)
            
            # Generate JWT tokens
            access_token = self.jwt_manager.generate_token(user.user_id, user.permissions)
            refresh_token = self.jwt_manager.generate_refresh_token(user.user_id)
            
            self._log_audit_event('login_successful', user.user_id, {'ip_address': ip_address})
            
            return {
                'success': True,
                'user_id': user.user_id,
                'session_id': session.session_id,
                'access_token': access_token,
                'refresh_token': refresh_token,
                'permissions': user.permissions,
                'mfa_enabled': user.mfa_enabled
            }
    
    def enable_mfa(self, user_id: str) -> Dict[str, Any]:
        """Enable MFA for user"""
        
        with self.lock:
            user = self.users.get(user_id)
            if not user:
                return {'success': False, 'error': 'User not found'}
            
            if user.mfa_enabled:
                return {'success': False, 'error': 'MFA already enabled'}
            
            # Generate MFA secret
            mfa_secret = self.mfa_manager.generate_mfa_secret()
            backup_codes = self.mfa_manager.generate_backup_codes()
            
            user.mfa_secret = mfa_secret
            user.mfa_enabled = True
            
            self._log_audit_event('mfa_enabled', user_id, {})
            
            return {
                'success': True,
                'mfa_secret': mfa_secret,
                'backup_codes': backup_codes,
                'qr_code_url': f"otpauth://totp/{user.username}?secret={mfa_secret}&issuer=MyApp"
            }
    
    def _find_user_by_username(self, username: str) -> Optional[User]:
        """Find user by username or email"""
        for user in self.users.values():
            if user.username == username or user.email == username:
                return user
        return None
    
    def _create_session(self, user: User, ip_address: str = None) -> Session:
        """Create new session for user"""
        
        session_id = f"sess_{int(time.time())}_{secrets.randbelow(100000)}"
        
        session = Session(
            session_id=session_id,
            user_id=user.user_id,
            created_at=time.time(),
            expires_at=time.time() + self.session_timeout,
            ip_address=ip_address or 'unknown',
            user_agent='unknown',
            is_active=True,
            last_activity=time.time(),
            permissions=user.permissions.copy(),
            metadata={}
        )
        
        self.sessions[session_id] = session
        return session
    
    def _get_default_permissions(self, roles: List[UserRole]) -> List[str]:
        """Get default permissions for roles"""
        
        permissions = set()
        
        for role in roles:
            if role == UserRole.ADMIN:
                permissions.update(['read', 'write', 'delete', 'admin', 'user_management'])
            elif role == UserRole.MODERATOR:
                permissions.update(['read', 'write', 'moderate'])
            elif role == UserRole.USER:
                permissions.update(['read', 'write'])
            elif role == UserRole.GUEST:
                permissions.update(['read'])
            elif role == UserRole.SERVICE:
                permissions.update(['api_access'])
        
        return list(permissions)
    
    def _log_audit_event(self, event_type: str, user_id: str, details: Dict[str, Any]):
        """Log audit event"""
        
        audit_entry = {
            'timestamp': time.time(),
            'event_type': event_type,
            'user_id': user_id,
            'details': details
        }
        
        self.audit_log.append(audit_entry)
        
        # Keep only recent audit logs
        if len(self.audit_log) > 10000:
            self.audit_log = self.audit_log[-10000:]
    
    def get_user_info(self, user_id: str) -> Dict[str, Any]:
        """Get user information"""
        
        user = self.users.get(user_id)
        if not user:
            return {'success': False, 'error': 'User not found'}
        
        return {
            'success': True,
            'user': {
                'user_id': user.user_id,
                'username': user.username,
                'email': user.email,
                'roles': [role.value for role in user.roles],
                'permissions': user.permissions,
                'created_at': user.created_at,
                'last_login': user.last_login,
                'is_active': user.is_active,
                'mfa_enabled': user.mfa_enabled
            }
        }

# Example usage
print("=== Authentication System Demo ===")

# Create authentication service
auth_service = AuthenticationService()

# Register users
print("\n--- User Registration ---")
admin_result = auth_service.register_user(
    "admin", "admin@example.com", "AdminPass123!", [UserRole.ADMIN]
)
print(f"Admin registration: {admin_result['success']}")

user_result = auth_service.register_user(
    "john_doe", "john@example.com", "SecurePass456!"
)
print(f"User registration: {user_result['success']}")

# Test weak password
weak_result = auth_service.register_user(
    "weak_user", "weak@example.com", "123"
)
print(f"Weak password registration: {weak_result['success']} - {weak_result.get('error', '')}")

# Test authentication
print("\n--- Authentication ---")
login_result = auth_service.authenticate("john_doe", "SecurePass456!", ip_address="192.168.1.100")
print(f"Login successful: {login_result['success']}")

if login_result['success']:
    print(f"Access token: {login_result['access_token'][:50]}...")
    print(f"Permissions: {login_result['permissions']}")

# Test MFA
print("\n--- Multi-Factor Authentication ---")
if user_result['success']:
    user_id = user_result['user_id']
    
    # Enable MFA
    mfa_result = auth_service.enable_mfa(user_id)
    print(f"MFA enabled: {mfa_result['success']}")
    
    if mfa_result['success']:
        print(f"MFA Secret: {mfa_result['mfa_secret']}")
        print(f"QR Code URL: {mfa_result['qr_code_url']}")
        
        # Generate TOTP code
        current_code = auth_service.mfa_manager.generate_totp_code(mfa_result['mfa_secret'])
        print(f"Current TOTP code: {current_code}")
        
        # Test login with MFA
        mfa_login = auth_service.authenticate("john_doe", "SecurePass456!", current_code, "192.168.1.100")
        print(f"MFA login successful: {mfa_login['success']}")

# Test JWT token verification
print("\n--- JWT Token Verification ---")
if login_result['success']:
    token = login_result['access_token']
    verification = auth_service.jwt_manager.verify_token(token)
    print(f"Token valid: {verification['valid']}")
    print(f"User ID from token: {verification.get('user_id')}")
    print(f"Permissions from token: {verification.get('permissions')}")

print("\n--- Authentication Demo Completed ---")
```

## 🛡️ Authorization and RBAC

```python
class Permission:
    """Individual permission"""
    
    def __init__(self, name: str, resource: str, action: str, conditions: Dict[str, Any] = None):
        self.name = name
        self.resource = resource
        self.action = action
        self.conditions = conditions or {}
    
    def __str__(self):
        return f"{self.action}:{self.resource}"

class Role:
    """Role with permissions"""
    
    def __init__(self, name: str, description: str):
        self.name = name
        self.description = description
        self.permissions: List[Permission] = []
        self.parent_roles: List[str] = []
    
    def add_permission(self, permission: Permission):
        self.permissions.append(permission)
    
    def has_permission(self, resource: str, action: str) -> bool:
        return any(p.resource == resource and p.action == action 
                  for p in self.permissions)

class AuthorizationService:
    """Role-Based Access Control (RBAC) service"""
    
    def __init__(self):
        self.roles: Dict[str, Role] = {}
        self.user_roles: Dict[str, List[str]] = {}
        self.permissions: Dict[str, Permission] = {}
        self.access_log: List[Dict[str, Any]] = []
        
        self._setup_default_roles()
    
    def _setup_default_roles(self):
        """Set up default roles and permissions"""
        
        # Create permissions
        permissions = [
            Permission("read_users", "users", "read"),
            Permission("write_users", "users", "write"),
            Permission("delete_users", "users", "delete"),
            Permission("read_posts", "posts", "read"),
            Permission("write_posts", "posts", "write"),
            Permission("delete_posts", "posts", "delete"),
            Permission("moderate_content", "content", "moderate"),
            Permission("admin_access", "system", "admin")
        ]
        
        for perm in permissions:
            self.permissions[perm.name] = perm
        
        # Create roles
        guest_role = Role("guest", "Guest user with read-only access")
        guest_role.add_permission(self.permissions["read_posts"])
        
        user_role = Role("user", "Regular user")
        user_role.add_permission(self.permissions["read_users"])
        user_role.add_permission(self.permissions["read_posts"])
        user_role.add_permission(self.permissions["write_posts"])
        
        moderator_role = Role("moderator", "Content moderator")
        moderator_role.parent_roles = ["user"]
        moderator_role.add_permission(self.permissions["moderate_content"])
        moderator_role.add_permission(self.permissions["delete_posts"])
        
        admin_role = Role("admin", "System administrator")
        admin_role.parent_roles = ["moderator"]
        admin_role.add_permission(self.permissions["write_users"])
        admin_role.add_permission(self.permissions["delete_users"])
        admin_role.add_permission(self.permissions["admin_access"])
        
        self.roles["guest"] = guest_role
        self.roles["user"] = user_role
        self.roles["moderator"] = moderator_role
        self.roles["admin"] = admin_role
    
    def assign_role(self, user_id: str, role_name: str) -> bool:
        """Assign role to user"""
        
        if role_name not in self.roles:
            return False
        
        if user_id not in self.user_roles:
            self.user_roles[user_id] = []
        
        if role_name not in self.user_roles[user_id]:
            self.user_roles[user_id].append(role_name)
        
        return True
    
    def check_permission(self, user_id: str, resource: str, action: str, 
                        context: Dict[str, Any] = None) -> Dict[str, Any]:
        """Check if user has permission for action on resource"""
        
        # Get user roles (including inherited roles)
        user_roles = self._get_all_user_roles(user_id)
        
        # Check permissions
        has_permission = False
        matched_permissions = []
        
        for role_name in user_roles:
            role = self.roles.get(role_name)
            if not role:
                continue
            
            for permission in role.permissions:
                if permission.resource == resource and permission.action == action:
                    # Check conditions if any
                    if self._check_permission_conditions(permission, context or {}):
                        has_permission = True
                        matched_permissions.append(permission.name)
        
        # Log access attempt
        self._log_access_attempt(user_id, resource, action, has_permission, context)
        
        return {
            'allowed': has_permission,
            'user_id': user_id,
            'resource': resource,
            'action': action,
            'matched_permissions': matched_permissions,
            'user_roles': user_roles
        }
    
    def _get_all_user_roles(self, user_id: str) -> List[str]:
        """Get all roles for user including inherited roles"""
        
        direct_roles = self.user_roles.get(user_id, [])
        all_roles = set(direct_roles)
        
        # Add parent roles recursively
        for role_name in direct_roles:
            parent_roles = self._get_parent_roles(role_name)
            all_roles.update(parent_roles)
        
        return list(all_roles)
    
    def _get_parent_roles(self, role_name: str) -> List[str]:
        """Get parent roles recursively"""
        
        role = self.roles.get(role_name)
        if not role or not role.parent_roles:
            return []
        
        parent_roles = set(role.parent_roles)
        
        # Recursively get parent roles
        for parent_role in role.parent_roles:
            parent_roles.update(self._get_parent_roles(parent_role))
        
        return list(parent_roles)
    
    def _check_permission_conditions(self, permission: Permission, 
                                   context: Dict[str, Any]) -> bool:
        """Check if permission conditions are met"""
        
        if not permission.conditions:
            return True
        
        for condition_key, condition_value in permission.conditions.items():
            context_value = context.get(condition_key)
            
            if context_value != condition_value:
                return False
        
        return True
    
    def _log_access_attempt(self, user_id: str, resource: str, action: str, 
                          allowed: bool, context: Dict[str, Any]):
        """Log access attempt for auditing"""
        
        log_entry = {
            'timestamp': time.time(),
            'user_id': user_id,
            'resource': resource,
            'action': action,
            'allowed': allowed,
            'context': context
        }
        
        self.access_log.append(log_entry)
        
        # Keep only recent logs
        if len(self.access_log) > 10000:
            self.access_log = self.access_log[-10000:]
    
    def get_user_permissions(self, user_id: str) -> Dict[str, Any]:
        """Get all permissions for user"""
        
        user_roles = self._get_all_user_roles(user_id)
        all_permissions = []
        
        for role_name in user_roles:
            role = self.roles.get(role_name)
            if role:
                for permission in role.permissions:
                    all_permissions.append({
                        'name': permission.name,
                        'resource': permission.resource,
                        'action': permission.action,
                        'from_role': role_name
                    })
        
        return {
            'user_id': user_id,
            'roles': user_roles,
            'permissions': all_permissions
        }

# Example usage
print("\n=== Authorization System Demo ===")

# Create authorization service
authz_service = AuthorizationService()

# Assign roles to users
user_id = "user_123"
admin_id = "admin_456"

authz_service.assign_role(user_id, "user")
authz_service.assign_role(admin_id, "admin")

# Test permissions
print("\n--- Permission Checks ---")

# User trying to read posts (should be allowed)
result1 = authz_service.check_permission(user_id, "posts", "read")
print(f"User read posts: {result1['allowed']}")

# User trying to delete users (should be denied)
result2 = authz_service.check_permission(user_id, "users", "delete")
print(f"User delete users: {result2['allowed']}")

# Admin trying to delete users (should be allowed)
result3 = authz_service.check_permission(admin_id, "users", "delete")
print(f"Admin delete users: {result3['allowed']}")

# Get user permissions
print("\n--- User Permissions ---")
user_perms = authz_service.get_user_permissions(user_id)
print(f"User roles: {user_perms['roles']}")
print("User permissions:")
for perm in user_perms['permissions']:
    print(f"  {perm['action']}:{perm['resource']} (from {perm['from_role']})")

admin_perms = authz_service.get_user_permissions(admin_id)
print(f"\nAdmin roles: {admin_perms['roles']}")
print(f"Admin permission count: {len(admin_perms['permissions'])}")

print("\n--- Authorization Demo Completed ---")
```

## 📚 Conclusion

Authentication and authorization form the security backbone of modern applications, ensuring that users are who they claim to be and can only access resources they're permitted to use. From password-based authentication to sophisticated RBAC systems with MFA, these systems must balance security, usability, and scalability.

**Key Takeaways:**

1. **Defense in Depth**: Layer multiple security mechanisms (passwords, MFA, tokens)
2. **Principle of Least Privilege**: Grant minimum necessary permissions
3. **Audit Everything**: Log all authentication and authorization events
4. **Plan for Scale**: Design systems that work for millions of users
5. **Stay Current**: Security threats evolve, so must your defenses

The future includes passwordless authentication, zero-trust architectures, and AI-powered threat detection. Whether building consumer apps or enterprise systems, robust authentication and authorization are essential for protecting users and data.

Remember: security is not a feature—it's a fundamental requirement that must be designed in from the beginning and continuously maintained and improved.
