# Microservices Architecture: Building Scalable Distributed Systems

## 🎯 What is Microservices Architecture?

Microservices architecture is like organizing a large corporation into specialized departments instead of having everyone work in one giant room. Each department (microservice) has its own expertise, resources, and responsibilities, but they all collaborate to achieve the company's goals. This approach enables teams to work independently, scale efficiently, and adapt quickly to changing requirements.

## 🏗️ Core Concepts

### The Corporate Department Analogy
- **Monolith**: Everyone works in one giant open office
- **Microservices**: Specialized departments (HR, Finance, Engineering, Marketing)
- **Communication**: Departments communicate through well-defined protocols (APIs)
- **Independence**: Each department can upgrade their tools and processes independently
- **Scalability**: Hire more people for busy departments without affecting others

### Why Microservices Matter
1. **Independent Deployment**: Deploy services without affecting others
2. **Technology Diversity**: Use the best technology for each service
3. **Team Autonomy**: Small teams can own entire services
4. **Fault Isolation**: Failures in one service don't bring down the entire system
5. **Scalability**: Scale individual services based on demand

## 🏛️ Microservices vs Monolith

### Monolithic Architecture
```python
# Traditional monolithic e-commerce application
class ECommerceMonolith:
    def __init__(self):
        self.database = Database()
        self.user_manager = UserManager(self.database)
        self.product_catalog = ProductCatalog(self.database)
        self.order_processor = OrderProcessor(self.database)
        self.payment_processor = PaymentProcessor(self.database)
        self.inventory_manager = InventoryManager(self.database)
        self.notification_service = NotificationService()
    
    def create_order(self, user_id, items):
        # All functionality in one application
        user = self.user_manager.get_user(user_id)
        
        for item in items:
            product = self.product_catalog.get_product(item['product_id'])
            if not self.inventory_manager.check_availability(item['product_id'], item['quantity']):
                raise InsufficientInventoryError()
        
        order = self.order_processor.create_order(user_id, items)
        payment_result = self.payment_processor.process_payment(order.total, user.payment_method)
        
        if payment_result.success:
            self.inventory_manager.reserve_items(items)
            self.notification_service.send_order_confirmation(user.email, order)
            return order
        else:
            raise PaymentFailedException()

# Deployment: Single application server
# Database: Single shared database
# Scaling: Scale entire application
```

**Advantages**:
- Simple to develop and test initially
- Easy deployment (single artifact)
- No network latency between components
- Strong consistency with ACID transactions

**Disadvantages**:
- All components must use same technology stack
- Difficult to scale individual features
- Single point of failure
- Large teams stepping on each other
- Deployment of one feature affects entire system

### Microservices Architecture
```python
# Microservices-based e-commerce system

# User Service
class UserService:
    def __init__(self):
        self.database = UserDatabase()
        self.cache = RedisCache()
    
    def get_user(self, user_id):
        # Check cache first
        cached_user = self.cache.get(f"user:{user_id}")
        if cached_user:
            return cached_user
        
        user = self.database.get_user(user_id)
        self.cache.set(f"user:{user_id}", user, ttl=3600)
        return user
    
    def create_user(self, user_data):
        user = self.database.create_user(user_data)
        # Publish event for other services
        self.event_bus.publish('user.created', user)
        return user

# Product Service
class ProductService:
    def __init__(self):
        self.database = ProductDatabase()
        self.search_index = ElasticsearchIndex()
    
    def get_product(self, product_id):
        return self.database.get_product(product_id)
    
    def search_products(self, query):
        return self.search_index.search(query)
    
    def update_product(self, product_id, updates):
        product = self.database.update_product(product_id, updates)
        # Update search index
        self.search_index.index_product(product)
        return product

# Order Service
class OrderService:
    def __init__(self):
        self.database = OrderDatabase()
        self.user_service_client = UserServiceClient()
        self.inventory_service_client = InventoryServiceClient()
        self.payment_service_client = PaymentServiceClient()
    
    def create_order(self, user_id, items):
        # Validate user exists
        user = self.user_service_client.get_user(user_id)
        if not user:
            raise UserNotFoundError()
        
        # Check inventory
        for item in items:
            available = self.inventory_service_client.check_availability(
                item['product_id'], item['quantity']
            )
            if not available:
                raise InsufficientInventoryError()
        
        # Create order
        order = self.database.create_order(user_id, items)
        
        # Process payment
        payment_result = self.payment_service_client.process_payment(
            order.total, user.payment_method
        )
        
        if payment_result.success:
            # Reserve inventory
            self.inventory_service_client.reserve_items(items)
            
            # Publish order created event
            self.event_bus.publish('order.created', order)
            
            return order
        else:
            # Cancel order
            self.database.cancel_order(order.id)
            raise PaymentFailedException()

# Each service has its own:
# - Database
# - Technology stack
# - Deployment pipeline
# - Scaling strategy
```

**Advantages**:
- Technology diversity (Python, Java, Node.js, etc.)
- Independent scaling
- Team autonomy
- Fault isolation
- Easier to understand individual services

**Disadvantages**:
- Distributed system complexity
- Network latency
- Data consistency challenges
- Operational overhead
- Testing complexity

## 🔧 Microservices Design Patterns

### 1. Database per Service

```python
# Each service owns its data
class UserService:
    def __init__(self):
        self.user_db = PostgreSQL('users_db')  # Relational data
    
    def get_user_profile(self, user_id):
        return self.user_db.query("SELECT * FROM users WHERE id = %s", user_id)

class ProductService:
    def __init__(self):
        self.product_db = MongoDB('products_db')  # Document data
    
    def get_product(self, product_id):
        return self.product_db.find_one({'_id': product_id})

class AnalyticsService:
    def __init__(self):
        self.analytics_db = ClickHouse('analytics_db')  # Time-series data
    
    def record_event(self, event_data):
        return self.analytics_db.insert('events', event_data)

# No shared databases between services
# Each service chooses optimal database technology
```

### 2. API Gateway Pattern

```python
class APIGateway:
    def __init__(self):
        self.service_registry = ServiceRegistry()
        self.load_balancer = LoadBalancer()
        self.auth_service = AuthenticationService()
    
    def handle_request(self, request):
        # Authenticate request
        user = self.auth_service.authenticate(request)
        if not user:
            return unauthorized_response()
        
        # Route to appropriate service
        service_name = self.extract_service_name(request.path)
        service_instance = self.service_registry.get_instance(service_name)
        
        # Add user context
        request.headers['X-User-ID'] = user.id
        request.headers['X-User-Roles'] = ','.join(user.roles)
        
        # Forward request
        return self.forward_request(request, service_instance)
    
    def extract_service_name(self, path):
        # /api/users/* -> user-service
        # /api/products/* -> product-service
        # /api/orders/* -> order-service
        path_parts = path.split('/')
        if len(path_parts) >= 3:
            return f"{path_parts[2]}-service"
        return None
```

### 3. Service Discovery

```python
# Service Registry
class ServiceRegistry:
    def __init__(self):
        self.services = {}  # service_name -> [instances]
        self.health_checker = HealthChecker()
    
    def register_service(self, service_name, instance_info):
        if service_name not in self.services:
            self.services[service_name] = []
        
        self.services[service_name].append(instance_info)
        
        # Start health checking
        self.health_checker.monitor_instance(instance_info)
    
    def get_healthy_instances(self, service_name):
        instances = self.services.get(service_name, [])
        return [inst for inst in instances if inst.is_healthy()]
    
    def deregister_service(self, service_name, instance_id):
        instances = self.services.get(service_name, [])
        self.services[service_name] = [
            inst for inst in instances if inst.id != instance_id
        ]

# Service Discovery Client
class ServiceDiscoveryClient:
    def __init__(self, registry_url):
        self.registry = ServiceRegistry(registry_url)
        self.local_cache = {}
        self.cache_ttl = 30  # seconds
    
    def discover_service(self, service_name):
        # Check local cache first
        cached_entry = self.local_cache.get(service_name)
        if cached_entry and not self.is_cache_expired(cached_entry):
            return cached_entry['instances']
        
        # Fetch from registry
        instances = self.registry.get_healthy_instances(service_name)
        
        # Cache locally
        self.local_cache[service_name] = {
            'instances': instances,
            'timestamp': time.time()
        }
        
        return instances
    
    def is_cache_expired(self, cache_entry):
        return time.time() - cache_entry['timestamp'] > self.cache_ttl

# Usage in service
class OrderService:
    def __init__(self):
        self.service_discovery = ServiceDiscoveryClient('http://registry:8500')
    
    def get_user_info(self, user_id):
        # Discover user service instances
        user_service_instances = self.service_discovery.discover_service('user-service')
        
        if not user_service_instances:
            raise ServiceUnavailableError('user-service not available')
        
        # Load balance across instances
        instance = random.choice(user_service_instances)
        
        # Make HTTP call
        response = requests.get(f"http://{instance.host}:{instance.port}/users/{user_id}")
        return response.json()
```

### 4. Circuit Breaker Pattern

```python
import time
from enum import Enum

class CircuitBreakerState(Enum):
    CLOSED = "CLOSED"
    OPEN = "OPEN"
    HALF_OPEN = "HALF_OPEN"

class CircuitBreaker:
    def __init__(self, failure_threshold=5, recovery_timeout=60, success_threshold=3):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.success_threshold = success_threshold
        
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time = None
        self.state = CircuitBreakerState.CLOSED
    
    def call(self, func, *args, **kwargs):
        if self.state == CircuitBreakerState.OPEN:
            if self.should_attempt_reset():
                self.state = CircuitBreakerState.HALF_OPEN
            else:
                raise CircuitBreakerOpenException("Circuit breaker is OPEN")
        
        try:
            result = func(*args, **kwargs)
            self.on_success()
            return result
        except Exception as e:
            self.on_failure()
            raise e
    
    def on_success(self):
        self.failure_count = 0
        
        if self.state == CircuitBreakerState.HALF_OPEN:
            self.success_count += 1
            if self.success_count >= self.success_threshold:
                self.state = CircuitBreakerState.CLOSED
                self.success_count = 0
    
    def on_failure(self):
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        if self.failure_count >= self.failure_threshold:
            self.state = CircuitBreakerState.OPEN
    
    def should_attempt_reset(self):
        return (time.time() - self.last_failure_time) >= self.recovery_timeout

# Usage in service communication
class PaymentServiceClient:
    def __init__(self):
        self.circuit_breaker = CircuitBreaker(failure_threshold=3, recovery_timeout=30)
        self.base_url = "http://payment-service:8080"
    
    def process_payment(self, amount, payment_method):
        try:
            return self.circuit_breaker.call(self._make_payment_request, amount, payment_method)
        except CircuitBreakerOpenException:
            # Fallback: queue payment for later processing
            return self.queue_payment_for_retry(amount, payment_method)
    
    def _make_payment_request(self, amount, payment_method):
        response = requests.post(
            f"{self.base_url}/payments",
            json={'amount': amount, 'payment_method': payment_method},
            timeout=10
        )
        
        if response.status_code >= 500:
            raise PaymentServiceError("Payment service error")
        
        return response.json()
```

### 5. Saga Pattern for Distributed Transactions

```python
# Choreography-based Saga
class OrderSagaChoreography:
    def __init__(self):
        self.event_bus = EventBus()
        self.event_bus.subscribe('order.created', self.handle_order_created)
        self.event_bus.subscribe('payment.processed', self.handle_payment_processed)
        self.event_bus.subscribe('payment.failed', self.handle_payment_failed)
        self.event_bus.subscribe('inventory.reserved', self.handle_inventory_reserved)
        self.event_bus.subscribe('inventory.reservation.failed', self.handle_inventory_failed)
    
    def handle_order_created(self, event):
        order = event.data
        # Step 1: Process payment
        self.event_bus.publish('payment.process', {
            'order_id': order.id,
            'amount': order.total,
            'payment_method': order.payment_method
        })
    
    def handle_payment_processed(self, event):
        # Step 2: Reserve inventory
        self.event_bus.publish('inventory.reserve', {
            'order_id': event.data['order_id'],
            'items': event.data['items']
        })
    
    def handle_payment_failed(self, event):
        # Compensating transaction: Cancel order
        self.event_bus.publish('order.cancel', {
            'order_id': event.data['order_id'],
            'reason': 'Payment failed'
        })
    
    def handle_inventory_reserved(self, event):
        # Step 3: Send confirmation
        self.event_bus.publish('notification.send', {
            'order_id': event.data['order_id'],
            'type': 'order_confirmed'
        })
    
    def handle_inventory_failed(self, event):
        # Compensating transactions
        order_id = event.data['order_id']
        
        # Refund payment
        self.event_bus.publish('payment.refund', {'order_id': order_id})
        
        # Cancel order
        self.event_bus.publish('order.cancel', {
            'order_id': order_id,
            'reason': 'Insufficient inventory'
        })

# Orchestration-based Saga
class OrderSagaOrchestrator:
    def __init__(self):
        self.payment_service = PaymentServiceClient()
        self.inventory_service = InventoryServiceClient()
        self.notification_service = NotificationServiceClient()
        self.order_service = OrderServiceClient()
    
    def process_order(self, order):
        saga_state = SagaState(order.id)
        
        try:
            # Step 1: Process payment
            saga_state.add_step('payment')
            payment_result = self.payment_service.process_payment(
                order.total, order.payment_method
            )
            saga_state.complete_step('payment', payment_result)
            
            # Step 2: Reserve inventory
            saga_state.add_step('inventory')
            inventory_result = self.inventory_service.reserve_items(order.items)
            saga_state.complete_step('inventory', inventory_result)
            
            # Step 3: Send confirmation
            saga_state.add_step('notification')
            self.notification_service.send_order_confirmation(order)
            saga_state.complete_step('notification')
            
            return saga_state
            
        except Exception as e:
            # Execute compensating transactions in reverse order
            self.compensate(saga_state, e)
            raise OrderProcessingFailedException(str(e))
    
    def compensate(self, saga_state, error):
        completed_steps = saga_state.get_completed_steps()
        
        # Compensate in reverse order
        for step in reversed(completed_steps):
            try:
                if step.name == 'inventory':
                    self.inventory_service.release_items(step.result['reservation_id'])
                elif step.name == 'payment':
                    self.payment_service.refund_payment(step.result['payment_id'])
            except Exception as comp_error:
                # Log compensation failure
                logger.error(f"Compensation failed for step {step.name}: {comp_error}")

class SagaState:
    def __init__(self, order_id):
        self.order_id = order_id
        self.steps = []
        self.current_step = None
    
    def add_step(self, step_name):
        step = SagaStep(step_name)
        self.steps.append(step)
        self.current_step = step
    
    def complete_step(self, step_name, result=None):
        step = self.find_step(step_name)
        if step:
            step.complete(result)
    
    def get_completed_steps(self):
        return [step for step in self.steps if step.is_completed()]

class SagaStep:
    def __init__(self, name):
        self.name = name
        self.status = 'pending'
        self.result = None
        self.started_at = time.time()
        self.completed_at = None
    
    def complete(self, result=None):
        self.status = 'completed'
        self.result = result
        self.completed_at = time.time()
    
    def is_completed(self):
        return self.status == 'completed'
```

## 🌍 Real-World Microservices Examples

### 1. Netflix Microservices Architecture

```python
# Netflix's microservices approach
class NetflixArchitecture:
    def __init__(self):
        # API Gateway
        self.zuul_gateway = ZuulGateway()
        
        # Core services
        self.user_service = UserService()
        self.content_service = ContentService()
        self.recommendation_service = RecommendationService()
        self.billing_service = BillingService()
        self.streaming_service = StreamingService()
        
        # Infrastructure services
        self.eureka_registry = EurekaServiceRegistry()
        self.hystrix_dashboard = HystrixDashboard()
        self.config_service = ConfigService()
        
        # Data services
        self.cassandra_cluster = CassandraCluster()
        self.elasticsearch_cluster = ElasticsearchCluster()
    
    def get_user_homepage(self, user_id):
        # Parallel service calls with circuit breakers
        user_profile = self.user_service.get_profile(user_id)
        
        # Get recommendations (with fallback)
        try:
            recommendations = self.recommendation_service.get_recommendations(user_id)
        except ServiceUnavailableException:
            recommendations = self.get_trending_content()  # Fallback
        
        # Get continue watching
        continue_watching = self.streaming_service.get_continue_watching(user_id)
        
        return {
            'user': user_profile,
            'recommendations': recommendations,
            'continue_watching': continue_watching
        }
    
    def stream_content(self, user_id, content_id):
        # Check user subscription
        subscription = self.billing_service.get_subscription(user_id)
        if not subscription.is_active():
            raise SubscriptionRequiredException()
        
        # Get content metadata
        content = self.content_service.get_content(content_id)
        
        # Get streaming URL (CDN)
        streaming_url = self.streaming_service.get_streaming_url(
            content_id, user_id, subscription.quality_tier
        )
        
        # Record viewing event
        self.analytics_service.record_view(user_id, content_id)
        
        return {
            'content': content,
            'streaming_url': streaming_url
        }
```

### 2. Uber's Microservices Architecture

```python
# Uber's domain-driven microservices
class UberArchitecture:
    def __init__(self):
        # Rider services
        self.rider_service = RiderService()
        self.trip_service = TripService()
        
        # Driver services
        self.driver_service = DriverService()
        self.vehicle_service = VehicleService()
        
        # Location services
        self.location_service = LocationService()
        self.mapping_service = MappingService()
        self.eta_service = ETAService()
        
        # Business services
        self.pricing_service = PricingService()
        self.payment_service = PaymentService()
        self.dispatch_service = DispatchService()
        
        # Platform services
        self.notification_service = NotificationService()
        self.fraud_detection_service = FraudDetectionService()
    
    def request_ride(self, rider_id, pickup_location, destination):
        # Validate rider
        rider = self.rider_service.get_rider(rider_id)
        if not rider.is_active():
            raise RiderNotActiveException()
        
        # Calculate pricing
        price_estimate = self.pricing_service.calculate_price(
            pickup_location, destination, rider.tier
        )
        
        # Find nearby drivers
        nearby_drivers = self.location_service.find_nearby_drivers(
            pickup_location, radius=5000  # 5km
        )
        
        # Filter available drivers
        available_drivers = []
        for driver_id in nearby_drivers:
            driver = self.driver_service.get_driver(driver_id)
            if driver.is_available():
                available_drivers.append(driver)
        
        if not available_drivers:
            raise NoDriversAvailableException()
        
        # Create trip request
        trip_request = self.trip_service.create_trip_request({
            'rider_id': rider_id,
            'pickup_location': pickup_location,
            'destination': destination,
            'price_estimate': price_estimate,
            'available_drivers': [d.id for d in available_drivers]
        })
        
        # Dispatch to drivers
        self.dispatch_service.dispatch_trip_request(trip_request, available_drivers)
        
        return trip_request
    
    def accept_trip(self, driver_id, trip_request_id):
        # Validate driver
        driver = self.driver_service.get_driver(driver_id)
        if not driver.is_available():
            raise DriverNotAvailableException()
        
        # Accept trip
        trip = self.trip_service.accept_trip_request(trip_request_id, driver_id)
        
        # Update driver status
        self.driver_service.update_driver_status(driver_id, 'en_route_to_pickup')
        
        # Notify rider
        self.notification_service.notify_rider_driver_assigned(
            trip.rider_id, driver, trip.estimated_pickup_time
        )
        
        # Start location tracking
        self.location_service.start_trip_tracking(trip.id, driver_id)
        
        return trip
```

### 3. Amazon's Microservices (Simplified)

```python
# Amazon's service-oriented architecture
class AmazonArchitecture:
    def __init__(self):
        # Customer services
        self.customer_service = CustomerService()
        self.authentication_service = AuthenticationService()
        
        # Product services
        self.product_catalog_service = ProductCatalogService()
        self.inventory_service = InventoryService()
        self.pricing_service = PricingService()
        self.review_service = ReviewService()
        
        # Order services
        self.shopping_cart_service = ShoppingCartService()
        self.order_service = OrderService()
        self.fulfillment_service = FulfillmentService()
        
        # Payment services
        self.payment_service = PaymentService()
        self.billing_service = BillingService()
        
        # Logistics services
        self.shipping_service = ShippingService()
        self.tracking_service = TrackingService()
        
        # Recommendation services
        self.recommendation_service = RecommendationService()
        self.search_service = SearchService()
    
    def place_order(self, customer_id, cart_items):
        # Get customer info
        customer = self.customer_service.get_customer(customer_id)
        
        # Validate cart items
        validated_items = []
        total_price = 0
        
        for item in cart_items:
            # Check inventory
            availability = self.inventory_service.check_availability(
                item['product_id'], item['quantity']
            )
            if not availability.available:
                raise InsufficientInventoryException(item['product_id'])
            
            # Get current price
            price = self.pricing_service.get_price(
                item['product_id'], customer.tier
            )
            
            validated_items.append({
                'product_id': item['product_id'],
                'quantity': item['quantity'],
                'unit_price': price,
                'total_price': price * item['quantity']
            })
            
            total_price += price * item['quantity']
        
        # Process payment
        payment_result = self.payment_service.process_payment(
            customer_id, total_price, customer.default_payment_method
        )
        
        if not payment_result.success:
            raise PaymentFailedException()
        
        # Create order
        order = self.order_service.create_order({
            'customer_id': customer_id,
            'items': validated_items,
            'total_price': total_price,
            'payment_id': payment_result.payment_id
        })
        
        # Reserve inventory
        for item in validated_items:
            self.inventory_service.reserve_item(
                item['product_id'], item['quantity'], order.id
            )
        
        # Initiate fulfillment
        self.fulfillment_service.initiate_fulfillment(order)
        
        # Clear shopping cart
        self.shopping_cart_service.clear_cart(customer_id)
        
        return order
```

## 🔧 Microservices Infrastructure Patterns

### 1. Service Mesh

```python
# Service mesh with Istio-like functionality
class ServiceMesh:
    def __init__(self):
        self.sidecar_proxies = {}
        self.control_plane = ControlPlane()
        self.telemetry_collector = TelemetryCollector()
    
    def inject_sidecar(self, service_name, service_instance):
        # Inject sidecar proxy for service
        sidecar = SidecarProxy(service_name, service_instance)
        self.sidecar_proxies[service_instance.id] = sidecar
        
        # Configure sidecar with policies
        policies = self.control_plane.get_policies(service_name)
        sidecar.configure(policies)
        
        return sidecar
    
    def route_request(self, source_service, target_service, request):
        source_sidecar = self.sidecar_proxies[source_service.id]
        
        # Apply routing rules
        routing_rules = self.control_plane.get_routing_rules(target_service.name)
        target_instance = self.select_target_instance(target_service.name, routing_rules)
        
        # Apply security policies
        if not self.check_security_policy(source_service, target_service):
            raise SecurityPolicyViolationException()
        
        # Add telemetry
        trace_id = generate_trace_id()
        request.headers['X-Trace-ID'] = trace_id
        
        # Forward request through target sidecar
        target_sidecar = self.sidecar_proxies[target_instance.id]
        response = target_sidecar.forward_request(request)
        
        # Collect metrics
        self.telemetry_collector.record_request(
            source_service.name, target_service.name, 
            response.status_code, response.duration
        )
        
        return response

class SidecarProxy:
    def __init__(self, service_name, service_instance):
        self.service_name = service_name
        self.service_instance = service_instance
        self.circuit_breakers = {}
        self.rate_limiters = {}
        self.retry_policies = {}
    
    def configure(self, policies):
        for policy in policies:
            if policy.type == 'circuit_breaker':
                self.circuit_breakers[policy.target] = CircuitBreaker(**policy.config)
            elif policy.type == 'rate_limit':
                self.rate_limiters[policy.target] = RateLimiter(**policy.config)
            elif policy.type == 'retry':
                self.retry_policies[policy.target] = RetryPolicy(**policy.config)
    
    def forward_request(self, request):
        target = request.headers.get('X-Target-Service')
        
        # Apply rate limiting
        rate_limiter = self.rate_limiters.get(target)
        if rate_limiter and not rate_limiter.allow_request():
            raise RateLimitExceededException()
        
        # Apply circuit breaker
        circuit_breaker = self.circuit_breakers.get(target)
        if circuit_breaker:
            return circuit_breaker.call(self._make_request, request)
        else:
            return self._make_request(request)
    
    def _make_request(self, request):
        # Apply retry policy
        retry_policy = self.retry_policies.get(request.headers.get('X-Target-Service'))
        
        if retry_policy:
            return retry_policy.execute(lambda: self._send_request(request))
        else:
            return self._send_request(request)
```

### 2. Event-Driven Architecture

```python
# Event-driven microservices communication
class EventDrivenArchitecture:
    def __init__(self):
        self.event_bus = EventBus()
        self.event_store = EventStore()
        self.services = {}
    
    def register_service(self, service):
        self.services[service.name] = service
        
        # Subscribe to events
        for event_type in service.subscribed_events:
            self.event_bus.subscribe(event_type, service.handle_event)
    
    def publish_event(self, event):
        # Store event for audit/replay
        self.event_store.store_event(event)
        
        # Publish to event bus
        self.event_bus.publish(event.type, event)

class OrderService:
    def __init__(self):
        self.name = 'order-service'
        self.subscribed_events = ['payment.processed', 'payment.failed', 'inventory.reserved']
        self.event_bus = EventBus()
    
    def create_order(self, order_data):
        # Create order in pending state
        order = self.database.create_order({
            **order_data,
            'status': 'pending'
        })
        
        # Publish order created event
        event = Event(
            type='order.created',
            data=order,
            source='order-service',
            timestamp=time.time()
        )
        
        self.event_bus.publish('order.created', event)
        return order
    
    def handle_event(self, event):
        if event.type == 'payment.processed':
            self.handle_payment_processed(event)
        elif event.type == 'payment.failed':
            self.handle_payment_failed(event)
        elif event.type == 'inventory.reserved':
            self.handle_inventory_reserved(event)
    
    def handle_payment_processed(self, event):
        order_id = event.data['order_id']
        
        # Update order status
        self.database.update_order(order_id, {'status': 'payment_confirmed'})
        
        # Request inventory reservation
        inventory_event = Event(
            type='inventory.reserve_request',
            data={
                'order_id': order_id,
                'items': event.data['items']
            },
            source='order-service'
        )
        
        self.event_bus.publish('inventory.reserve_request', inventory_event)
    
    def handle_inventory_reserved(self, event):
        order_id = event.data['order_id']
        
        # Update order status
        self.database.update_order(order_id, {'status': 'confirmed'})
        
        # Publish order confirmed event
        confirmed_event = Event(
            type='order.confirmed',
            data={'order_id': order_id},
            source='order-service'
        )
        
        self.event_bus.publish('order.confirmed', confirmed_event)

class Event:
    def __init__(self, type, data, source, timestamp=None):
        self.id = str(uuid.uuid4())
        self.type = type
        self.data = data
        self.source = source
        self.timestamp = timestamp or time.time()
```

## 📊 Microservices Monitoring and Observability

### 1. Distributed Tracing

```python
# Distributed tracing implementation
class DistributedTracer:
    def __init__(self):
        self.tracer = opentracing.tracer
        self.spans = {}
    
    def start_span(self, operation_name, parent_span=None):
        span = self.tracer.start_span(
            operation_name=operation_name,
            child_of=parent_span
        )
        
        span.set_tag('service.name', os.environ.get('SERVICE_NAME'))
        span.set_tag('service.version', os.environ.get('SERVICE_VERSION'))
        
        return span
    
    def inject_span_context(self, span, headers):
        self.tracer.inject(
            span_context=span.context,
            format=opentracing.Format.HTTP_HEADERS,
            carrier=headers
        )
    
    def extract_span_context(self, headers):
        return self.tracer.extract(
            format=opentracing.Format.HTTP_HEADERS,
            carrier=headers
        )

# Service with tracing
class TracedOrderService:
    def __init__(self):
        self.tracer = DistributedTracer()
        self.payment_client = PaymentServiceClient()
    
    def create_order(self, order_data, request_headers=None):
        # Extract parent span context
        parent_context = None
        if request_headers:
            parent_context = self.tracer.extract_span_context(request_headers)
        
        # Start span for order creation
        with self.tracer.start_span('create_order', parent_context) as span:
            span.set_tag('order.user_id', order_data['user_id'])
            span.set_tag('order.item_count', len(order_data['items']))
            
            try:
                # Create order
                order = self.database.create_order(order_data)
                span.set_tag('order.id', order.id)
                
                # Call payment service with trace context
                payment_headers = {}
                self.tracer.inject_span_context(span, payment_headers)
                
                payment_result = self.payment_client.process_payment(
                    order.total, 
                    order_data['payment_method'],
                    headers=payment_headers
                )
                
                span.set_tag('payment.success', payment_result.success)
                
                if payment_result.success:
                    span.set_tag('order.status', 'confirmed')
                    return order
                else:
                    span.set_tag('order.status', 'payment_failed')
                    span.set_tag('error', True)
                    raise PaymentFailedException()
                    
            except Exception as e:
                span.set_tag('error', True)
                span.log_kv({'error.message': str(e)})
                raise
```

### 2. Metrics and Health Checks

```python
# Service metrics collection
class ServiceMetrics:
    def __init__(self):
        self.request_count = Counter('requests_total', ['service', 'method', 'status'])
        self.request_duration = Histogram('request_duration_seconds', ['service', 'method'])
        self.active_connections = Gauge('active_connections', ['service'])
        self.circuit_breaker_state = Gauge('circuit_breaker_open', ['service', 'target'])
    
    def record_request(self, service_name, method, status_code, duration):
        labels = {
            'service': service_name,
            'method': method,
            'status': str(status_code)
        }
        
        self.request_count.inc(labels)
        self.request_duration.observe(duration, labels)
    
    def update_circuit_breaker_state(self, service_name, target, is_open):
        self.circuit_breaker_state.set(
            1 if is_open else 0,
            {'service': service_name, 'target': target}
        )

# Health check implementation
class HealthChecker:
    def __init__(self):
        self.health_checks = []
        self.dependencies = []
    
    def add_health_check(self, name, check_function):
        self.health_checks.append({
            'name': name,
            'check': check_function
        })
    
    def add_dependency(self, name, service_client):
        self.dependencies.append({
            'name': name,
            'client': service_client
        })
    
    def get_health_status(self):
        health_status = {
            'status': 'healthy',
            'checks': {},
            'dependencies': {}
        }
        
        # Run health checks
        for check in self.health_checks:
            try:
                result = check['check']()
                health_status['checks'][check['name']] = {
                    'status': 'healthy',
                    'details': result
                }
            except Exception as e:
                health_status['checks'][check['name']] = {
                    'status': 'unhealthy',
                    'error': str(e)
                }
                health_status['status'] = 'unhealthy'
        
        # Check dependencies
        for dep in self.dependencies:
            try:
                dep['client'].health_check()
                health_status['dependencies'][dep['name']] = 'healthy'
            except Exception as e:
                health_status['dependencies'][dep['name']] = f'unhealthy: {str(e)}'
                # Dependencies being down doesn't make this service unhealthy
        
        return health_status

# Usage in service
class OrderService:
    def __init__(self):
        self.health_checker = HealthChecker()
        self.metrics = ServiceMetrics()
        
        # Add health checks
        self.health_checker.add_health_check('database', self.check_database)
        self.health_checker.add_health_check('cache', self.check_cache)
        
        # Add dependencies
        self.health_checker.add_dependency('payment-service', self.payment_client)
        self.health_checker.add_dependency('inventory-service', self.inventory_client)
    
    def check_database(self):
        # Simple database connectivity check
        result = self.database.execute("SELECT 1")
        return {'connection': 'ok', 'response_time_ms': result.duration}
    
    def check_cache(self):
        # Cache connectivity check
        self.cache.set('health_check', 'ok', ttl=1)
        value = self.cache.get('health_check')
        return {'connection': 'ok', 'value': value}
```

## 🚨 Common Microservices Challenges

### 1. Data Consistency

```python
# Eventual consistency with event sourcing
class EventSourcingService:
    def __init__(self):
        self.event_store = EventStore()
        self.projections = {}
        self.event_handlers = {}
    
    def handle_command(self, command):
        # Generate events based on command
        events = self.process_command(command)
        
        # Store events
        for event in events:
            self.event_store.append_event(command.aggregate_id, event)
        
        # Apply events to projections
        for event in events:
            self.apply_event_to_projections(event)
        
        # Publish events for other services
        for event in events:
            self.event_bus.publish(event.type, event)
    
    def rebuild_projection(self, projection_name, aggregate_id):
        # Rebuild projection from event history
        events = self.event_store.get_events(aggregate_id)
        projection = self.projections[projection_name]
        
        projection.reset(aggregate_id)
        for event in events:
            projection.apply_event(event)
```

### 2. Network Latency and Failures

```python
# Retry with exponential backoff
class RetryableServiceClient:
    def __init__(self, base_url, max_retries=3):
        self.base_url = base_url
        self.max_retries = max_retries
        self.session = requests.Session()
    
    def make_request(self, method, path, **kwargs):
        for attempt in range(self.max_retries + 1):
            try:
                response = self.session.request(
                    method, 
                    f"{self.base_url}{path}",
                    timeout=10,
                    **kwargs
                )
                
                if response.status_code < 500:
                    return response
                else:
                    raise ServiceException(f"Server error: {response.status_code}")
                    
            except (requests.ConnectionError, requests.Timeout, ServiceException) as e:
                if attempt == self.max_retries:
                    raise ServiceUnavailableException(f"Service call failed after {self.max_retries + 1} attempts")
                
                # Exponential backoff with jitter
                delay = (2 ** attempt) + random.uniform(0, 1)
                time.sleep(delay)
```

## 📚 Conclusion

Microservices architecture enables organizations to build scalable, resilient systems by breaking down monolithic applications into smaller, independent services. While this approach introduces complexity in terms of distributed system challenges, the benefits of team autonomy, technology diversity, and independent scaling often outweigh the costs for large, complex applications.

**Key Takeaways:**

1. **Start with a Monolith**: Don't begin with microservices; extract them when you understand domain boundaries
2. **Domain-Driven Design**: Use business domains to define service boundaries
3. **Infrastructure Investment**: Invest in service discovery, monitoring, and deployment automation
4. **Data Management**: Each service should own its data and communicate through well-defined APIs
5. **Failure Handling**: Design for failure with circuit breakers, retries, and graceful degradation

The future of microservices lies in service mesh technologies, serverless architectures, and AI-powered operations that can automatically optimize service interactions and resource allocation. Whether you're building a simple application or a complex distributed system, understanding microservices patterns is essential for creating scalable, maintainable architectures.

Remember: Microservices are not a silver bullet—they're a tool for managing complexity in large systems. Use them when the benefits outweigh the operational overhead, and always prioritize business value over architectural purity.
