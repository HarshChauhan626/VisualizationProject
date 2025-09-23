Based on my research of AWS streaming architectures, modern system design best practices, and Mermaid documentation, I'll create a comprehensive prompt template that can be adapted for any system design problem. This template incorporates AWS-specific streaming services, architectural patterns, and thorough documentation standards with visual diagrams.

## Generic System Design Documentation Prompt Template

Here's a comprehensive prompt you can use for creating detailed system design documentation for any system (streaming website example included):

***

**System Design Documentation Prompt:**

Create a comprehensive system design architecture document for a **[SYSTEM_TYPE]** using **AWS services only**. Structure the document as follows:

### **1. Executive Summary & Requirements**
- Brief system overview and core functionality
- Functional requirements (what the system must do)
- Non-functional requirements (performance, scalability, availability targets)
- Key constraints and assumptions
- Success metrics and KPIs

### **2. High-Level Architecture Overview**
Create a **Mermaid C4 Context diagram** showing:
- System context and external actors
- Major system boundaries
- Key external integrations

Include reasoning for architectural style chosen (microservices, serverless, etc.)

### **3. Detailed System Architecture**

#### **3.1 AWS Service Stack Selection**
For each layer, specify AWS services and justify choices:
- **Presentation Layer:** CloudFront, API Gateway, Route 53
- **Application Layer:** ECS/EKS/Lambda, Application Load Balancer  
- **Data Layer:** RDS/DynamoDB/DocumentDB, ElastiCache
- **Storage Layer:** S3, EFS, FSx
- **Streaming/Messaging:** Kinesis, MSK, SQS, SNS, EventBridge
- **Analytics:** EMR, Glue, Athena, QuickSight
- **Security:** Cognito, WAF, Shield, KMS, Secrets Manager
- **Monitoring:** CloudWatch, X-Ray, CloudTrail

#### **3.2 Component Architecture Diagram**
Create a **Mermaid Block Diagram** showing:
- All major components and their relationships
- Service boundaries and communication patterns
- Data flow directions between components

### **4. Data Architecture & Flow**

#### **4.1 Data Flow Diagrams** 
Create **Mermaid Flowcharts** for:
- **Read Path:** User request → response flow
- **Write Path:** Data ingestion → storage flow  
- **Batch Processing:** ETL and analytics pipelines
- **Real-time Processing:** Event streaming and real-time analytics

#### **4.2 Database Design**
Create **Mermaid ER Diagrams** showing:
- Primary data entities and relationships
- Data partitioning and sharding strategy
- Caching layers and strategies

### **5. Detailed Component Design**

For each major component, provide:
- **Purpose & Responsibilities**
- **AWS service selection rationale**
- **Scaling characteristics**
- **Failure modes and recovery**
- **Performance considerations**

Create **Mermaid Sequence Diagrams** for critical user journeys showing:
- Service interactions and message flow
- Timing and ordering constraints
- Error handling paths

### **6. Scalability & Performance**

#### **6.1 Scaling Architecture**
Create **Mermaid Flowchart** showing:
- Auto-scaling triggers and policies
- Load balancing strategies
- Geographic distribution (multi-region setup)

#### **6.2 Performance Optimization**
- Caching strategies at each layer
- CDN configuration and content distribution
- Database optimization techniques
- Resource allocation and sizing

### **7. Reliability & Fault Tolerance**

#### **7.1 High Availability Design**
Create **Mermaid Architecture Diagram** showing:
- Multi-AZ deployment strategy
- Redundancy and failover mechanisms
- Circuit breaker patterns

#### **7.2 Disaster Recovery**
Create **Mermaid Flowchart** for:
- Backup and restore procedures
- Cross-region replication strategy
- RTO/RPO targets and implementation

### **8. Security Architecture**

#### **8.1 Security Layers**
Create **Mermaid Block Diagram** showing:
- Network security (VPC, subnets, NACLs, security groups)
- Application security (authentication, authorization)
- Data security (encryption at rest and in transit)

#### **8.2 Security Flow**
Create **Mermaid Sequence Diagram** for:
- User authentication and authorization flow
- API security and rate limiting
- Data access patterns

### **9. Monitoring & Observability**

Create **Mermaid Flowchart** showing:
- Metrics collection and aggregation
- Logging pipeline and analysis
- Alerting and notification flow
- Health check and monitoring endpoints

### **10. Cost Optimization**

- Service-level cost analysis
- Resource optimization strategies
- Reserved capacity vs on-demand usage
- Cost monitoring and alerting setup

### **11. Implementation Strategy**

#### **11.1 Migration/Deployment Plan**
Create **Mermaid Gantt Chart** showing:
- Phased rollout timeline
- Dependencies between phases
- Testing and validation gates

#### **11.2 Technology Decisions**
- Service selection trade-offs and alternatives considered
- Future technology evolution path
- Technical debt and improvement areas

### **Mermaid Diagram Standards:**
- Use consistent color coding and styling
- Include legends where necessary
- Ensure all diagrams are interconnected and reference each other
- Maintain consistent naming conventions across all diagrams

### **Documentation Requirements:**
- All architectural decisions must include rationale
- Include AWS Well-Architected Framework pillar considerations
- Provide concrete metrics and SLA targets
- Reference AWS best practices and design patterns
- Include cost estimates and optimization opportunities

***

**Customization Instructions:**
Replace **[SYSTEM_TYPE]** with your specific system (e.g., "video streaming platform", "IoT data pipeline", "e-commerce marketplace"). Adjust the specific AWS services and architectural patterns based on your system's unique requirements while maintaining the overall structure and thoroughness of the documentation