# Top 30 Most Asked System Design Problems

This document contains the most frequently asked system design interview questions and problems that candidates encounter at major tech companies.

## 1. Design a URL Shortener (like bit.ly, TinyURL)
Design a service that takes long URLs and returns shorter URLs, with analytics and custom aliases.

## 2. Design a Social Media Feed (like Facebook, Twitter)
Build a system to generate personalized news feeds for users with posts from friends and pages they follow.

## 3. Design a Chat System (like WhatsApp, Slack)
Create a real-time messaging system supporting one-on-one and group conversations with message delivery guarantees.

## 4. Design a Video Streaming Service (like YouTube, Netflix)
Build a platform for uploading, storing, processing, and streaming videos to millions of users globally.

## 5. Design a Web Crawler (like Google's crawler)
Create a system to systematically browse and index web pages for search engines.

## 6. Design a Search Engine (like Google)
Build a system to crawl, index, and search billions of web pages with relevance ranking.

## 7. Design a Ride-Sharing Service (like Uber, Lyft)
Create a platform matching riders with drivers, handling real-time location tracking and pricing.

## 8. Design a Notification System
Build a system to send push notifications, emails, and SMS to millions of users reliably.

## 9. Design a Distributed Cache (like Redis, Memcached)
Create a high-performance, distributed caching system with data consistency and fault tolerance.

## 10. Design a Key-Value Store (like DynamoDB, Cassandra)
Build a distributed NoSQL database that can handle massive scale with high availability.

## 11. Design a Content Delivery Network (CDN)
Create a geographically distributed network of servers to deliver content with low latency.

## 12. Design a Load Balancer
Build a system to distribute incoming requests across multiple servers efficiently.

## 13. Design a Rate Limiter
Create a system to control the rate of requests to prevent abuse and ensure fair usage.

## 14. Design an Online Marketplace (like Amazon, eBay)
Build a platform for buyers and sellers with product catalog, payments, and order management.

## 15. Design a Food Delivery System (like DoorDash, Uber Eats)
Create a platform connecting customers, restaurants, and delivery drivers with real-time tracking.

## 16. Design a Parking Lot System
Build a system to manage parking spaces, reservations, and payments for a multi-level parking garage.

## 17. Design a Distributed File System (like Google File System, HDFS)
Create a system to store and retrieve large files across multiple machines with fault tolerance.

## 18. Design a Logging System
Build a centralized logging system to collect, store, and analyze logs from distributed applications.

## 19. Design a Metrics and Analytics System
Create a system to collect, process, and visualize real-time metrics and analytics data.

## 20. Design a Recommendation System
Build a system to recommend products, content, or connections based on user behavior and preferences.

## 21. Design a Payment System
Create a secure and reliable payment processing system handling transactions, fraud detection, and compliance.

## 22. Design a Booking System (like Airbnb, hotel booking)
Build a platform for property listings, search, booking, and reservation management.

## 23. Design a Distributed Message Queue (like Apache Kafka, RabbitMQ)
Create a system for reliable message passing between distributed applications.

## 24. Design a Stock Trading System
Build a high-frequency trading platform with order matching, portfolio management, and real-time data.

## 25. Design a Collaborative Document Editor (like Google Docs)
Create a system for real-time collaborative editing with conflict resolution and version control.

## 26. Design a Social Network (like Facebook, LinkedIn)
Build a platform for user profiles, connections, posts, and social interactions at scale.

## 27. Design a Gaming Leaderboard
Create a system to track and display real-time rankings for millions of players across multiple games.

## 28. Design a Distributed Lock Service
Build a system to coordinate access to shared resources in a distributed environment.

## 29. Design an Email Service (like Gmail, Outlook)
Create a system for sending, receiving, storing, and searching emails with spam filtering.

## 30. Design a Code Deployment System
Build a system for continuous integration and deployment of code across multiple environments.

---

## Common System Design Concepts to Master

- **Scalability**: Horizontal vs Vertical scaling
- **Reliability**: Fault tolerance, redundancy, backup strategies
- **Availability**: Uptime, disaster recovery, geographic distribution
- **Consistency**: ACID properties, CAP theorem, eventual consistency
- **Performance**: Latency, throughput, caching strategies
- **Security**: Authentication, authorization, encryption, data privacy
- **Monitoring**: Logging, metrics, alerting, observability
- **Data Storage**: SQL vs NoSQL, sharding, replication
- **Communication**: APIs, message queues, pub-sub patterns
- **Architecture Patterns**: Microservices, event-driven, serverless

## Tips for System Design Interviews

1. **Clarify Requirements**: Ask questions about scale, features, and constraints
2. **Estimate Scale**: Calculate users, requests per second, storage needs
3. **High-Level Design**: Start with basic components and data flow
4. **Deep Dive**: Focus on critical components and trade-offs
5. **Scale the Design**: Address bottlenecks and scaling challenges
6. **Consider Edge Cases**: Handle failures, edge cases, and monitoring
