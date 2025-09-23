# URL Shortener System Design Architecture

## 1. Executive Summary & Requirements

### System Overview
A URL shortener service that converts long URLs into short, manageable links while providing analytics, custom aliases, and high availability. The system handles millions of URL shortening requests daily with sub-second response times.

### Functional Requirements
- **URL Shortening**: Convert long URLs to short URLs (6-8 character codes)
- **URL Redirection**: Redirect short URLs to original URLs with minimal latency
- **Custom Aliases**: Allow users to create custom short URLs
- **Analytics**: Track click counts, geographic data, referrer information, and timestamps
- **User Management**: User accounts, URL management dashboard
- **Expiration**: Support URL expiration dates
- **Bulk Operations**: API for bulk URL shortening

### Non-Functional Requirements
- **Availability**: 99.9% uptime
- **Latency**: <100ms for URL redirection, <500ms for URL creation
- **Scale**: 100M URLs shortened per day, 10:1 read/write ratio
- **Storage**: 5 years of URL retention
- **Throughput**: 100K read requests per second, 10K write requests per second

### Key Constraints
- Short URLs must be unique and collision-free
- System must handle traffic spikes (viral content)
- Geographic distribution for global low latency
- GDPR and data privacy compliance

### Success Metrics
- 99.9% availability SLA
- Average redirection latency <50ms
- 99.99% URL uniqueness guarantee
- Support 1B+ total URLs in system

## 2. High-Level Architecture Overview

```mermaid
C4Context
    title URL Shortener System Context

    Person(user, "End User", "Creates and uses short URLs")
    Person(api_user, "API User", "Integrates URL shortener via API")
    Person(analyst, "Business Analyst", "Views analytics and reports")

    System_Boundary(url_system, "URL Shortener System") {
        System(core, "URL Shortener Core", "Handles URL shortening and redirection")
        System(analytics, "Analytics System", "Tracks and analyzes URL usage")
        System(dashboard, "Management Dashboard", "User interface for URL management")
    }

    System_Ext(cdn, "CloudFront CDN", "Global content delivery")
    System_Ext(monitoring, "CloudWatch", "System monitoring and alerting")
    System_Ext(external_apis, "External APIs", "Social media, link validation")

    Rel(user, core, "Creates/accesses short URLs", "HTTPS")
    Rel(api_user, core, "API integration", "REST API")
    Rel(analyst, dashboard, "Views analytics", "HTTPS")
    Rel(core, analytics, "Usage events", "Event streaming")
    Rel(cdn, core, "Cached responses", "HTTP")
    Rel(core, monitoring, "Metrics and logs", "CloudWatch API")
    Rel(core, external_apis, "Link validation", "HTTPS")
```

**Architectural Style Rationale**: Microservices architecture chosen for:
- Independent scaling of URL creation vs redirection services
- Technology diversity (different databases optimized for different use cases)
- Fault isolation and independent deployments
- Team autonomy and parallel development

## 3. Detailed System Architecture

### 3.1 AWS Service Stack Selection

**Presentation Layer:**
- **CloudFront**: Global CDN for caching redirections and static assets
- **API Gateway**: RESTful API management with rate limiting and authentication
- **Route 53**: DNS management with health checks and failover

**Application Layer:**
- **ECS Fargate**: Containerized microservices for URL shortener core services
- **Application Load Balancer**: Distributes traffic with health checks
- **Lambda**: Serverless functions for analytics processing and batch jobs

**Data Layer:**
- **DynamoDB**: Primary database for URL mappings (high read performance)
- **RDS Aurora**: User management and analytics data (ACID compliance)
- **ElastiCache Redis**: Caching layer for frequently accessed URLs

**Storage Layer:**
- **S3**: Analytics data archival and static asset storage
- **EFS**: Shared storage for application logs and temporary files

**Streaming/Messaging:**
- **Kinesis Data Streams**: Real-time analytics event streaming
- **SQS**: Asynchronous processing queues
- **SNS**: Notification system for alerts and user notifications

**Analytics:**
- **Kinesis Analytics**: Real-time stream processing
- **Glue**: ETL jobs for analytics data transformation
- **QuickSight**: Business intelligence and dashboard visualization

**Security:**
- **Cognito**: User authentication and authorization
- **WAF**: Web application firewall protection
- **KMS**: Encryption key management
- **Secrets Manager**: API keys and database credentials

**Monitoring:**
- **CloudWatch**: Metrics, logs, and alerting
- **X-Ray**: Distributed tracing
- **CloudTrail**: API audit logging

### 3.2 Component Architecture Diagram

```mermaid
block-beta
    columns 3
    
    block:frontend:3
        CDN["CloudFront CDN"]
        ALB["Application Load Balancer"]
        API["API Gateway"]
    end
    
    block:services:3
        URL["URL Shortener Service"]
        RED["Redirection Service"]
        ANA["Analytics Service"]
    end
    
    block:data:3
        DDB["DynamoDB"]
        RDS["Aurora RDS"]
        CACHE["ElastiCache Redis"]
    end
    
    block:streaming:3
        KDS["Kinesis Data Streams"]
        SQS["SQS Queues"]
        S3["S3 Storage"]
    end
    
    CDN --> ALB
    ALB --> URL
    ALB --> RED
    API --> URL
    URL --> DDB
    RED --> CACHE
    RED --> DDB
    URL --> KDS
    RED --> KDS
    KDS --> ANA
    ANA --> RDS
    ANA --> S3
    CACHE --> DDB
```

## 4. Data Architecture & Flow

### 4.1 Data Flow Diagrams

#### Read Path (URL Redirection)
```mermaid
flowchart TD
    A[User clicks short URL] --> B[CloudFront CDN]
    B --> C{Cache Hit?}
    C -->|Yes| D[Return cached redirect]
    C -->|No| E[Application Load Balancer]
    E --> F[Redirection Service]
    F --> G[ElastiCache Redis]
    G --> H{Cache Hit?}
    H -->|Yes| I[Return original URL]
    H -->|No| J[DynamoDB Query]
    J --> K[Update Redis Cache]
    K --> I
    I --> L[HTTP 301/302 Redirect]
    L --> M[Log Analytics Event]
    M --> N[Kinesis Data Streams]
    
    style D fill:#90EE90
    style I fill:#90EE90
    style L fill:#FFB6C1
```

#### Write Path (URL Creation)
```mermaid
flowchart TD
    A[User submits long URL] --> B[API Gateway]
    B --> C[Authentication Check]
    C --> D[URL Shortener Service]
    D --> E[Validate URL]
    E --> F[Generate Short Code]
    F --> G{Custom Alias?}
    G -->|Yes| H[Validate Alias Availability]
    G -->|No| I[Check Code Uniqueness]
    H --> J{Available?}
    J -->|No| K[Return Error]
    J -->|Yes| I
    I --> L[Store in DynamoDB]
    L --> M[Update Cache]
    M --> N[Return Short URL]
    N --> O[Log Creation Event]
    O --> P[Kinesis Data Streams]
    
    style K fill:#FFB6C1
    style N fill:#90EE90
```

#### Real-time Analytics Processing
```mermaid
flowchart TD
    A[Kinesis Data Streams] --> B[Kinesis Analytics]
    B --> C[Real-time Aggregations]
    C --> D[ElastiCache Updates]
    B --> E[Lambda Functions]
    E --> F[Batch Processing]
    F --> G[Aurora RDS]
    G --> H[QuickSight Dashboards]
    A --> I[S3 Raw Data Archive]
    I --> J[Glue ETL Jobs]
    J --> K[Data Warehouse]
```

### 4.2 Database Design

#### Primary URL Mapping (DynamoDB)
```mermaid
erDiagram
    URL_MAPPING {
        string short_code PK
        string original_url
        string user_id
        timestamp created_at
        timestamp expires_at
        number click_count
        string status
    }
    
    USER_URLS {
        string user_id PK
        string short_code SK
        timestamp created_at
        string title
        boolean is_custom_alias
    }
    
    ANALYTICS_EVENTS {
        string short_code PK
        timestamp event_time SK
        string ip_address
        string user_agent
        string referrer
        string country
        string city
    }
    
    URL_MAPPING ||--o{ USER_URLS : "belongs to"
    URL_MAPPING ||--o{ ANALYTICS_EVENTS : "generates"
```

#### User Management (Aurora RDS)
```mermaid
erDiagram
    USERS {
        uuid user_id PK
        string email UK
        string password_hash
        string first_name
        string last_name
        timestamp created_at
        timestamp last_login
        string subscription_tier
        boolean is_active
    }
    
    API_KEYS {
        uuid api_key_id PK
        uuid user_id FK
        string api_key_hash
        string name
        timestamp created_at
        timestamp expires_at
        boolean is_active
        number rate_limit
    }
    
    ANALYTICS_SUMMARY {
        uuid summary_id PK
        uuid user_id FK
        date summary_date
        number total_clicks
        number unique_visitors
        number new_urls_created
        json top_countries
        json top_referrers
    }
    
    USERS ||--o{ API_KEYS : "has"
    USERS ||--o{ ANALYTICS_SUMMARY : "generates"
```

## 5. Detailed Component Design

### 5.1 URL Shortener Service

**Purpose & Responsibilities:**
- Generate unique short codes for URLs
- Validate and sanitize input URLs
- Handle custom alias requests
- Manage URL metadata and expiration
- Rate limiting and user quota enforcement

**AWS Service Selection:**
- **ECS Fargate**: Serverless containers for auto-scaling without infrastructure management
- **Application Load Balancer**: Health checks and traffic distribution
- **DynamoDB**: Single-digit millisecond latency for URL storage

**Scaling Characteristics:**
- Horizontal scaling based on CPU and request metrics
- Auto-scaling target: 70% CPU utilization
- Scale out: +2 tasks per scaling event
- Scale in: -1 task per scaling event (conservative)

**Failure Modes & Recovery:**
- Service failure: ALB health checks redirect to healthy instances
- Database failure: DynamoDB auto-failover to secondary regions
- Code generation failure: Fallback to timestamp-based generation

### 5.2 Redirection Service

**Purpose & Responsibilities:**
- High-performance URL lookups
- HTTP redirect responses (301/302)
- Analytics event generation
- Cache management and warming

**Performance Considerations:**
- Read-optimized with Redis caching (99% cache hit rate target)
- Connection pooling for database connections
- Async analytics event publishing
- CDN integration for geographic distribution

### 5.3 Analytics Service

**Purpose & Responsibilities:**
- Real-time event processing from Kinesis streams
- Aggregation and summarization of click data
- Geographic and demographic analysis
- Report generation and data export

**Scaling Characteristics:**
- Lambda auto-scaling for stream processing
- Kinesis shard scaling based on throughput
- Aurora read replicas for analytics queries

### Critical User Journey Sequence Diagrams

#### URL Shortening Flow
```mermaid
sequenceDiagram
    participant U as User
    participant AG as API Gateway
    participant US as URL Shortener Service
    participant DB as DynamoDB
    participant C as ElastiCache
    participant K as Kinesis
    
    U->>AG: POST /shorten {url, custom_alias?}
    AG->>AG: Authenticate & Rate Limit
    AG->>US: Forward Request
    US->>US: Validate URL Format
    US->>US: Generate Short Code
    US->>DB: Check Code Uniqueness
    DB-->>US: Unique Confirmation
    US->>DB: Store URL Mapping
    DB-->>US: Success
    US->>C: Cache URL Mapping
    US->>K: Publish Creation Event
    US-->>AG: Return Short URL
    AG-->>U: 201 Created {short_url}
    
    Note over US,DB: Retry logic for code collisions
    Note over K: Async analytics processing
```

#### URL Redirection Flow
```mermaid
sequenceDiagram
    participant U as User
    participant CF as CloudFront
    participant ALB as Load Balancer
    participant RS as Redirection Service
    participant C as ElastiCache
    participant DB as DynamoDB
    participant K as Kinesis
    
    U->>CF: GET /abc123
    CF->>CF: Check Edge Cache
    alt Cache Miss
        CF->>ALB: Forward Request
        ALB->>RS: Route to Healthy Instance
        RS->>C: Query Redis Cache
        alt Cache Miss
            RS->>DB: Query DynamoDB
            DB-->>RS: Return Original URL
            RS->>C: Update Cache (TTL: 1 hour)
        else Cache Hit
            C-->>RS: Return Cached URL
        end
        RS->>K: Publish Click Event (Async)
        RS-->>ALB: 302 Redirect
        ALB-->>CF: 302 Redirect
        CF->>CF: Cache Response (TTL: 5 min)
    end
    CF-->>U: 302 Redirect to Original URL
    U->>U: Navigate to Original URL
    
    Note over RS,K: Analytics processing happens asynchronously
    Note over CF: Edge caching reduces backend load
```

## 6. Scalability & Performance

### 6.1 Scaling Architecture

```mermaid
flowchart TD
    subgraph "Auto Scaling Strategy"
        A[CloudWatch Metrics] --> B[Auto Scaling Triggers]
        B --> C{Metric Threshold}
        C -->|CPU > 70%| D[Scale Out +2 Tasks]
        C -->|CPU < 30%| E[Scale In -1 Task]
        C -->|Request Rate > 1000/min| F[Scale Out +1 Task]
    end
    
    subgraph "Geographic Distribution"
        G[US East Primary] --> H[US West Secondary]
        G --> I[EU West Secondary]
        G --> J[Asia Pacific Secondary]
        K[Route 53 Health Checks] --> G
        K --> H
        K --> I
        K --> J
    end
    
    subgraph "Load Balancing"
        L[Application Load Balancer] --> M[Target Group 1]
        L --> N[Target Group 2]
        M --> O[ECS Tasks 1-10]
        N --> P[ECS Tasks 11-20]
    end
```

### 6.2 Performance Optimization

**Caching Strategy:**
- **L1 Cache (CloudFront)**: 5-minute TTL for redirections, 1-hour for static assets
- **L2 Cache (ElastiCache)**: 1-hour TTL for URL mappings, LRU eviction
- **L3 Cache (Application)**: In-memory cache for frequently accessed data

**CDN Configuration:**
- **Origin Shield**: Enabled in primary regions to reduce origin load
- **Compression**: Gzip/Brotli compression for API responses
- **HTTP/2**: Enabled for improved connection efficiency

**Database Optimization:**
- **DynamoDB**: On-demand billing with burst capacity
- **Read Replicas**: Aurora read replicas in each region
- **Connection Pooling**: Managed connection pools with circuit breakers

## 7. Reliability & Fault Tolerance

### 7.1 High Availability Design

```mermaid
graph TB
    subgraph "Multi-AZ Deployment"
        subgraph "AZ-1a"
            ALB1[ALB Instance]
            ECS1[ECS Tasks 1-5]
            CACHE1[ElastiCache Node 1]
        end
        
        subgraph "AZ-1b"
            ALB2[ALB Instance]
            ECS2[ECS Tasks 6-10]
            CACHE2[ElastiCache Node 2]
        end
        
        subgraph "AZ-1c"
            ECS3[ECS Tasks 11-15]
            CACHE3[ElastiCache Node 3]
        end
    end
    
    subgraph "Data Layer HA"
        DDB[(DynamoDB<br/>Multi-AZ)]
        RDS[(Aurora<br/>Multi-AZ)]
    end
    
    ALB1 --> ECS1
    ALB2 --> ECS2
    ALB1 --> ECS2
    ALB2 --> ECS1
    
    ECS1 --> DDB
    ECS2 --> DDB
    ECS3 --> DDB
    
    ECS1 --> CACHE1
    ECS2 --> CACHE2
    ECS3 --> CACHE3
```

**Circuit Breaker Patterns:**
- **Database Circuit Breaker**: 50% error rate threshold, 30-second timeout
- **Cache Circuit Breaker**: Fallback to database on cache failures
- **External API Circuit Breaker**: Graceful degradation for non-critical services

### 7.2 Disaster Recovery

```mermaid
flowchart TD
    A[Primary Region Failure] --> B[Route 53 Health Check Failure]
    B --> C[DNS Failover to Secondary Region]
    C --> D[Secondary Region Activation]
    D --> E[DynamoDB Global Tables Sync]
    E --> F[Aurora Cross-Region Replica Promotion]
    F --> G[Application Services Auto-Start]
    G --> H[Cache Warming from Database]
    H --> I[Full Service Restoration]
    
    J[Backup Strategy] --> K[DynamoDB Point-in-Time Recovery]
    J --> L[Aurora Automated Backups]
    J --> M[S3 Cross-Region Replication]
    
    style A fill:#FFB6C1
    style I fill:#90EE90
```

**RTO/RPO Targets:**
- **RTO (Recovery Time Objective)**: 15 minutes
- **RPO (Recovery Point Objective)**: 1 minute
- **Backup Retention**: 35 days for DynamoDB, 7 days for Aurora
- **Cross-Region Replication**: Real-time for DynamoDB Global Tables

## 8. Security Architecture

### 8.1 Security Layers

```mermaid
block-beta
    columns 3
    
    block:network:3
        VPC["VPC with Private Subnets"]
        NACL["Network ACLs"]
        SG["Security Groups"]
    end
    
    block:app:3
        WAF["AWS WAF"]
        COGNITO["Cognito Authentication"]
        APIGW["API Gateway Rate Limiting"]
    end
    
    block:data:3
        KMS["KMS Encryption"]
        SECRETS["Secrets Manager"]
        IAM["IAM Roles & Policies"]
    end
    
    WAF --> VPC
    COGNITO --> APIGW
    KMS --> SECRETS
    VPC --> NACL
    NACL --> SG
```

**Network Security:**
- **VPC**: Isolated network with private subnets for application tier
- **Security Groups**: Least privilege access (port 443/80 only from ALB)
- **NACLs**: Additional subnet-level protection
- **NAT Gateway**: Secure outbound internet access for private subnets

**Application Security:**
- **WAF Rules**: SQL injection, XSS, and rate limiting protection
- **API Authentication**: JWT tokens with Cognito integration
- **Rate Limiting**: 1000 requests/hour per user, 10 requests/second burst

**Data Security:**
- **Encryption at Rest**: KMS encryption for DynamoDB, Aurora, S3
- **Encryption in Transit**: TLS 1.3 for all communications
- **Key Rotation**: Automatic 90-day rotation for encryption keys

### 8.2 Authentication & Authorization Flow

```mermaid
sequenceDiagram
    participant U as User
    participant CF as CloudFront
    participant AG as API Gateway
    participant COG as Cognito
    participant US as URL Shortener Service
    participant DB as DynamoDB
    
    U->>CF: POST /auth/login
    CF->>AG: Forward Request
    AG->>COG: Authenticate User
    COG-->>AG: JWT Access Token
    AG-->>CF: Return Token
    CF-->>U: Authentication Success
    
    U->>CF: POST /shorten (with JWT)
    CF->>AG: Forward with Token
    AG->>AG: Validate JWT
    AG->>COG: Verify Token
    COG-->>AG: User Claims
    AG->>US: Authorized Request
    US->>DB: Create URL Mapping
    DB-->>US: Success
    US-->>AG: Short URL Response
    AG-->>CF: Response
    CF-->>U: Short URL Created
    
    Note over AG,COG: Token validation cached for 5 minutes
    Note over US: User quota enforcement based on claims
```

## 9. Monitoring & Observability

```mermaid
flowchart TD
    subgraph "Metrics Collection"
        A[Application Metrics] --> D[CloudWatch Metrics]
        B[Infrastructure Metrics] --> D
        C[Custom Business Metrics] --> D
    end
    
    subgraph "Logging Pipeline"
        E[Application Logs] --> F[CloudWatch Logs]
        G[Access Logs] --> F
        H[Error Logs] --> F
        F --> I[Log Insights Queries]
    end
    
    subgraph "Tracing & Debugging"
        J[X-Ray Tracing] --> K[Service Map]
        J --> L[Performance Analysis]
        J --> M[Error Root Cause]
    end
    
    subgraph "Alerting & Notification"
        D --> N[CloudWatch Alarms]
        N --> O[SNS Topics]
        O --> P[PagerDuty Integration]
        O --> Q[Slack Notifications]
    end
    
    style P fill:#FFB6C1
    style Q fill:#90EE90
```

**Key Metrics Monitored:**
- **Application**: Request latency, error rate, throughput
- **Infrastructure**: CPU, memory, disk utilization
- **Business**: URLs created/hour, click-through rates, user engagement
- **Security**: Failed authentication attempts, suspicious IP patterns

**Alerting Thresholds:**
- **Critical**: >5% error rate, >1000ms average latency, service unavailability
- **Warning**: >2% error rate, >500ms average latency, >80% resource utilization
- **Info**: Unusual traffic patterns, quota approaching limits

## 10. Cost Optimization

**Service-Level Cost Analysis:**
- **DynamoDB**: $800/month (on-demand, 100M reads, 10M writes)
- **ECS Fargate**: $1,200/month (10 tasks, 2 vCPU, 4GB RAM each)
- **ElastiCache**: $400/month (3 cache.r6g.large nodes)
- **CloudFront**: $300/month (1TB data transfer, 10M requests)
- **Aurora**: $600/month (2 instances, 1TB storage)
- **Total Estimated**: ~$3,300/month

**Cost Optimization Strategies:**
- **Reserved Capacity**: 40% savings on predictable workloads
- **Spot Instances**: Use for non-critical batch processing
- **S3 Intelligent Tiering**: Automatic cost optimization for analytics data
- **DynamoDB On-Demand**: Pay-per-request pricing for variable workloads

**Cost Monitoring:**
- **Budget Alerts**: 80% and 100% of monthly budget
- **Cost Anomaly Detection**: Unusual spending pattern alerts
- **Resource Optimization**: Weekly reviews of underutilized resources

## 11. Implementation Strategy

### 11.1 Migration/Deployment Plan

```mermaid
gantt
    title URL Shortener Implementation Timeline
    dateFormat  YYYY-MM-DD
    section Phase 1: Core Infrastructure
    VPC & Networking           :done,    infra1, 2024-01-01, 2024-01-07
    Database Setup             :done,    db1,    2024-01-08, 2024-01-14
    Basic API Gateway          :done,    api1,   2024-01-15, 2024-01-21
    
    section Phase 2: Core Services
    URL Shortener Service      :active,  core1,  2024-01-22, 2024-02-05
    Redirection Service        :         core2,  2024-02-06, 2024-02-19
    Basic Authentication       :         auth1,  2024-02-20, 2024-02-26
    
    section Phase 3: Performance & Scale
    Caching Layer              :         perf1,  2024-02-27, 2024-03-05
    CDN Integration            :         perf2,  2024-03-06, 2024-03-12
    Auto Scaling Setup         :         scale1, 2024-03-13, 2024-03-19
    
    section Phase 4: Analytics & Monitoring
    Analytics Pipeline         :         anal1,  2024-03-20, 2024-04-02
    Monitoring & Alerting      :         mon1,   2024-04-03, 2024-04-09
    Dashboard Development      :         dash1,  2024-04-10, 2024-04-16
    
    section Phase 5: Production Readiness
    Security Hardening         :         sec1,   2024-04-17, 2024-04-23
    Load Testing               :         test1,  2024-04-24, 2024-04-30
    Go-Live Preparation        :         live1,  2024-05-01, 2024-05-07
```

### 11.2 Technology Decisions & Trade-offs

**Database Selection Rationale:**
- **DynamoDB vs RDS**: Chose DynamoDB for URL mappings due to predictable access patterns and need for single-digit millisecond latency
- **Aurora for Analytics**: ACID compliance needed for financial and user data
- **ElastiCache Redis**: Superior performance over Memcached for complex data structures

**Service Architecture Trade-offs:**
- **Microservices vs Monolith**: Microservices chosen for independent scaling, despite increased operational complexity
- **Serverless vs Containers**: ECS Fargate for predictable workloads, Lambda for event processing
- **Synchronous vs Asynchronous**: Async analytics processing to maintain low latency for core operations

**Future Evolution Path:**
- **GraphQL API**: Consider for complex client requirements
- **Machine Learning**: Fraud detection and URL classification
- **Blockchain Integration**: Decentralized URL verification
- **Edge Computing**: Lambda@Edge for ultra-low latency redirections

**Technical Debt & Improvement Areas:**
- **Code Generation Algorithm**: Move from random to more sophisticated base62 encoding
- **Database Sharding**: Implement when DynamoDB limits are approached
- **Multi-Region Active-Active**: Currently active-passive setup
- **Advanced Analytics**: Real-time fraud detection and bot filtering
