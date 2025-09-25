# AWS Services Decision-Making Cheatsheet
*When to use what AWS service and when to combine which services*

## Table of Contents
1. [Service Categories & Decision Trees](#service-categories--decision-trees)
2. [Service Combination Patterns](#service-combination-patterns)
3. [Decision Matrix Format](#decision-matrix-format)
4. [Cost vs Performance vs Management Trade-offs](#cost-vs-performance-vs-management-trade-offs)
5. [Quick Reference Cards](#quick-reference-cards)
6. [Regional & Global Architecture Decisions](#regional--global-architecture-decisions)
7. [Security & Compliance Combinations](#security--compliance-combinations)

---

## Service Categories & Decision Trees

### Compute Services

#### When to Use Each Service:

| Service | Use When | Don't Use When | Key Decision Factors |
|---------|----------|----------------|---------------------|
| **EC2** | - Persistent workloads<br>- Custom OS/kernel needs<br>- Legacy applications<br>- High-performance computing | - Event-driven workloads<br>- Infrequent usage<br>- Want zero server management | Control, performance, cost predictability |
| **Lambda** | - Event-driven processing<br>- Microservices<br>- Serverless applications<br>- Short-running tasks (<15 min) | - Long-running processes<br>- Complex state management<br>- High-frequency invocations | Event-driven, auto-scaling, pay-per-use |
| **ECS** | - Containerized applications<br>- Docker expertise<br>- Mixed workload types<br>- AWS integration needed | - Kubernetes preference<br>- Multi-cloud strategy<br>- Complex orchestration | Container orchestration, AWS native |
| **EKS** | - Kubernetes expertise<br>- Multi-cloud portability<br>- Complex microservices<br>- Advanced scheduling needs | - Simple containerization<br>- Cost-sensitive projects<br>- AWS-only strategy | Kubernetes compatibility, portability |
| **Fargate** | - Serverless containers<br>- No infrastructure management<br>- Variable workloads | - Cost optimization critical<br>- Specialized instance needs<br>- High-performance computing | Serverless, managed infrastructure |
| **Batch** | - Large-scale batch processing<br>- Scientific computing<br>- ETL jobs<br>- Queue-based processing | - Real-time processing<br>- Interactive workloads<br>- Simple batch jobs | Batch processing, job queues, scaling |
| **Lightsail** | - Simple web applications<br>- Development/testing<br>- Small business apps<br>- WordPress sites | - Enterprise applications<br>- High availability needs<br>- Complex architectures | Simplicity, fixed pricing, ease of use |

#### Compute Decision Tree:
```
Need compute? 
├── Event-driven/short tasks? → Lambda
├── Batch processing? → AWS Batch
├── Containers?
│   ├── Want Kubernetes? → EKS
│   ├── Want serverless? → Fargate
│   └── Want control? → ECS
├── Simple website/app? → Lightsail
└── Custom/persistent needs? → EC2
```

### Storage Services

#### When to Use Each Service:

| Service | Use When | Don't Use When | Key Decision Factors |
|---------|----------|----------------|---------------------|
| **S3** | - Object storage<br>- Static websites<br>- Data archiving<br>- Content distribution | - File system needs<br>- High IOPS requirements<br>- Frequent small updates | Durability, scalability, web integration |
| **EBS** | - Database storage<br>- File systems<br>- High IOPS applications<br>- Persistent block storage | - Shared file access<br>- Object storage needs<br>- Cross-AZ sharing | Performance, persistence, single-AZ |
| **EFS** | - Shared file storage<br>- Multi-AZ access<br>- POSIX compliance<br>- Container persistent storage | - High IOPS databases<br>- Windows file shares<br>- Object storage | POSIX, shared access, multi-AZ |
| **FSx** | - Windows file shares<br>- Lustre for HPC<br>- High-performance workloads<br>- Legacy applications | - Simple file sharing<br>- Cost-sensitive projects<br>- Object storage | Windows compatibility, HPC, performance |
| **Storage Gateway** | - Hybrid cloud storage<br>- On-premises integration<br>- Gradual migration<br>- Backup to cloud | - Cloud-native applications<br>- No on-premises needs<br>- Real-time access | Hybrid integration, migration |

#### Storage Decision Tree:
```
Need storage?
├── Object storage? → S3
├── Block storage for single instance? → EBS
├── Shared file system?
│   ├── POSIX/Linux? → EFS
│   ├── Windows? → FSx for Windows
│   └── HPC/Lustre? → FSx for Lustre
└── Hybrid/on-premises? → Storage Gateway
```

### Database Services

#### When to Use Each Service:

| Service | Use When | Don't Use When | Key Decision Factors |
|---------|----------|----------------|---------------------|
| **RDS** | - Relational data<br>- ACID transactions<br>- Existing SQL applications<br>- Structured data with relationships | - NoSQL needs<br>- Massive scale (>64TB)<br>- Complex analytics | ACID, SQL compatibility, managed |
| **Aurora** | - High-performance relational<br>- MySQL/PostgreSQL compatibility<br>- Read-heavy workloads<br>- Global applications | - Simple applications<br>- Cost-sensitive projects<br>- NoSQL requirements | Performance, compatibility, read scaling |
| **DynamoDB** | - NoSQL applications<br>- Massive scale<br>- Variable workloads<br>- Serverless architectures | - Complex queries<br>- ACID across items<br>- Relational data | NoSQL, scale, serverless integration |
| **Redshift** | - Data warehousing<br>- Analytics workloads<br>- Historical data analysis<br>- Business intelligence | - OLTP workloads<br>- Real-time queries<br>- Small datasets | Analytics, warehousing, columnar |
| **DocumentDB** | - MongoDB compatibility<br>- Document databases<br>- JSON data<br>- Managed MongoDB | - Relational data<br>- MongoDB not required<br>- Cost optimization | MongoDB compatibility, document model |
| **Neptune** | - Graph databases<br>- Social networks<br>- Recommendation engines<br>- Fraud detection | - Relational data<br>- Simple key-value<br>- Document storage | Graph relationships, traversal queries |
| **Timestream** | - Time-series data<br>- IoT applications<br>- Monitoring metrics<br>- Real-time analytics | - Relational data<br>- Document storage<br>- Static datasets | Time-series, IoT, real-time |
| **QLDB** | - Immutable ledger<br>- Audit trails<br>- Regulatory compliance<br>- Cryptographic verification | - Mutable data<br>- High-volume OLTP<br>- Complex queries | Immutability, audit, verification |

#### Database Decision Tree:
```
Need database?
├── Relational/SQL?
│   ├── High performance? → Aurora
│   ├── Standard needs? → RDS
│   └── Analytics/DW? → Redshift
├── NoSQL?
│   ├── Key-value/document? → DynamoDB
│   ├── MongoDB compatible? → DocumentDB
│   └── Graph data? → Neptune
├── Time-series? → Timestream
└── Immutable ledger? → QLDB
```

### Networking Services

#### When to Use Each Service:

| Service | Use When | Don't Use When | Key Decision Factors |
|---------|----------|----------------|---------------------|
| **ALB** | - HTTP/HTTPS traffic<br>- Microservices<br>- Content-based routing<br>- WebSocket support | - TCP/UDP traffic<br>- Ultra-low latency<br>- Simple load balancing | Layer 7, HTTP features, routing |
| **NLB** | - TCP/UDP traffic<br>- Ultra-low latency<br>- Static IP requirements<br>- High throughput | - HTTP-specific features<br>- Content-based routing<br>- WebSocket termination | Layer 4, performance, static IP |
| **CLB** | - Legacy applications<br>- Simple load balancing<br>- EC2-Classic<br>- Basic SSL termination | - New applications<br>- Advanced routing<br>- Container services | Legacy support, simplicity |
| **API Gateway** | - REST/HTTP APIs<br>- Serverless backends<br>- API management<br>- Authentication integration | - GraphQL (use AppSync)<br>- WebSocket (use v2)<br>- Internal APIs only | API management, serverless, auth |
| **CloudFront** | - Content delivery<br>- Global distribution<br>- Static/dynamic content<br>- DDoS protection | - Internal applications<br>- Single region<br>- Real-time bidirectional | CDN, global reach, caching |
| **Route 53** | - DNS management<br>- Health checks<br>- Traffic routing<br>- Domain registration | - Simple DNS only<br>- Cost optimization<br>- Single endpoint | DNS, routing policies, health checks |

#### Networking Decision Tree:
```
Need networking?
├── Load balancing?
│   ├── HTTP/HTTPS? → ALB
│   ├── TCP/UDP? → NLB
│   └── Legacy? → CLB
├── API management? → API Gateway
├── Content delivery? → CloudFront
└── DNS/routing? → Route 53
```

---

## Service Combination Patterns

### Web Applications Pattern
**Stack:** CloudFront + ALB + EC2/ECS + RDS + S3

#### When to Use:
- Traditional web applications
- Multi-tier architectures
- Predictable traffic patterns
- Need for persistent state

#### Architecture:
```
Internet → CloudFront → ALB → EC2/ECS → RDS
                            ↓
                           S3 (static assets)
```

#### Benefits:
- High availability across AZs
- CDN for global performance
- Managed database
- Scalable compute tier

#### Cost Optimization:
- Use S3 for static content
- Implement CloudFront caching
- Right-size EC2 instances
- Use RDS reserved instances

### Serverless Pattern
**Stack:** API Gateway + Lambda + DynamoDB + S3

#### When to Use:
- Event-driven applications
- Variable/unpredictable traffic
- Microservices architecture
- Want zero server management

#### Architecture:
```
Client → API Gateway → Lambda → DynamoDB
                    ↓
                   S3 (files/static)
```

#### Benefits:
- Pay-per-use pricing
- Automatic scaling
- No server management
- High availability built-in

#### Considerations:
- Cold start latency
- 15-minute execution limit
- Vendor lock-in
- Debugging complexity

### Data Analytics Pattern
**Option A:** S3 + Glue + Athena + QuickSight
**Option B:** Kinesis + Lambda + Redshift + QuickSight

#### Option A - Batch Analytics:
```
Data Sources → S3 → Glue (ETL) → Athena → QuickSight
```

**Use When:**
- Batch processing acceptable
- Cost optimization priority
- Ad-hoc querying needed
- Large datasets

#### Option B - Real-time Analytics:
```
Data Sources → Kinesis → Lambda → Redshift → QuickSight
```

**Use When:**
- Real-time insights needed
- Structured analytics
- Performance critical
- Business intelligence focus

### Microservices Pattern
**Stack:** ALB + EKS/ECS + RDS/DynamoDB + ElastiCache

#### When to Use:
- Distributed applications
- Team autonomy needed
- Technology diversity
- Independent scaling

#### Architecture:
```
Internet → ALB → EKS/ECS (services) → RDS/DynamoDB
                      ↓
                 ElastiCache
```

#### Service Selection:
- **Container Platform:** EKS (Kubernetes) vs ECS (AWS native)
- **Database:** RDS (relational) vs DynamoDB (NoSQL)
- **Caching:** ElastiCache Redis (complex) vs Memcached (simple)

### Batch Processing Pattern
**Stack:** S3 + Lambda + Batch + SQS

#### When to Use:
- Large-scale data processing
- Scientific computing
- ETL operations
- Scheduled jobs

#### Architecture:
```
S3 (trigger) → Lambda (orchestrator) → SQS → Batch
```

#### Workflow:
1. S3 event triggers Lambda
2. Lambda submits jobs to SQS
3. Batch processes jobs
4. Results stored in S3

### Real-time Streaming Pattern
**Stack:** Kinesis Data Streams + Analytics + Firehose + S3/Redshift

#### When to Use:
- Real-time data processing
- IoT data ingestion
- Log analysis
- Event streaming

#### Architecture:
```
Data Sources → Kinesis Streams → Kinesis Analytics → Kinesis Firehose → S3/Redshift
```

#### Components:
- **Streams:** Real-time data ingestion
- **Analytics:** SQL queries on streaming data
- **Firehose:** Data delivery to storage
- **Destinations:** S3 (data lake) or Redshift (analytics)

---

## Decision Matrix Format

### High Traffic Web Application

| Factor | Weight | EC2 + ALB | Lambda + API GW | EKS + ALB |
|--------|--------|-----------|-----------------|-----------|
| **Performance** | High | ✅ Excellent | ⚠️ Cold starts | ✅ Excellent |
| **Scalability** | High | ✅ Auto Scaling | ✅ Automatic | ✅ HPA/VPA |
| **Cost** | Medium | ⚠️ Always-on | ✅ Pay-per-use | ⚠️ Complex pricing |
| **Management** | Low | ⚠️ More setup | ✅ Serverless | ❌ Complex |
| **Reliability** | High | ✅ Multi-AZ | ✅ Built-in | ✅ Self-healing |

**Recommendation:** EC2 + ALB for consistent traffic, Lambda for variable traffic

### IoT Data Processing

| Factor | Weight | Kinesis + Lambda | SQS + Batch | Kafka on EC2 |
|--------|--------|------------------|-------------|--------------|
| **Real-time** | High | ✅ Sub-second | ❌ Batch only | ✅ Real-time |
| **Scale** | High | ✅ Managed scaling | ✅ Job scaling | ⚠️ Manual scaling |
| **Cost** | Medium | ✅ Pay-per-use | ✅ Spot instances | ❌ Always-on |
| **Complexity** | Low | ✅ Managed | ✅ Simple | ❌ Self-managed |
| **Throughput** | High | ✅ Very high | ⚠️ Depends on jobs | ✅ Very high |

**Recommendation:** Kinesis + Lambda for real-time, SQS + Batch for cost-optimized batch

### Machine Learning Training

| Factor | Weight | SageMaker | EC2 + Batch | EKS + GPUs |
|--------|--------|-----------|-------------|------------|
| **ML Features** | High | ✅ Native ML | ❌ DIY | ⚠️ Custom |
| **Cost** | Medium | ⚠️ Premium | ✅ Spot instances | ✅ Spot nodes |
| **Flexibility** | Medium | ⚠️ Framework limits | ✅ Full control | ✅ Kubernetes |
| **Management** | High | ✅ Fully managed | ⚠️ Some setup | ⚠️ K8s complexity |
| **Integration** | Medium | ✅ AWS native | ⚠️ Manual | ⚠️ Custom |

**Recommendation:** SageMaker for ML focus, EC2 + Batch for cost optimization

---

## Cost vs Performance vs Management Trade-offs

### Low Cost Optimization

#### Compute Strategy:
- **Spot Instances:** 70-90% cost reduction
- **Reserved Instances:** 1-3 year commitments
- **Lambda:** Pay-per-invocation for sporadic workloads
- **Fargate Spot:** Serverless with spot pricing

#### Storage Strategy:
- **S3 Intelligent Tiering:** Automatic cost optimization
- **S3 Glacier:** Long-term archival
- **EBS gp3:** Better price/performance than gp2
- **EFS Infrequent Access:** Rarely accessed files

#### Database Strategy:
- **DynamoDB On-Demand:** Pay-per-request
- **Aurora Serverless:** Pause when idle
- **RDS Reserved Instances:** Predictable workloads
- **Redshift Reserved Instances:** Analytics workloads

#### Example Low-Cost Stack:
```
CloudFront → ALB → Lambda → DynamoDB
                ↓
            S3 (Intelligent Tiering)
```

**Cost Benefits:**
- No always-on compute costs
- Automatic storage optimization
- Pay-per-request database
- CDN reduces origin requests

### High Performance Optimization

#### Compute Strategy:
- **Dedicated Hosts:** Consistent performance
- **C5n/M5n/R5n:** Enhanced networking
- **Placement Groups:** Low-latency communication
- **Custom AMIs:** Faster boot times

#### Storage Strategy:
- **EBS Provisioned IOPS:** Guaranteed IOPS
- **EBS io2:** Higher IOPS per volume
- **Instance Store:** Temporary high-performance storage
- **EFS Max I/O:** Higher levels of aggregate throughput

#### Database Strategy:
- **Aurora:** 5x MySQL, 3x PostgreSQL performance
- **DynamoDB:** Single-digit millisecond latency
- **ElastiCache:** Microsecond latency
- **Redshift RA3:** Managed storage, compute scaling

#### Network Strategy:
- **Enhanced Networking:** SR-IOV
- **Cluster Placement Groups:** 10 Gbps network
- **Dedicated Tenancy:** Predictable performance
- **Local Zones:** Ultra-low latency

#### Example High-Performance Stack:
```
CloudFront → NLB → EC2 (c5n.large+) → Aurora → ElastiCache
           ↓                        ↓
    Placement Groups         EBS Provisioned IOPS
```

### Low Management (Fully Managed)

#### Serverless-First Strategy:
- **Lambda:** No server management
- **Aurora Serverless:** Database auto-scaling
- **API Gateway:** Managed API layer
- **DynamoDB:** NoSQL without servers

#### Managed Services Strategy:
- **EKS Fargate:** Kubernetes without nodes
- **RDS:** Managed relational databases
- **ElastiCache:** Managed caching
- **OpenSearch Service:** Managed search

#### Example Fully Managed Stack:
```
API Gateway → Lambda → Aurora Serverless
           ↓
      DynamoDB → ElastiCache
```

**Management Benefits:**
- No OS patching
- Automatic backups
- Built-in monitoring
- Auto-scaling

### Hybrid Scenarios

#### When to Mix Managed and Self-Managed:

1. **Cost-Performance Balance:**
   ```
   ALB → ECS (Fargate + EC2) → RDS
   ```
   - Fargate for variable workloads
   - EC2 for predictable workloads
   - Managed database

2. **Compliance Requirements:**
   ```
   NLB → EC2 (dedicated) → RDS (encrypted)
   ```
   - Dedicated instances for compliance
   - Managed database with encryption
   - Custom security configurations

3. **Migration Strategy:**
   ```
   ALB → EC2 (lift-and-shift) → Aurora (modernized)
   ```
   - Keep application on EC2 initially
   - Modernize database first
   - Gradual containerization

---

## Quick Reference Cards

### One-Liner Decision Rules

#### Performance-Critical Decisions:
- **Sub-second response + complex queries** = `ElastiCache + RDS Read Replicas`
- **Ultra-low latency networking** = `Placement Groups + Enhanced Networking + NLB`
- **High IOPS database** = `RDS + Provisioned IOPS + Multi-AZ`
- **Microsecond caching** = `ElastiCache Redis Cluster Mode`

#### Cost-Optimization Decisions:
- **Variable traffic + cost optimization** = `Lambda + DynamoDB + S3`
- **Predictable workload + cost control** = `Reserved Instances + S3 IA + DynamoDB Provisioned`
- **Batch processing + cost focus** = `Spot Fleet + S3 + SQS`
- **Archive + compliance** = `S3 Glacier + Vault Lock + Cross-Region Replication`

#### Scalability Decisions:
- **Massive scale + simple data** = `DynamoDB + Global Tables + DAX`
- **Auto-scaling containers** = `EKS Fargate + HPA + VPA`
- **Global content delivery** = `CloudFront + Route 53 + Multi-Region S3`
- **Event-driven scaling** = `Lambda + SQS + Auto Scaling`

#### Integration Decisions:
- **Enterprise integration + compliance** = `VPC + Direct Connect + KMS + CloudTrail`
- **Microservices + service mesh** = `EKS + ALB + App Mesh + X-Ray`
- **Data lake + analytics** = `S3 + Glue + Athena + Lake Formation`
- **Real-time + batch analytics** = `Kinesis + Lambda + Redshift + QuickSight`

#### Security Decisions:
- **Zero-trust network** = `VPC + Security Groups + NACLs + WAF + Shield`
- **Secrets management** = `Secrets Manager + Parameter Store + KMS + IAM`
- **Audit + compliance** = `CloudTrail + Config + GuardDuty + Security Hub`
- **Identity federation** = `Cognito + SAML + Active Directory + IAM Roles`

#### Development & DevOps Decisions:
- **CI/CD pipeline** = `CodeCommit + CodeBuild + CodeDeploy + CodePipeline`
- **Infrastructure as Code** = `CloudFormation + Systems Manager + Config`
- **Monitoring + observability** = `CloudWatch + X-Ray + Systems Manager + EventBridge`
- **Container deployment** = `ECR + ECS/EKS + CodeDeploy + ALB`

### Quick Service Combinations by Use Case

#### Startup/Small Business:
```
Lightsail + RDS + S3 + CloudFront + Route 53
```
- Simple, predictable pricing
- Managed services
- Global reach
- Easy to start

#### Enterprise Web Application:
```
CloudFront + WAF + ALB + ECS + RDS + ElastiCache + S3
```
- Security layers
- High availability
- Performance optimization
- Scalable architecture

#### Data-Driven Startup:
```
API Gateway + Lambda + DynamoDB + Kinesis + S3 + Athena + QuickSight
```
- Serverless scaling
- Real-time + batch analytics
- Pay-per-use
- Data insights

#### IoT Platform:
```
IoT Core + Kinesis + Lambda + DynamoDB + S3 + Timestream + QuickSight
```
- Device management
- Real-time processing
- Time-series storage
- Analytics dashboard

#### Mobile Backend:
```
Cognito + API Gateway + Lambda + DynamoDB + S3 + CloudFront + SNS
```
- User authentication
- Serverless backend
- File storage
- Push notifications

#### Machine Learning Platform:
```
S3 + SageMaker + Lambda + Step Functions + ECR + Batch + Redshift
```
- Data storage
- ML training/inference
- Workflow orchestration
- Batch processing

---

## Regional & Global Architecture Decisions

### Single Region vs Multi-Region

#### Single Region Scenarios:
- **Use When:**
  - Regional compliance requirements
  - Cost optimization priority
  - Simple architecture needs
  - Low latency to specific region

- **Architecture Pattern:**
  ```
  Route 53 → Single Region (Multi-AZ)
  ```

#### Multi-Region Scenarios:
- **Use When:**
  - Global user base
  - Disaster recovery needs
  - Compliance across regions
  - High availability requirements

- **Architecture Pattern:**
  ```
  Route 53 (Geolocation) → Multiple Regions (Each Multi-AZ)
  ```

### Route 53 + CloudFront vs ALB Decision Matrix

| Requirement | Route 53 + CloudFront | ALB Only | Both Together |
|-------------|----------------------|----------|---------------|
| **Global users** | ✅ CDN + DNS routing | ❌ Single region | ✅ Best performance |
| **Static content** | ✅ Edge caching | ❌ No caching | ✅ Optimal |
| **Dynamic content** | ⚠️ Limited caching | ✅ Real-time | ✅ Smart caching |
| **Cost for global** | ✅ Reduced bandwidth | ❌ Higher costs | ⚠️ Higher but optimized |
| **DDoS protection** | ✅ AWS Shield | ⚠️ Limited | ✅ Comprehensive |
| **SSL termination** | ✅ Edge locations | ✅ Load balancer | ✅ Both layers |

**Decision Rules:**
- **Global static/media content:** CloudFront + S3
- **Regional dynamic apps:** ALB only
- **Global dynamic apps:** CloudFront + ALB
- **Multi-region failover:** Route 53 + both

### Cross-Region Replication Strategies

#### RDS Cross-Region:
```
Primary Region: RDS Multi-AZ
       ↓ (Async replication)
Secondary Region: RDS Read Replica
```

**Use Cases:**
- Disaster recovery
- Read scaling for global users
- Compliance requirements

**Considerations:**
- Replication lag
- Cross-region data transfer costs
- Manual failover process

#### S3 Cross-Region Replication:
```
Primary Bucket (Region A) → Secondary Bucket (Region B)
```

**Configuration Options:**
- **Entire bucket** or **prefix-based**
- **Storage class changes** (Standard → IA → Glacier)
- **Ownership controls**
- **Encryption changes**

#### DynamoDB Global Tables:
```
Region A: DynamoDB Table ←→ Region B: DynamoDB Table
                ↕
           Region C: DynamoDB Table
```

**Benefits:**
- Multi-master replication
- Automatic failover
- Local read/write performance
- Conflict resolution

#### Aurora Global Database:
```
Primary Region: Aurora Cluster (Write)
       ↓ (< 1 second lag)
Secondary Region: Aurora Cluster (Read-only)
```

**Features:**
- < 1 second replication lag
- Up to 5 secondary regions
- Fast failover (< 1 minute)
- Global read scaling

### Global Architecture Examples

#### Global E-commerce Platform:
```
Route 53 (Geolocation)
├── US-East: CloudFront → ALB → ECS → Aurora
├── EU-West: CloudFront → ALB → ECS → Aurora
└── AP-Southeast: CloudFront → ALB → ECS → Aurora
         ↓
    S3 Cross-Region Replication
    DynamoDB Global Tables
```

#### Global Content Platform:
```
CloudFront (Global)
├── Origin: S3 (Primary Region)
├── Secondary: S3 (Backup Region)
└── API: ALB → Lambda → DynamoDB Global Tables
```

#### Global SaaS Application:
```
Route 53 Failover
├── Primary: Region A (Full Stack)
└── Secondary: Region B (Standby)
         ↓
    RDS Cross-Region Read Replica
    S3 Cross-Region Replication
```

---

## Security & Compliance Combinations

### Network Security Layers

#### VPC + Security Groups + NACLs + WAF

**Layer 1: VPC (Network Isolation)**
```
Internet Gateway → VPC
├── Public Subnets (Web Tier)
├── Private Subnets (App Tier)
└── Database Subnets (Data Tier)
```

**Layer 2: NACLs (Subnet-level firewall)**
- Stateless rules
- Allow/deny by port, protocol, IP
- Applied to entire subnet

**Layer 3: Security Groups (Instance-level firewall)**
- Stateful rules
- Allow rules only
- Applied to ENI/instances

**Layer 4: WAF (Application-level firewall)**
- SQL injection protection
- XSS protection
- Rate limiting
- Geographic restrictions

#### Security Group Patterns:

**Web Tier Security Group:**
```
Inbound:
- HTTP (80) from 0.0.0.0/0
- HTTPS (443) from 0.0.0.0/0
- SSH (22) from Bastion SG

Outbound:
- ALL to App Tier SG
```

**App Tier Security Group:**
```
Inbound:
- App Port (8080) from Web Tier SG
- SSH (22) from Bastion SG

Outbound:
- MySQL (3306) to DB Tier SG
- HTTPS (443) to 0.0.0.0/0 (APIs)
```

**Database Tier Security Group:**
```
Inbound:
- MySQL (3306) from App Tier SG
- MySQL (3306) from Bastion SG

Outbound:
- None (or specific requirements)
```

### IAM + KMS + Secrets Manager + Parameter Store

#### IAM Strategy:
```
IAM Users/Roles → IAM Policies → AWS Resources
         ↓
    MFA + Access Keys + Temporary Credentials
```

**Best Practices:**
- **Principle of least privilege**
- **Role-based access control**
- **MFA for privileged operations**
- **Temporary credentials**
- **Cross-account roles**

#### KMS Integration:
```
Application → KMS → Encrypted Resources
├── S3 (SSE-KMS)
├── EBS (KMS encryption)
├── RDS (Encryption at rest)
└── Secrets Manager (Encrypted secrets)
```

**Key Management:**
- **Customer Managed Keys:** Full control
- **AWS Managed Keys:** AWS services
- **AWS Owned Keys:** AWS internal

#### Secrets vs Parameters:

| Use Case | Secrets Manager | Parameter Store |
|----------|----------------|----------------|
| **Passwords** | ✅ Automatic rotation | ❌ Manual management |
| **API Keys** | ✅ Encrypted by default | ⚠️ SecureString type |
| **Configuration** | ❌ Overkill | ✅ Perfect fit |
| **Cost** | ❌ $0.40/secret/month | ✅ Free tier available |
| **Integration** | ✅ RDS, Redshift | ✅ EC2, Lambda |

#### Security Architecture Example:
```
Internet → CloudFront → WAF → ALB → ECS
                             ↓
                        IAM Roles → KMS
                             ↓
                   Secrets Manager ← RDS (encrypted)
                             ↓
                   Parameter Store ← App Config
```

### Logging & Monitoring Security

#### CloudTrail + CloudWatch + Config + GuardDuty

**CloudTrail (API Auditing):**
```
AWS API Calls → CloudTrail → S3 + CloudWatch Logs
                      ↓
                 Cross-region replication
                 S3 Object Lock (compliance)
```

**CloudWatch (Monitoring):**
```
Applications → CloudWatch Metrics/Logs → Alarms → SNS
                      ↓
              Custom Dashboards
              Log Insights queries
```

**Config (Compliance):**
```
AWS Resources → Config Rules → Compliance Dashboard
                      ↓
              Automatic remediation
              SNS notifications
```

**GuardDuty (Threat Detection):**
```
VPC Flow Logs + DNS Logs + CloudTrail → GuardDuty → Security Hub
                                            ↓
                                    SNS → Lambda → Response
```

#### Security Monitoring Stack:
```
Security Hub (Central dashboard)
├── GuardDuty (Threat detection)
├── Config (Compliance)
├── CloudTrail (API audit)
├── VPC Flow Logs (Network)
└── WAF (Application attacks)
         ↓
    CloudWatch → SNS → Lambda → Automated response
```

### Compliance Patterns

#### HIPAA Compliance Pattern:
```
VPC (Dedicated tenancy) → WAF → ALB → ECS (dedicated hosts)
                               ↓
                       RDS (encrypted, dedicated)
                               ↓
                       KMS (customer managed keys)
                               ↓
                   CloudTrail → S3 (object lock)
```

**Key Requirements:**
- Dedicated hosting
- Encryption at rest/transit
- Access logging
- Data retention policies
- Business Associate Agreement

#### PCI DSS Compliance Pattern:
```
CloudFront → WAF → ALB → ECS (PCI-validated AMI)
                   ↓
           RDS (encrypted) + Secrets Manager
                   ↓
           Security Groups (restrictive)
                   ↓
           CloudTrail + Config + GuardDuty
```

**Key Requirements:**
- Network segmentation
- Encryption of cardholder data
- Access controls
- Regular security testing
- Vulnerability management

#### SOC 2 Compliance Pattern:
```
Identity Provider → Cognito → IAM Roles
                         ↓
               Multi-factor authentication
                         ↓
               Least privilege access
                         ↓
           CloudTrail + Config + Security Hub
```

**Key Requirements:**
- Security controls
- Availability controls
- Processing integrity
- Confidentiality
- Privacy

---

## Real-World Examples & Migration Pathways

### Migration Scenarios

#### On-Premises to AWS (Lift and Shift):

**Phase 1: Infrastructure Migration**
```
On-premises → AWS VM Import → EC2
                    ↓
            EBS for storage
            VPC for networking
            RDS for databases
```

**Phase 2: Modernization**
```
EC2 → Containerization → ECS/EKS
      ↓
  Auto Scaling Groups
  Application Load Balancer
  CloudWatch monitoring
```

**Phase 3: Cloud-Native**
```
Containers → Serverless (Lambda)
RDS → Aurora Serverless
File Storage → S3
Queues → SQS/SNS
```

#### Legacy Modernization Path:

**Monolith → Microservices**
```
Step 1: Monolith on EC2 + RDS
Step 2: Extract services → Lambda + API Gateway
Step 3: Event-driven → SQS/SNS + EventBridge
Step 4: Data decomposition → DynamoDB per service
```

**Database Modernization**
```
Oracle → Aurora PostgreSQL
SQL Server → Aurora MySQL
MongoDB → DocumentDB
Cassandra → DynamoDB
```

### Pricing Considerations

#### Cost Optimization Strategies:

**1. Compute Optimization:**
```
On-Demand → Reserved Instances (1-3 years)
Reserved → Spot Instances (up to 90% savings)
EC2 → Lambda (for suitable workloads)
Always-on → Auto Scaling
```

**2. Storage Optimization:**
```
S3 Standard → Intelligent Tiering
Frequent access → Infrequent Access
Archival → Glacier/Deep Archive
EBS → EFS (for shared storage)
```

**3. Database Optimization:**
```
Always-on → Aurora Serverless
Over-provisioned → Right-sizing
Single-AZ → Multi-AZ (only if needed)
Read replicas → Read scaling
```

**4. Network Optimization:**
```
Internet Gateway → VPC Endpoints
Cross-AZ → Same-AZ (where possible)
Data transfer → CloudFront
Direct Connect → VPN (for lower volume)
```

#### Cost Example Scenarios:

**Startup ($1K/month budget):**
```
Lightsail $20 + RDS t3.micro $15 + S3 $5 + CloudFront $10
Total: ~$50/month (room for growth)
```

**Small Business ($5K/month budget):**
```
EC2 t3.medium Reserved $25 + ALB $18 + RDS db.t3.small $35
+ S3 $50 + CloudFront $30
Total: ~$158/month
```

**Enterprise ($50K/month budget):**
```
EKS cluster $146 + EC2 fleet $2000 + Aurora $800
+ S3 $500 + CloudFront $200 + Data transfer $300
Total: ~$4000/month
```

### Best Practices Summary

#### Architecture Principles:
1. **Design for failure** - Multi-AZ, auto-recovery
2. **Decouple components** - SQS, SNS, EventBridge
3. **Think parallel** - Async processing, caching
4. **Security by design** - Defense in depth
5. **Monitor everything** - CloudWatch, X-Ray

#### Service Selection Framework:
1. **Start simple** - Managed services first
2. **Optimize later** - Measure before optimizing
3. **Cost vs performance** - Right-size regularly
4. **Vendor lock-in vs features** - Strategic decision
5. **Skills vs automation** - Team capabilities matter

#### Common Anti-Patterns to Avoid:
- **Over-engineering** early stages
- **Ignoring costs** until too late
- **Single points of failure**
- **Not using managed services**
- **Premature optimization**
- **Insufficient monitoring**
- **Poor security practices**

---

## Conclusion

This cheatsheet provides a comprehensive guide for AWS service selection and combination strategies. Remember that architecture decisions should always consider:

1. **Current requirements** vs future needs
2. **Team expertise** and operational capabilities
3. **Budget constraints** and cost optimization opportunities
4. **Performance requirements** and user experience
5. **Security and compliance** mandates
6. **Scalability and reliability** needs

Start with managed services, measure performance and costs, then optimize based on actual usage patterns. AWS provides many paths to the same destination - choose the one that best fits your specific context and constraints.

**Key Takeaway:** There's no single "best" architecture - only the best architecture for your specific requirements, constraints, and organizational context.