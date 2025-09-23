# Data Patterns

## 🗄️ Overview

Data patterns provide proven solutions for managing, storing, and processing data in distributed systems. This guide covers data management, consistency, and storage patterns essential for building scalable, reliable data architectures.

## 📋 Table of Contents

### Data Management Patterns
1. [Database per Service Pattern](#1-database-per-service-pattern)
2. [Shared Database Pattern (Anti-Pattern)](#2-shared-database-pattern-anti-pattern)
3. [Data Lake Pattern](#3-data-lake-pattern)
4. [Data Warehouse Pattern](#4-data-warehouse-pattern)
5. [Lambda Architecture Pattern](#5-lambda-architecture-pattern)
6. [Kappa Architecture Pattern](#6-kappa-architecture-pattern)

### Data Consistency Patterns
7. [Saga Pattern](#7-saga-pattern)
8. [Two-Phase Commit Pattern](#8-two-phase-commit-pattern)
9. [Eventually Consistent Pattern](#9-eventually-consistent-pattern)
10. [Transactional Outbox Pattern](#10-transactional-outbox-pattern)
11. [Event Sourcing Pattern](#11-event-sourcing-pattern)

### Data Storage Patterns
12. [Polyglot Persistence Pattern](#12-polyglot-persistence-pattern)
13. [CQRS Pattern](#13-cqrs-pattern)
14. [Master-Slave Pattern](#14-master-slave-pattern)
15. [Master-Master Pattern](#15-master-master-pattern)
16. [Sharding Pattern](#16-sharding-pattern)

---

## Data Management Patterns

## 1. Database per Service Pattern

### 🏢 What is Database per Service?

Database per Service ensures each microservice **owns its data** exclusively, preventing tight coupling and enabling independent scaling and technology choices.

### Database per Service Architecture

```mermaid
graph TB
    subgraph "Database per Service Pattern"
        subgraph "User Service"
            UserService[User Service<br/>User management<br/>Authentication<br/>Profile data]
            UserDB[(User Database<br/>PostgreSQL<br/>ACID transactions<br/>Relational data)]
        end
        
        subgraph "Product Service"
            ProductService[Product Service<br/>Catalog management<br/>Search functionality<br/>Inventory tracking]
            ProductDB[(Product Database<br/>MongoDB<br/>Document storage<br/>Flexible schema)]
        end
        
        subgraph "Order Service"
            OrderService[Order Service<br/>Order processing<br/>Payment coordination<br/>Order history]
            OrderDB[(Order Database<br/>MySQL<br/>Transactional integrity<br/>Structured data)]
        end
        
        subgraph "Analytics Service"
            AnalyticsService[Analytics Service<br/>Data processing<br/>Reporting<br/>Business intelligence]
            AnalyticsDB[(Analytics Database<br/>Cassandra<br/>Time-series data<br/>High throughput)]
        end
        
        UserService --> UserDB
        ProductService --> ProductDB
        OrderService --> OrderDB
        AnalyticsService --> AnalyticsDB
        
        UserService -.->|API calls| OrderService
        OrderService -.->|API calls| ProductService
        ProductService -.->|Events| AnalyticsService
    end
```

### Benefits and Challenges

```mermaid
graph TB
    subgraph "Database per Service Trade-offs"
        subgraph "Benefits"
            Isolation[Data Isolation<br/>Service independence<br/>Failure containment<br/>Security boundaries]
            
            TechDiversity[Technology Diversity<br/>Choose optimal DB<br/>Polyglot persistence<br/>Performance optimization]
            
            Scaling[Independent Scaling<br/>Scale data layer separately<br/>Optimize for workload<br/>Cost efficiency]
        end
        
        subgraph "Challenges"
            Transactions[Distributed Transactions<br/>No ACID across services<br/>Eventual consistency<br/>Complex coordination]
            
            DataJoins[Cross-Service Queries<br/>No SQL joins<br/>Application-level joins<br/>Performance impact]
            
            DataConsistency[Data Consistency<br/>Synchronization complexity<br/>Conflict resolution<br/>Monitoring overhead]
        end
    end
```

---

## 2. Shared Database Pattern (Anti-Pattern)

### ⚠️ Why is Shared Database an Anti-Pattern?

Shared Database creates **tight coupling** between services through shared data structures, violating microservices principles and creating operational bottlenecks.

### Shared Database Problems

```mermaid
graph TB
    subgraph "Shared Database Anti-Pattern"
        subgraph "Multiple Services"
            UserService[User Service]
            OrderService[Order Service]
            ProductService[Product Service]
            PaymentService[Payment Service]
        end
        
        subgraph "Shared Database"
            SharedDB[(Shared Database<br/>Single point of failure<br/>Schema coupling<br/>Performance bottleneck)]
        end
        
        UserService --> SharedDB
        OrderService --> SharedDB
        ProductService --> SharedDB
        PaymentService --> SharedDB
        
        subgraph "Problems"
            Problems[❌ Schema changes affect all services<br/>❌ Database becomes bottleneck<br/>❌ Services can't scale independently<br/>❌ Technology lock-in<br/>❌ Deployment coupling<br/>❌ Security boundary violations]
        end
    end
```

---

## 3. Data Lake Pattern

### 🏞️ What is Data Lake Pattern?

Data Lake stores **raw data in native format** at scale, enabling diverse analytics workloads and machine learning without predefined schemas.

### Data Lake Architecture

```mermaid
graph TB
    subgraph "Data Lake Architecture"
        subgraph "Data Sources"
            WebLogs[Web Server Logs<br/>Click streams<br/>User behavior]
            AppData[Application Data<br/>Transactions<br/>User profiles]
            IoTData[IoT Sensors<br/>Device telemetry<br/>Real-time streams]
            SocialData[Social Media<br/>User-generated content<br/>External APIs]
        end
        
        subgraph "Data Ingestion"
            BatchIngestion[Batch Ingestion<br/>ETL pipelines<br/>Scheduled jobs<br/>Large datasets]
            StreamIngestion[Stream Ingestion<br/>Real-time processing<br/>Kafka, Kinesis<br/>Low latency]
        end
        
        subgraph "Data Lake Storage"
            RawZone[Raw Zone<br/>Unprocessed data<br/>Original format<br/>Data lineage]
            ProcessedZone[Processed Zone<br/>Cleaned data<br/>Standardized format<br/>Quality assured]
            CuratedZone[Curated Zone<br/>Business-ready data<br/>Aggregated views<br/>Optimized access]
        end
        
        subgraph "Analytics & ML"
            BatchAnalytics[Batch Analytics<br/>Spark, Hadoop<br/>Historical analysis<br/>Business intelligence]
            StreamAnalytics[Stream Analytics<br/>Real-time processing<br/>Anomaly detection<br/>Live dashboards]
            MLWorkloads[ML Workloads<br/>Model training<br/>Feature engineering<br/>Predictions]
        end
        
        WebLogs --> BatchIngestion
        AppData --> BatchIngestion
        IoTData --> StreamIngestion
        SocialData --> StreamIngestion
        
        BatchIngestion --> RawZone
        StreamIngestion --> RawZone
        RawZone --> ProcessedZone
        ProcessedZone --> CuratedZone
        
        CuratedZone --> BatchAnalytics
        CuratedZone --> StreamAnalytics
        CuratedZone --> MLWorkloads
    end
```

---

## 4. Data Warehouse Pattern

### 🏭 What is Data Warehouse Pattern?

Data Warehouse provides **structured, optimized storage** for analytical workloads with predefined schemas and business intelligence focus.

### Data Warehouse vs Data Lake

```mermaid
graph TB
    subgraph "Data Warehouse vs Data Lake"
        subgraph "Data Warehouse"
            DWChar[Data Warehouse<br/>✅ Structured data<br/>✅ Predefined schema<br/>✅ Fast queries<br/>✅ Business intelligence<br/>❌ Less flexible<br/>❌ Higher cost per GB]
            
            DWUse[Use Cases:<br/>• Business reporting<br/>• Financial analysis<br/>• Compliance reporting<br/>• Executive dashboards]
        end
        
        subgraph "Data Lake"
            DLChar[Data Lake<br/>✅ Raw data storage<br/>✅ Schema on read<br/>✅ Cost effective<br/>✅ ML/AI workloads<br/>❌ Slower queries<br/>❌ Data governance challenges]
            
            DLUse[Use Cases:<br/>• Machine learning<br/>• Data exploration<br/>• IoT analytics<br/>• Unstructured data]
        end
        
        subgraph "Hybrid Approach"
            Hybrid[Data Lakehouse<br/>✅ Best of both worlds<br/>✅ ACID transactions<br/>✅ Schema enforcement<br/>✅ ML + BI workloads]
        end
    end
```

---

## 5. Lambda Architecture Pattern

### λ What is Lambda Architecture?

Lambda Architecture processes data through **both batch and stream processing layers** to provide comprehensive analytics with both historical and real-time views.

### Lambda Architecture Components

```mermaid
graph TB
    subgraph "Lambda Architecture"
        subgraph "Data Sources"
            DataSources[Data Sources<br/>User events<br/>IoT sensors<br/>Application logs<br/>External APIs]
        end
        
        subgraph "Batch Layer"
            BatchStorage[Master Dataset<br/>Immutable, append-only<br/>Complete historical data<br/>HDFS, S3]
            
            BatchProcessing[Batch Processing<br/>MapReduce, Spark<br/>Complex computations<br/>High latency, high throughput]
            
            BatchViews[Batch Views<br/>Precomputed results<br/>Historical accuracy<br/>Complete dataset analysis]
        end
        
        subgraph "Speed Layer"
            StreamProcessing[Stream Processing<br/>Storm, Kafka Streams<br/>Real-time processing<br/>Low latency, approximate]
            
            RealtimeViews[Realtime Views<br/>Recent data only<br/>Fast updates<br/>Incremental processing]
        end
        
        subgraph "Serving Layer"
            ServingLayer[Serving Layer<br/>Query interface<br/>Merge batch + realtime<br/>Unified API]
        end
        
        DataSources --> BatchStorage
        DataSources --> StreamProcessing
        
        BatchStorage --> BatchProcessing
        BatchProcessing --> BatchViews
        
        StreamProcessing --> RealtimeViews
        
        BatchViews --> ServingLayer
        RealtimeViews --> ServingLayer
    end
```

---

## 6. Kappa Architecture Pattern

### κ What is Kappa Architecture?

Kappa Architecture simplifies Lambda by using **only stream processing** for both real-time and batch workloads, treating batch as a special case of streaming.

### Kappa vs Lambda Comparison

```mermaid
graph TB
    subgraph "Kappa Architecture"
        subgraph "Stream-Only Processing"
            EventLog[Event Log<br/>Kafka, Pulsar<br/>Immutable event stream<br/>Replay capability]
            
            StreamProcessor[Stream Processor<br/>Kafka Streams, Flink<br/>Unified processing model<br/>Stateful computations]
            
            MaterializedViews[Materialized Views<br/>Real-time + historical<br/>Continuous updates<br/>Query-optimized storage]
        end
        
        EventLog --> StreamProcessor
        StreamProcessor --> MaterializedViews
        
        subgraph "Advantages"
            Advantages[✅ Simpler architecture<br/>✅ Single processing model<br/>✅ Real-time by default<br/>✅ Easy to reason about<br/>❌ Limited by stream processing capabilities]
        end
    end
```

---

## Data Consistency Patterns

## 7. Saga Pattern

### 🎭 What is Saga Pattern?

Saga Pattern manages **distributed transactions** across multiple services using compensating actions instead of traditional ACID transactions.

### Saga Implementation Types

```mermaid
graph TB
    subgraph "Saga Pattern Types"
        subgraph "Orchestrator Saga"
            Orchestrator[Orchestrator Saga<br/>Centralized coordinator<br/>Explicit workflow<br/>Easy to monitor<br/>Single point of failure]
        end
        
        subgraph "Choreography Saga"
            Choreography[Choreography Saga<br/>Distributed coordination<br/>Event-driven<br/>No single point of failure<br/>Complex to monitor]
        end
    end
```

### Saga Transaction Flow

```mermaid
sequenceDiagram
    participant OrderService
    participant PaymentService
    participant InventoryService
    participant ShippingService
    
    OrderService->>PaymentService: Process Payment
    PaymentService-->>OrderService: Payment Success
    
    OrderService->>InventoryService: Reserve Items
    InventoryService-->>OrderService: Items Reserved
    
    OrderService->>ShippingService: Create Shipment
    ShippingService-->>OrderService: Shipping Failed ❌
    
    Note over OrderService: Compensation Phase
    OrderService->>InventoryService: Cancel Reservation
    InventoryService-->>OrderService: Reservation Cancelled
    
    OrderService->>PaymentService: Refund Payment
    PaymentService-->>OrderService: Payment Refunded
```

---

## 8. Two-Phase Commit Pattern

### 🔄 What is Two-Phase Commit?

Two-Phase Commit ensures **ACID properties** across distributed databases through a coordinator that manages prepare and commit phases.

### 2PC Protocol Flow

```mermaid
sequenceDiagram
    participant App as Application
    participant Coordinator as Transaction Coordinator
    participant DB1 as Database 1
    participant DB2 as Database 2
    participant DB3 as Database 3
    
    App->>Coordinator: Begin Transaction
    
    Note over Coordinator,DB3: Phase 1: Prepare
    Coordinator->>DB1: Prepare to commit
    Coordinator->>DB2: Prepare to commit
    Coordinator->>DB3: Prepare to commit
    
    DB1-->>Coordinator: Ready to commit
    DB2-->>Coordinator: Ready to commit
    DB3-->>Coordinator: Ready to commit
    
    Note over Coordinator,DB3: Phase 2: Commit
    Coordinator->>DB1: Commit
    Coordinator->>DB2: Commit
    Coordinator->>DB3: Commit
    
    DB1-->>Coordinator: Committed
    DB2-->>Coordinator: Committed
    DB3-->>Coordinator: Committed
    
    Coordinator-->>App: Transaction Complete
```

### 2PC Limitations

```mermaid
graph TB
    subgraph "Two-Phase Commit Limitations"
        subgraph "Problems"
            BlockingProtocol[Blocking Protocol<br/>Participants wait for coordinator<br/>Poor performance<br/>Availability issues]
            
            SinglePointFailure[Coordinator Failure<br/>Single point of failure<br/>Transaction blocking<br/>Manual intervention needed]
            
            PartialFailure[Partial Failure Handling<br/>Network partitions<br/>Uncertain outcomes<br/>Data inconsistency risk]
        end
        
        subgraph "Why Avoid in Microservices"
            Reasons[❌ Reduces availability<br/>❌ Tight coupling<br/>❌ Poor scalability<br/>❌ Complex error handling<br/>✅ Use Saga instead]
        end
    end
```

---

## 9. Eventually Consistent Pattern

### ⏳ What is Eventually Consistent?

Eventually Consistent systems guarantee that **all replicas will converge** to the same state given enough time, trading immediate consistency for availability and performance.

### Eventually Consistent Implementation

```mermaid
graph TB
    subgraph "Eventually Consistent Pattern"
        subgraph "Write Operation"
            Client[Client] --> WriteRequest[Write Request<br/>Update user profile]
            WriteRequest --> PrimaryReplica[Primary Replica<br/>Immediate write<br/>Acknowledge client]
        end
        
        subgraph "Asynchronous Replication"
            PrimaryReplica --> AsyncReplication[Async Replication<br/>Background process<br/>Network optimized<br/>Eventual propagation]
            
            AsyncReplication --> Replica1[Replica 1<br/>Eventually consistent<br/>May be stale]
            AsyncReplication --> Replica2[Replica 2<br/>Eventually consistent<br/>May be stale]
            AsyncReplication --> Replica3[Replica 3<br/>Eventually consistent<br/>May be stale]
        end
        
        subgraph "Read Operations"
            ReadClient1[Read Client 1] --> Replica1
            ReadClient2[Read Client 2] --> Replica2
            ReadClient3[Read Client 3] --> Replica3
        end
        
        subgraph "Characteristics"
            Characteristics[⚡ High availability<br/>📈 Better performance<br/>🌐 Partition tolerance<br/>❓ Temporary inconsistency]
        end
    end
```

---

## 10. Transactional Outbox Pattern

### 📮 What is Transactional Outbox?

Transactional Outbox ensures **reliable message publishing** by storing events in the same database transaction as business data, then publishing asynchronously.

### Outbox Implementation

```mermaid
sequenceDiagram
    participant App as Application
    participant DB as Database
    participant OutboxTable as Outbox Table
    participant MessageRelay as Message Relay
    participant MessageBroker as Message Broker
    
    Note over App,MessageBroker: Business Transaction
    App->>DB: Begin Transaction
    App->>DB: Update business data
    App->>OutboxTable: Insert event record
    App->>DB: Commit Transaction
    DB-->>App: Transaction Success
    
    Note over MessageRelay,MessageBroker: Asynchronous Publishing
    MessageRelay->>OutboxTable: Poll for new events
    OutboxTable-->>MessageRelay: Return unpublished events
    MessageRelay->>MessageBroker: Publish events
    MessageBroker-->>MessageRelay: Publish confirmed
    MessageRelay->>OutboxTable: Mark events as published
```

### Outbox Table Schema

```sql
-- Transactional Outbox Table
CREATE TABLE outbox_events (
    id UUID PRIMARY KEY,
    aggregate_id UUID NOT NULL,
    event_type VARCHAR(255) NOT NULL,
    event_data JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    published_at TIMESTAMP NULL,
    version INTEGER NOT NULL
);

-- Index for efficient polling
CREATE INDEX idx_outbox_unpublished 
ON outbox_events (created_at) 
WHERE published_at IS NULL;
```

---

## Data Storage Patterns

## 12. Polyglot Persistence Pattern

### 🗣️ What is Polyglot Persistence?

Polyglot Persistence uses **different databases** for different data storage needs, optimizing each data store for its specific use case.

### Polyglot Persistence Strategy

```mermaid
graph TB
    subgraph "Polyglot Persistence Pattern"
        subgraph "Application Services"
            UserService[User Service]
            ProductService[Product Service]
            OrderService[Order Service]
            AnalyticsService[Analytics Service]
            SearchService[Search Service]
        end
        
        subgraph "Specialized Data Stores"
            PostgreSQL[(PostgreSQL<br/>User profiles<br/>ACID transactions<br/>Relational integrity)]
            
            MongoDB[(MongoDB<br/>Product catalog<br/>Flexible schema<br/>Document storage)]
            
            Redis[(Redis<br/>Session data<br/>Caching layer<br/>High performance)]
            
            Cassandra[(Cassandra<br/>Time-series data<br/>High write throughput<br/>Linear scalability)]
            
            Elasticsearch[(Elasticsearch<br/>Full-text search<br/>Complex queries<br/>Real-time indexing)]
        end
        
        UserService --> PostgreSQL
        UserService --> Redis
        ProductService --> MongoDB
        OrderService --> PostgreSQL
        AnalyticsService --> Cassandra
        SearchService --> Elasticsearch
        
        subgraph "Selection Criteria"
            Criteria[📊 Data structure<br/>🔍 Query patterns<br/>📈 Scalability needs<br/>🔒 Consistency requirements<br/>⚡ Performance demands]
        end
    end
```

---

## 13. CQRS Pattern

### 🔄 What is CQRS?

CQRS (Command Query Responsibility Segregation) **separates read and write operations** using different models optimized for their specific purposes.

### CQRS Architecture

```mermaid
graph TB
    subgraph "CQRS Pattern"
        subgraph "Command Side (Write)"
            Commands[Commands<br/>Create, Update, Delete<br/>Business operations]
            CommandHandlers[Command Handlers<br/>Business logic<br/>Validation rules<br/>Domain models]
            WriteStore[(Write Store<br/>Normalized schema<br/>ACID compliance<br/>Optimized for writes)]
        end
        
        subgraph "Query Side (Read)"
            Queries[Queries<br/>Read operations<br/>Data retrieval<br/>Reporting]
            QueryHandlers[Query Handlers<br/>Data access logic<br/>View composition<br/>Read models]
            ReadStore[(Read Store<br/>Denormalized views<br/>Query optimization<br/>Multiple projections)]
        end
        
        subgraph "Synchronization"
            EventBus[Event Bus<br/>Domain events<br/>Async messaging<br/>Eventual consistency]
        end
        
        Commands --> CommandHandlers
        CommandHandlers --> WriteStore
        CommandHandlers --> EventBus
        
        EventBus --> QueryHandlers
        QueryHandlers --> ReadStore
        Queries --> QueryHandlers
    end
```

---

## 14. Master-Slave Pattern

### 👑 What is Master-Slave Pattern?

Master-Slave Pattern designates **one primary database** for writes and multiple replicas for reads, providing read scalability and fault tolerance.

### Master-Slave Replication

```mermaid
graph TB
    subgraph "Master-Slave Replication"
        subgraph "Write Operations"
            WriteClients[Write Clients<br/>Applications<br/>Admin tools] --> Master[(Master Database<br/>Primary replica<br/>Handles all writes<br/>Source of truth)]
        end
        
        subgraph "Read Operations"
            ReadClient1[Read Client 1] --> Slave1[(Slave 1<br/>Read replica<br/>Async replication<br/>Eventually consistent)]
            ReadClient2[Read Client 2] --> Slave2[(Slave 2<br/>Read replica<br/>Load distribution<br/>Geographic distribution)]
            ReadClient3[Read Client 3] --> Slave3[(Slave 3<br/>Read replica<br/>Disaster recovery<br/>Backup purposes)]
        end
        
        subgraph "Replication Process"
            Master --> ReplicationLog[Replication Log<br/>Binary log<br/>Transaction log<br/>Change stream]
            ReplicationLog --> Slave1
            ReplicationLog --> Slave2
            ReplicationLog --> Slave3
        end
        
        subgraph "Failover Process"
            HealthMonitoring[Health Monitoring<br/>Master availability<br/>Automatic detection<br/>Failover triggers]
            SlavePromotion[Slave Promotion<br/>Promote slave to master<br/>Update application config<br/>Resume operations]
        end
    end
```

---

## 15. Master-Master Pattern

### 👑👑 What is Master-Master Pattern?

Master-Master Pattern allows **multiple databases** to accept writes simultaneously, providing high availability but requiring conflict resolution.

### Master-Master Challenges

```mermaid
graph TB
    subgraph "Master-Master Replication"
        subgraph "Active Masters"
            Master1[(Master 1<br/>US East<br/>Accepts writes<br/>Bidirectional sync)]
            Master2[(Master 2<br/>US West<br/>Accepts writes<br/>Bidirectional sync)]
        end
        
        subgraph "Conflict Resolution"
            ConflictDetection[Conflict Detection<br/>Same record updates<br/>Timestamp comparison<br/>Vector clocks]
            
            ResolutionStrategies[Resolution Strategies<br/>Last-writer-wins<br/>Business rules<br/>Manual intervention]
        end
        
        Master1 <--> Master2
        Master1 --> ConflictDetection
        Master2 --> ConflictDetection
        ConflictDetection --> ResolutionStrategies
        
        subgraph "Trade-offs"
            Benefits[✅ High availability<br/>✅ Local writes<br/>✅ Load distribution]
            Challenges[❌ Conflict resolution<br/>❌ Complex consistency<br/>❌ Data integrity risks]
        end
    end
```

---

## 16. Sharding Pattern

### ⚡ What is Sharding Pattern?

Sharding **horizontally partitions data** across multiple databases based on a shard key, enabling linear scalability for large datasets.

### Sharding Strategies

```mermaid
graph TB
    subgraph "Sharding Strategies"
        subgraph "Range-Based Sharding"
            RangeSharding[Range-Based Sharding<br/>Partition by value ranges<br/>user_id: 1-1000 → Shard 1<br/>user_id: 1001-2000 → Shard 2<br/>✅ Simple<br/>❌ Hot spots possible]
        end
        
        subgraph "Hash-Based Sharding"
            HashSharding[Hash-Based Sharding<br/>hash(user_id) % shard_count<br/>Even distribution<br/>✅ Balanced load<br/>❌ Range queries difficult]
        end
        
        subgraph "Directory-Based Sharding"
            DirectorySharding[Directory-Based Sharding<br/>Lookup service<br/>Flexible mapping<br/>✅ Dynamic rebalancing<br/>❌ Additional complexity]
        end
        
        subgraph "Consistent Hashing"
            ConsistentHashing[Consistent Hashing<br/>Hash ring<br/>Minimal data movement<br/>✅ Easy rebalancing<br/>✅ Fault tolerant]
        end
    end
```

### Sharding Implementation

```mermaid
graph TB
    subgraph "Sharding Implementation"
        subgraph "Application Layer"
            ShardingProxy[Sharding Proxy<br/>Route queries<br/>Aggregate results<br/>Handle failures]
        end
        
        subgraph "Shard Distribution"
            Shard1[(Shard 1<br/>Users 1-10M<br/>US East<br/>High performance)]
            Shard2[(Shard 2<br/>Users 10M-20M<br/>US West<br/>Regional data)]
            Shard3[(Shard 3<br/>Users 20M-30M<br/>EU<br/>Compliance)]
        end
        
        subgraph "Cross-Shard Operations"
            Aggregation[Result Aggregation<br/>Merge query results<br/>Sort and paginate<br/>Handle partial failures]
            
            DistributedTransactions[Distributed Transactions<br/>Two-phase commit<br/>Saga pattern<br/>Eventual consistency]
        end
        
        ShardingProxy --> Shard1
        ShardingProxy --> Shard2
        ShardingProxy --> Shard3
        
        ShardingProxy --> Aggregation
        ShardingProxy --> DistributedTransactions
    end
```

## Real-World Data Pattern Examples

### Netflix Data Architecture

```mermaid
graph TB
    subgraph "Netflix Data Platform"
        subgraph "Operational Data"
            Microservices[700+ Microservices<br/>Database per service<br/>Polyglot persistence<br/>Independent scaling]
            
            Cassandra[Cassandra Clusters<br/>User viewing history<br/>Recommendation data<br/>Global distribution]
        end
        
        subgraph "Analytics Pipeline"
            DataIngestion[Data Ingestion<br/>Kafka streams<br/>Real-time events<br/>Batch processing]
            
            DataLake[S3 Data Lake<br/>Raw event data<br/>Video metadata<br/>User interactions]
            
            StreamProcessing[Stream Processing<br/>Kafka Streams<br/>Flink jobs<br/>Real-time analytics]
        end
        
        subgraph "ML Platform"
            FeatureStore[Feature Store<br/>ML features<br/>Real-time serving<br/>Batch computation]
            
            MLPipelines[ML Pipelines<br/>Recommendation models<br/>Content analysis<br/>A/B testing]
        end
        
        Microservices --> DataIngestion
        DataIngestion --> DataLake
        DataIngestion --> StreamProcessing
        
        DataLake --> FeatureStore
        StreamProcessing --> MLPipelines
        FeatureStore --> MLPipelines
    end
```

## 🎯 Key Takeaways

### Data Pattern Selection ✅

1. **Database per Service** - Essential for microservices independence
2. **Polyglot Persistence** - Choose right database for each use case
3. **CQRS** - Separate read/write when patterns differ significantly
4. **Event Sourcing** - When audit trail and replay capability needed
5. **Saga Pattern** - For distributed transactions across services
6. **Sharding** - When single database can't handle the load

### Implementation Guidelines ✅

1. **Start Simple** - Begin with single database, add complexity as needed
2. **Plan for Consistency** - Understand CAP theorem trade-offs
3. **Monitor Data Quality** - Implement data validation and monitoring
4. **Design for Scale** - Consider future growth in data patterns
5. **Test Failure Scenarios** - Validate data consistency under failures
6. **Document Data Flow** - Clear understanding of data movement

### Common Pitfalls to Avoid ❌

1. **Shared Database** - Avoid coupling services through shared data
2. **Ignoring Consistency** - Plan for eventual consistency challenges
3. **Over-Sharding** - Don't shard prematurely without clear need
4. **Poor Shard Key Choice** - Avoid hot spots and uneven distribution
5. **Missing Data Governance** - Implement proper data management
6. **Inadequate Monitoring** - Monitor data consistency and performance

### Remember
> "Data patterns are not just about storage - they're about enabling business capabilities while maintaining consistency, performance, and scalability as your system grows."

This comprehensive guide provides essential data patterns for building scalable, consistent data architectures. Each pattern addresses specific data management challenges and should be implemented based on your consistency, performance, and scalability requirements.
