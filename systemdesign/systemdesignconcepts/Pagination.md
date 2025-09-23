# Pagination: Efficient Data Chunking and Navigation

## 🎯 What is Pagination?

Pagination is like reading a book page by page instead of trying to read the entire book at once. Rather than loading massive datasets all at once, pagination breaks data into manageable chunks (pages), allowing users to navigate through large collections efficiently while maintaining excellent performance and user experience.

## 🏗️ Core Concepts

### The Book Reading Analogy
- **Page-by-Page**: Read one page at a time for better comprehension
- **Navigation**: Easy movement between pages with bookmarks
- **Memory Efficiency**: Only keep current page in active memory
- **Quick Access**: Jump to specific pages or chapters
- **Progress Tracking**: Know your position in the overall content

### Why Pagination Matters
1. **Performance**: Faster loading times with smaller data sets
2. **Memory Efficiency**: Reduced memory consumption on client and server
3. **User Experience**: Manageable content chunks for better usability
4. **Network Optimization**: Smaller payloads and reduced bandwidth usage
5. **Scalability**: Handle millions of records without overwhelming systems

## 📄 Pagination Implementation

```python
import time
import math
from typing import Dict, List, Optional, Any, Tuple, Generic, TypeVar
from dataclasses import dataclass, field
from abc import ABC, abstractmethod
from enum import Enum

T = TypeVar('T')

class PaginationStrategy(Enum):
    OFFSET_LIMIT = "offset_limit"
    CURSOR_BASED = "cursor_based"
    KEYSET = "keyset"
    TIME_BASED = "time_based"

@dataclass
class PageInfo:
    page_number: int
    page_size: int
    total_items: int
    total_pages: int
    has_next: bool
    has_previous: bool
    start_cursor: Optional[str] = None
    end_cursor: Optional[str] = None
    
    @property
    def is_first_page(self) -> bool:
        return self.page_number == 1
    
    @property
    def is_last_page(self) -> bool:
        return self.page_number == self.total_pages

@dataclass
class PaginatedResult(Generic[T]):
    data: List[T]
    page_info: PageInfo
    metadata: Dict[str, Any] = field(default_factory=dict)

class PaginationProvider(ABC, Generic[T]):
    """Abstract pagination provider"""
    
    @abstractmethod
    def get_page(self, page: int, size: int, **kwargs) -> PaginatedResult[T]:
        """Get specific page of data"""
        pass
    
    @abstractmethod
    def get_total_count(self) -> int:
        """Get total number of items"""
        pass

class OffsetLimitPagination(PaginationProvider[T]):
    """Traditional offset/limit pagination"""
    
    def __init__(self, data_source: List[T]):
        self.data_source = data_source
        self.total_count = len(data_source)
    
    def get_page(self, page: int, size: int, **kwargs) -> PaginatedResult[T]:
        if page < 1:
            page = 1
        
        offset = (page - 1) * size
        limit = size
        
        # Get page data
        page_data = self.data_source[offset:offset + limit]
        
        # Calculate pagination info
        total_pages = math.ceil(self.total_count / size) if size > 0 else 1
        
        page_info = PageInfo(
            page_number=page,
            page_size=size,
            total_items=self.total_count,
            total_pages=total_pages,
            has_next=page < total_pages,
            has_previous=page > 1
        )
        
        return PaginatedResult(
            data=page_data,
            page_info=page_info,
            metadata={'strategy': 'offset_limit', 'offset': offset}
        )
    
    def get_total_count(self) -> int:
        return self.total_count

class CursorBasedPagination(PaginationProvider[T]):
    """Cursor-based pagination for stable pagination"""
    
    def __init__(self, data_source: List[T], key_func: callable):
        self.data_source = data_source
        self.key_func = key_func  # Function to extract cursor key from item
        self.total_count = len(data_source)
    
    def get_page(self, page: int = 1, size: int = 10, 
                 after_cursor: str = None, before_cursor: str = None) -> PaginatedResult[T]:
        
        # Find starting position
        start_index = 0
        if after_cursor:
            start_index = self._find_cursor_position(after_cursor) + 1
        elif before_cursor:
            end_index = self._find_cursor_position(before_cursor)
            start_index = max(0, end_index - size)
        
        # Get page data
        end_index = min(start_index + size, len(self.data_source))
        page_data = self.data_source[start_index:end_index]
        
        # Generate cursors
        start_cursor = self.key_func(page_data[0]) if page_data else None
        end_cursor = self.key_func(page_data[-1]) if page_data else None
        
        # Calculate page info
        page_info = PageInfo(
            page_number=page,
            page_size=size,
            total_items=self.total_count,
            total_pages=math.ceil(self.total_count / size),
            has_next=end_index < len(self.data_source),
            has_previous=start_index > 0,
            start_cursor=start_cursor,
            end_cursor=end_cursor
        )
        
        return PaginatedResult(
            data=page_data,
            page_info=page_info,
            metadata={'strategy': 'cursor_based', 'start_index': start_index}
        )
    
    def _find_cursor_position(self, cursor: str) -> int:
        """Find position of cursor in data"""
        for i, item in enumerate(self.data_source):
            if self.key_func(item) == cursor:
                return i
        return -1
    
    def get_total_count(self) -> int:
        return self.total_count

class DatabasePagination(PaginationProvider[Dict[str, Any]]):
    """Database pagination simulation"""
    
    def __init__(self, table_name: str, connection=None):
        self.table_name = table_name
        self.connection = connection or MockDatabase()
        
    def get_page(self, page: int, size: int, 
                 order_by: str = 'id', filters: Dict[str, Any] = None) -> PaginatedResult[Dict[str, Any]]:
        
        filters = filters or {}
        offset = (page - 1) * size
        
        # Simulate database query
        query_result = self.connection.query(
            table=self.table_name,
            limit=size,
            offset=offset,
            order_by=order_by,
            filters=filters
        )
        
        total_count = self.connection.count(self.table_name, filters)
        total_pages = math.ceil(total_count / size) if size > 0 else 1
        
        page_info = PageInfo(
            page_number=page,
            page_size=size,
            total_items=total_count,
            total_pages=total_pages,
            has_next=page < total_pages,
            has_previous=page > 1
        )
        
        return PaginatedResult(
            data=query_result,
            page_info=page_info,
            metadata={'strategy': 'database', 'order_by': order_by, 'filters': filters}
        )
    
    def get_total_count(self) -> int:
        return self.connection.count(self.table_name, {})

class MockDatabase:
    """Mock database for demonstration"""
    
    def __init__(self):
        # Generate sample data
        self.tables = {
            'users': [
                {'id': i, 'name': f'User {i}', 'email': f'user{i}@example.com', 'active': i % 2 == 0}
                for i in range(1, 1001)
            ],
            'orders': [
                {'id': i, 'user_id': (i % 100) + 1, 'amount': i * 10.5, 'status': 'completed'}
                for i in range(1, 5001)
            ]
        }
    
    def query(self, table: str, limit: int, offset: int, 
              order_by: str = 'id', filters: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        
        if table not in self.tables:
            return []
        
        data = self.tables[table].copy()
        
        # Apply filters
        if filters:
            for key, value in filters.items():
                data = [item for item in data if item.get(key) == value]
        
        # Sort by order_by field
        if order_by in data[0] if data else {}:
            data.sort(key=lambda x: x[order_by])
        
        # Apply pagination
        return data[offset:offset + limit]
    
    def count(self, table: str, filters: Dict[str, Any] = None) -> int:
        if table not in self.tables:
            return 0
        
        data = self.tables[table]
        
        if filters:
            filtered_count = 0
            for item in data:
                if all(item.get(key) == value for key, value in filters.items()):
                    filtered_count += 1
            return filtered_count
        
        return len(data)

class PaginationOptimizer:
    """Optimize pagination strategies based on usage patterns"""
    
    def __init__(self):
        self.access_patterns: Dict[str, List[int]] = {}
        self.performance_metrics: Dict[str, List[float]] = {}
    
    def record_access(self, session_id: str, page: int, load_time: float):
        """Record page access for pattern analysis"""
        if session_id not in self.access_patterns:
            self.access_patterns[session_id] = []
            self.performance_metrics[session_id] = []
        
        self.access_patterns[session_id].append(page)
        self.performance_metrics[session_id].append(load_time)
    
    def analyze_patterns(self) -> Dict[str, Any]:
        """Analyze access patterns"""
        if not self.access_patterns:
            return {}
        
        total_sessions = len(self.access_patterns)
        sequential_sessions = 0
        random_sessions = 0
        first_page_only = 0
        
        for session_id, pages in self.access_patterns.items():
            if len(pages) == 1:
                first_page_only += 1
            elif self._is_sequential(pages):
                sequential_sessions += 1
            else:
                random_sessions += 1
        
        # Calculate average performance
        all_load_times = []
        for times in self.performance_metrics.values():
            all_load_times.extend(times)
        
        avg_load_time = sum(all_load_times) / len(all_load_times) if all_load_times else 0
        
        return {
            'total_sessions': total_sessions,
            'sequential_access_rate': sequential_sessions / total_sessions,
            'random_access_rate': random_sessions / total_sessions,
            'first_page_only_rate': first_page_only / total_sessions,
            'average_load_time': avg_load_time,
            'recommended_strategy': self._recommend_strategy(sequential_sessions, random_sessions, first_page_only, total_sessions)
        }
    
    def _is_sequential(self, pages: List[int]) -> bool:
        """Check if page access is sequential"""
        if len(pages) < 2:
            return False
        
        sequential_count = 0
        for i in range(1, len(pages)):
            if pages[i] == pages[i-1] + 1:
                sequential_count += 1
        
        return sequential_count / (len(pages) - 1) > 0.7  # 70% sequential
    
    def _recommend_strategy(self, sequential: int, random: int, first_only: int, total: int) -> str:
        """Recommend pagination strategy based on patterns"""
        if first_only / total > 0.8:
            return "small_page_size"  # Most users only see first page
        elif sequential / total > 0.6:
            return "prefetch_next_page"  # Sequential access patterns
        elif random / total > 0.6:
            return "cursor_based"  # Random access, need stable pagination
        else:
            return "offset_limit"  # Standard pagination

# Web API pagination helper
class WebAPIPagination:
    """Helper for web API pagination"""
    
    def __init__(self, provider: PaginationProvider[T]):
        self.provider = provider
    
    def paginate(self, request_params: Dict[str, Any]) -> Dict[str, Any]:
        """Create pagination response for web API"""
        
        # Extract pagination parameters
        page = int(request_params.get('page', 1))
        size = int(request_params.get('size', 20))
        size = min(size, 100)  # Limit maximum page size
        
        # Get paginated result
        result = self.provider.get_page(page, size, **request_params)
        
        # Format for API response
        return {
            'data': result.data,
            'pagination': {
                'page': result.page_info.page_number,
                'size': result.page_info.page_size,
                'total_items': result.page_info.total_items,
                'total_pages': result.page_info.total_pages,
                'has_next': result.page_info.has_next,
                'has_previous': result.page_info.has_previous,
                'links': self._generate_links(result.page_info, request_params)
            },
            'metadata': result.metadata
        }
    
    def _generate_links(self, page_info: PageInfo, params: Dict[str, Any]) -> Dict[str, str]:
        """Generate navigation links"""
        base_params = {k: v for k, v in params.items() if k not in ['page']}
        
        links = {}
        
        if page_info.has_previous:
            links['previous'] = self._build_url({**base_params, 'page': page_info.page_number - 1})
        
        if page_info.has_next:
            links['next'] = self._build_url({**base_params, 'page': page_info.page_number + 1})
        
        links['first'] = self._build_url({**base_params, 'page': 1})
        links['last'] = self._build_url({**base_params, 'page': page_info.total_pages})
        
        return links
    
    def _build_url(self, params: Dict[str, Any]) -> str:
        """Build URL from parameters"""
        param_strings = [f"{k}={v}" for k, v in params.items()]
        return f"/api/data?{'&'.join(param_strings)}"

# Example usage and testing
print("=== Pagination Demo ===")

# Generate sample data
sample_users = [
    {'id': i, 'name': f'User {i}', 'email': f'user{i}@example.com', 'created_at': f'2023-01-{(i%28)+1:02d}'}
    for i in range(1, 101)
]

# Test offset/limit pagination
print("\n--- Offset/Limit Pagination ---")
offset_paginator = OffsetLimitPagination(sample_users)

for page in range(1, 4):
    result = offset_paginator.get_page(page, 10)
    print(f"Page {page}: {len(result.data)} items")
    print(f"  Items {result.page_info.page_number * result.page_info.page_size - result.page_info.page_size + 1}-"
          f"{min(result.page_info.page_number * result.page_info.page_size, result.page_info.total_items)} "
          f"of {result.page_info.total_items}")
    print(f"  Has next: {result.page_info.has_next}, Has previous: {result.page_info.has_previous}")

# Test cursor-based pagination
print("\n--- Cursor-Based Pagination ---")
cursor_paginator = CursorBasedPagination(sample_users, lambda x: str(x['id']))

result = cursor_paginator.get_page(size=5)
print(f"First page: {len(result.data)} items")
print(f"  Start cursor: {result.page_info.start_cursor}, End cursor: {result.page_info.end_cursor}")

# Get next page using cursor
next_result = cursor_paginator.get_page(size=5, after_cursor=result.page_info.end_cursor)
print(f"Next page: {len(next_result.data)} items")
print(f"  Start cursor: {next_result.page_info.start_cursor}, End cursor: {next_result.page_info.end_cursor}")

# Test database pagination
print("\n--- Database Pagination ---")
db_paginator = DatabasePagination('users')

result = db_paginator.get_page(1, 15, order_by='id')
print(f"Database page 1: {len(result.data)} users")
print(f"  Total users: {result.page_info.total_items}")
print(f"  Sample user: {result.data[0] if result.data else 'None'}")

# Test with filters
filtered_result = db_paginator.get_page(1, 10, filters={'active': True})
print(f"Filtered page: {len(filtered_result.data)} active users")

# Test Web API pagination
print("\n--- Web API Pagination ---")
api_paginator = WebAPIPagination(offset_paginator)

request_params = {'page': 2, 'size': 8}
api_response = api_paginator.paginate(request_params)

print(f"API Response:")
print(f"  Data items: {len(api_response['data'])}")
print(f"  Pagination info: {api_response['pagination']}")
print(f"  Navigation links: {api_response['pagination']['links']}")

# Test pagination optimizer
print("\n--- Pagination Optimization ---")
optimizer = PaginationOptimizer()

# Simulate different user sessions
sessions = [
    ('session1', [1, 2, 3, 4, 5]),  # Sequential
    ('session2', [1]),               # First page only
    ('session3', [1, 5, 2, 8]),     # Random access
    ('session4', [1, 2, 3]),        # Sequential
    ('session5', [1]),               # First page only
]

for session_id, pages in sessions:
    for page in pages:
        load_time = 0.1 + (page * 0.01)  # Simulate varying load times
        optimizer.record_access(session_id, page, load_time)

analysis = optimizer.analyze_patterns()
print("Access pattern analysis:")
print(f"  Sequential access rate: {analysis['sequential_access_rate']:.2%}")
print(f"  Random access rate: {analysis['random_access_rate']:.2%}")
print(f"  First page only rate: {analysis['first_page_only_rate']:.2%}")
print(f"  Average load time: {analysis['average_load_time']:.3f}s")
print(f"  Recommended strategy: {analysis['recommended_strategy']}")

# Performance comparison
print("\n--- Performance Comparison ---")

large_dataset = list(range(1, 10001))  # 10,000 items
strategies = [
    ('Offset/Limit', OffsetLimitPagination(large_dataset)),
    ('Cursor-Based', CursorBasedPagination(large_dataset, lambda x: str(x)))
]

for strategy_name, paginator in strategies:
    start_time = time.time()
    
    # Simulate accessing multiple pages
    for page in [1, 50, 100, 500]:
        result = paginator.get_page(page, 20)
    
    total_time = time.time() - start_time
    print(f"{strategy_name}: {total_time:.4f}s for 4 page requests")

print("\n--- Pagination Demo Completed ---")
```

## 📚 Conclusion

Pagination is fundamental for handling large datasets efficiently in modern applications. From traditional offset/limit approaches to sophisticated cursor-based strategies, pagination enables systems to provide responsive user experiences while managing resources effectively.

**Key Takeaways:**

1. **Choose Right Strategy**: Match pagination approach to access patterns and data characteristics
2. **Optimize Performance**: Consider database indexes and query optimization for large datasets
3. **Provide Navigation**: Include clear navigation controls and progress indicators
4. **Handle Edge Cases**: Manage empty results, invalid pages, and concurrent data changes
5. **Monitor Usage**: Track access patterns to optimize pagination strategies

The future of pagination includes AI-powered page size optimization, predictive prefetching, and real-time adaptive strategies. Whether building web applications, APIs, or mobile apps, implementing effective pagination is essential for scalable, user-friendly systems that can handle massive datasets efficiently.
