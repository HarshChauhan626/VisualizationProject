# Lazy Loading: On-Demand Resource Loading

## 🎯 What is Lazy Loading?

Lazy loading is like reading a book chapter by chapter instead of trying to memorize the entire book at once. Rather than loading all data upfront, lazy loading defers the loading of resources until they're actually needed. This approach dramatically improves initial load times and reduces memory consumption by only fetching what's currently required.

## 🏗️ Core Concepts

### The Chapter-by-Chapter Reading Analogy
- **On-Demand Access**: Only load the chapter you're currently reading
- **Memory Efficiency**: Don't keep entire book in memory simultaneously
- **Fast Start**: Begin reading immediately without waiting for full book download
- **Progressive Loading**: Load additional chapters as needed
- **Smart Caching**: Keep recently read chapters readily available

### Why Lazy Loading Matters
1. **Improved Performance**: Faster initial load times and reduced bandwidth usage
2. **Memory Efficiency**: Lower memory footprint by loading only what's needed
3. **Better User Experience**: Users can interact with content immediately
4. **Cost Optimization**: Reduce unnecessary data transfer and processing
5. **Scalability**: Handle large datasets without overwhelming system resources

## 🚀 Lazy Loading Implementation

```python
import time
import threading
import weakref
from typing import Dict, List, Optional, Any, Callable, TypeVar, Generic
from dataclasses import dataclass, field
from abc import ABC, abstractmethod
import asyncio
from collections import defaultdict

T = TypeVar('T')

class LazyValue(Generic[T]):
    """Lazy-loaded value container"""
    
    def __init__(self, loader: Callable[[], T], cache_ttl: Optional[float] = None):
        self.loader = loader
        self.cache_ttl = cache_ttl
        self._value: Optional[T] = None
        self._loaded = False
        self._loading = False
        self._load_time: Optional[float] = None
        self._lock = threading.RLock()
        
    @property
    def value(self) -> T:
        """Get the lazy-loaded value"""
        with self._lock:
            if not self._loaded or self._is_expired():
                if self._loading:
                    # Wait for ongoing loading
                    while self._loading:
                        time.sleep(0.01)
                    if self._loaded and not self._is_expired():
                        return self._value
                
                self._loading = True
                try:
                    self._value = self.loader()
                    self._loaded = True
                    self._load_time = time.time()
                finally:
                    self._loading = False
            
            return self._value
    
    def _is_expired(self) -> bool:
        """Check if cached value has expired"""
        if self.cache_ttl is None or self._load_time is None:
            return False
        return time.time() - self._load_time > self.cache_ttl
    
    def is_loaded(self) -> bool:
        """Check if value has been loaded"""
        return self._loaded and not self._is_expired()
    
    def invalidate(self):
        """Invalidate cached value"""
        with self._lock:
            self._loaded = False
            self._value = None
            self._load_time = None

class LazyList(Generic[T]):
    """Lazy-loaded list with pagination support"""
    
    def __init__(self, loader: Callable[[int, int], List[T]], page_size: int = 100):
        self.loader = loader
        self.page_size = page_size
        self._pages: Dict[int, List[T]] = {}
        self._loading_pages: set = set()
        self._total_size: Optional[int] = None
        self._lock = threading.RLock()
    
    def __getitem__(self, index: int) -> T:
        """Get item at index with lazy loading"""
        if index < 0:
            raise IndexError("Negative indices not supported in lazy list")
        
        page_num = index // self.page_size
        page_index = index % self.page_size
        
        # Load page if not cached
        if page_num not in self._pages:
            self._load_page(page_num)
        
        page = self._pages[page_num]
        
        if page_index >= len(page):
            raise IndexError("Index out of range")
        
        return page[page_index]
    
    def __len__(self) -> int:
        """Get total length (may trigger loading of first page)"""
        if self._total_size is None:
            # Load first page to determine size
            self._load_page(0)
        return self._total_size or 0
    
    def _load_page(self, page_num: int):
        """Load specific page"""
        with self._lock:
            if page_num in self._pages or page_num in self._loading_pages:
                return
            
            self._loading_pages.add(page_num)
            
            try:
                start_index = page_num * self.page_size
                page_data = self.loader(start_index, self.page_size)
                
                self._pages[page_num] = page_data
                
                # Update total size estimate
                if self._total_size is None:
                    if len(page_data) < self.page_size:
                        # This is the last page
                        self._total_size = start_index + len(page_data)
                    else:
                        # Estimate based on first page
                        self._total_size = start_index + self.page_size
                
            finally:
                self._loading_pages.discard(page_num)
    
    def prefetch_pages(self, start_page: int, count: int):
        """Prefetch multiple pages"""
        for page_num in range(start_page, start_page + count):
            if page_num not in self._pages:
                self._load_page(page_num)

class LazyDict(Generic[T]):
    """Lazy-loaded dictionary"""
    
    def __init__(self, loader: Callable[[str], T], cache_ttl: Optional[float] = None):
        self.loader = loader
        self.cache_ttl = cache_ttl
        self._cache: Dict[str, T] = {}
        self._load_times: Dict[str, float] = {}
        self._loading_keys: set = set()
        self._lock = threading.RLock()
    
    def __getitem__(self, key: str) -> T:
        """Get value with lazy loading"""
        with self._lock:
            if key not in self._cache or self._is_expired(key):
                if key in self._loading_keys:
                    # Wait for ongoing loading
                    while key in self._loading_keys:
                        time.sleep(0.01)
                    if key in self._cache and not self._is_expired(key):
                        return self._cache[key]
                
                self._loading_keys.add(key)
                try:
                    value = self.loader(key)
                    self._cache[key] = value
                    self._load_times[key] = time.time()
                finally:
                    self._loading_keys.discard(key)
            
            return self._cache[key]
    
    def _is_expired(self, key: str) -> bool:
        """Check if cached value has expired"""
        if self.cache_ttl is None or key not in self._load_times:
            return False
        return time.time() - self._load_times[key] > self.cache_ttl
    
    def invalidate(self, key: str):
        """Invalidate specific key"""
        with self._lock:
            self._cache.pop(key, None)
            self._load_times.pop(key, None)

class LazyObjectProxy:
    """Proxy for lazy-loaded objects"""
    
    def __init__(self, loader: Callable[[], Any]):
        object.__setattr__(self, '_loader', loader)
        object.__setattr__(self, '_target', None)
        object.__setattr__(self, '_loaded', False)
        object.__setattr__(self, '_lock', threading.RLock())
    
    def _load_target(self):
        """Load the target object"""
        with object.__getattribute__(self, '_lock'):
            if not object.__getattribute__(self, '_loaded'):
                loader = object.__getattribute__(self, '_loader')
                target = loader()
                object.__setattr__(self, '_target', target)
                object.__setattr__(self, '_loaded', True)
    
    def __getattribute__(self, name):
        if name.startswith('_'):
            return object.__getattribute__(self, name)
        
        self._load_target()
        target = object.__getattribute__(self, '_target')
        return getattr(target, name)
    
    def __setattr__(self, name, value):
        if name.startswith('_'):
            object.__setattr__(self, name, value)
        else:
            self._load_target()
            target = object.__getattribute__(self, '_target')
            setattr(target, name, value)

# Database lazy loading examples
class LazyDatabaseRecord:
    """Lazy-loaded database record"""
    
    def __init__(self, record_id: str, db_connection):
        self.record_id = record_id
        self.db_connection = db_connection
        self._lazy_fields = {}
        self._loaded_fields = set()
        
    def _load_field(self, field_name: str) -> Any:
        """Load specific field from database"""
        if field_name not in self._loaded_fields:
            # Simulate database query
            time.sleep(0.1)  # Database latency
            
            # Mock field loading
            field_data = {
                'name': f'Record {self.record_id}',
                'description': f'Description for record {self.record_id}',
                'data': {'key': f'value_{self.record_id}'},
                'metadata': {'created_at': time.time(), 'version': 1}
            }
            
            self._lazy_fields[field_name] = field_data.get(field_name, None)
            self._loaded_fields.add(field_name)
        
        return self._lazy_fields[field_name]
    
    @property
    def name(self) -> str:
        return self._load_field('name')
    
    @property
    def description(self) -> str:
        return self._load_field('description')
    
    @property
    def data(self) -> Dict[str, Any]:
        return self._load_field('data')
    
    @property
    def metadata(self) -> Dict[str, Any]:
        return self._load_field('metadata')

class LazyImageLoader:
    """Lazy image loading with caching"""
    
    def __init__(self, image_url: str):
        self.image_url = image_url
        self._image_data = LazyValue(self._load_image, cache_ttl=3600)  # 1 hour cache
        self._thumbnail_data = LazyValue(self._load_thumbnail, cache_ttl=3600)
    
    def _load_image(self) -> bytes:
        """Load full image"""
        print(f"Loading full image from {self.image_url}")
        time.sleep(0.5)  # Simulate network download
        return b"full_image_data_" + self.image_url.encode()
    
    def _load_thumbnail(self) -> bytes:
        """Load thumbnail"""
        print(f"Loading thumbnail from {self.image_url}")
        time.sleep(0.2)  # Simulate network download
        return b"thumbnail_data_" + self.image_url.encode()
    
    @property
    def image(self) -> bytes:
        """Get full image data"""
        return self._image_data.value
    
    @property
    def thumbnail(self) -> bytes:
        """Get thumbnail data"""
        return self._thumbnail_data.value
    
    def is_loaded(self) -> bool:
        """Check if image is loaded"""
        return self._image_data.is_loaded()

# Web application lazy loading
class LazyWebComponent:
    """Lazy-loaded web component"""
    
    def __init__(self, component_id: str, loader_func: Callable[[], Dict[str, Any]]):
        self.component_id = component_id
        self.loader_func = loader_func
        self._content = None
        self._loaded = False
        self._load_time = None
    
    def render(self) -> str:
        """Render component (loads if necessary)"""
        if not self._loaded:
            self._load_content()
        
        return self._generate_html()
    
    def _load_content(self):
        """Load component content"""
        print(f"Loading component {self.component_id}")
        self._content = self.loader_func()
        self._loaded = True
        self._load_time = time.time()
    
    def _generate_html(self) -> str:
        """Generate HTML from loaded content"""
        if not self._content:
            return f'<div id="{self.component_id}">Loading...</div>'
        
        return f'''
        <div id="{self.component_id}" class="lazy-component">
            <h3>{self._content.get('title', 'Component')}</h3>
            <p>{self._content.get('description', 'No description')}</p>
            <div class="data">{self._content.get('data', {})}</div>
        </div>
        '''

# Performance monitoring for lazy loading
class LazyLoadingMonitor:
    """Monitor lazy loading performance"""
    
    def __init__(self):
        self.load_times = defaultdict(list)
        self.cache_hits = defaultdict(int)
        self.cache_misses = defaultdict(int)
        self.total_loads = defaultdict(int)
        self.lock = threading.RLock()
    
    def record_load(self, resource_type: str, load_time: float, cache_hit: bool):
        """Record a lazy load operation"""
        with self.lock:
            self.load_times[resource_type].append(load_time)
            self.total_loads[resource_type] += 1
            
            if cache_hit:
                self.cache_hits[resource_type] += 1
            else:
                self.cache_misses[resource_type] += 1
    
    def get_stats(self) -> Dict[str, Any]:
        """Get lazy loading statistics"""
        with self.lock:
            stats = {}
            
            for resource_type in self.total_loads:
                loads = self.load_times[resource_type]
                hits = self.cache_hits[resource_type]
                misses = self.cache_misses[resource_type]
                total = self.total_loads[resource_type]
                
                stats[resource_type] = {
                    'total_loads': total,
                    'cache_hit_rate': hits / total if total > 0 else 0,
                    'average_load_time': sum(loads) / len(loads) if loads else 0,
                    'min_load_time': min(loads) if loads else 0,
                    'max_load_time': max(loads) if loads else 0
                }
            
            return stats

# Example usage and testing
print("=== Lazy Loading Demo ===")

# Test lazy value
print("\n--- Lazy Value Test ---")

def expensive_computation():
    print("Performing expensive computation...")
    time.sleep(1)
    return "Computed result"

lazy_value = LazyValue(expensive_computation, cache_ttl=5.0)

print("Lazy value created (not computed yet)")
print(f"Is loaded: {lazy_value.is_loaded()}")

print("Accessing value for first time:")
result1 = lazy_value.value
print(f"Result: {result1}")
print(f"Is loaded: {lazy_value.is_loaded()}")

print("Accessing value again (should use cache):")
result2 = lazy_value.value
print(f"Result: {result2}")

# Test lazy list
print("\n--- Lazy List Test ---")

def load_page(start: int, size: int) -> List[str]:
    print(f"Loading page: start={start}, size={size}")
    time.sleep(0.2)  # Simulate database query
    return [f"item_{i}" for i in range(start, start + size)]

lazy_list = LazyList(load_page, page_size=5)

print("Accessing items from lazy list:")
print(f"Item 0: {lazy_list[0]}")  # Loads page 0
print(f"Item 7: {lazy_list[7]}")  # Loads page 1
print(f"Item 2: {lazy_list[2]}")  # Uses cached page 0

# Test lazy dictionary
print("\n--- Lazy Dictionary Test ---")

def load_config(key: str) -> str:
    print(f"Loading config: {key}")
    time.sleep(0.1)
    configs = {
        'database_url': 'postgresql://localhost:5432/mydb',
        'api_key': 'secret_api_key_12345',
        'cache_ttl': '3600'
    }
    return configs.get(key, 'default_value')

lazy_config = LazyDict(load_config, cache_ttl=10.0)

print("Accessing configuration values:")
print(f"Database URL: {lazy_config['database_url']}")
print(f"API Key: {lazy_config['api_key']}")
print(f"Database URL again: {lazy_config['database_url']}")  # Cached

# Test lazy database record
print("\n--- Lazy Database Record Test ---")

class MockDBConnection:
    pass

db_record = LazyDatabaseRecord("record_123", MockDBConnection())

print("Accessing record fields:")
print(f"Name: {db_record.name}")
print(f"Description: {db_record.description}")
print(f"Name again: {db_record.name}")  # Should not reload

# Test lazy image loading
print("\n--- Lazy Image Loading Test ---")

image_loader = LazyImageLoader("https://example.com/image.jpg")

print(f"Image loaded: {image_loader.is_loaded()}")
print("Loading thumbnail:")
thumbnail = image_loader.thumbnail
print(f"Thumbnail size: {len(thumbnail)} bytes")

print("Loading full image:")
full_image = image_loader.image
print(f"Full image size: {len(full_image)} bytes")
print(f"Image loaded: {image_loader.is_loaded()}")

# Test lazy web component
print("\n--- Lazy Web Component Test ---")

def load_component_data():
    print("Loading component data from API...")
    time.sleep(0.3)
    return {
        'title': 'User Dashboard',
        'description': 'Welcome to your personalized dashboard',
        'data': {'user_count': 1234, 'active_sessions': 56}
    }

web_component = LazyWebComponent("dashboard", load_component_data)

print("Rendering component:")
html = web_component.render()
print(html[:100] + "..." if len(html) > 100 else html)

# Test performance monitoring
print("\n--- Performance Monitoring ---")

monitor = LazyLoadingMonitor()

# Simulate some loads
for i in range(10):
    load_time = 0.1 + (i % 3) * 0.05  # Varying load times
    cache_hit = i > 2 and i % 2 == 0  # Some cache hits
    monitor.record_load("database", load_time, cache_hit)

for i in range(5):
    load_time = 0.5 + (i % 2) * 0.2
    cache_hit = i > 1
    monitor.record_load("images", load_time, cache_hit)

stats = monitor.get_stats()
print("Lazy loading statistics:")
for resource_type, data in stats.items():
    print(f"  {resource_type}:")
    print(f"    Total loads: {data['total_loads']}")
    print(f"    Cache hit rate: {data['cache_hit_rate']:.2%}")
    print(f"    Average load time: {data['average_load_time']:.3f}s")

print("\n--- Lazy Loading Demo Completed ---")
```

## 📚 Conclusion

Lazy loading is a fundamental performance optimization technique that improves application responsiveness by loading resources only when needed. From simple value caching to complex paginated data structures, lazy loading enables applications to handle large datasets efficiently while providing excellent user experience.

**Key Takeaways:**

1. **Load On-Demand**: Only fetch resources when actually needed
2. **Cache Intelligently**: Store loaded resources with appropriate TTL
3. **Handle Concurrency**: Prevent duplicate loading with proper synchronization
4. **Monitor Performance**: Track cache hit rates and loading times
5. **Progressive Enhancement**: Start with basic functionality, load advanced features lazily

The future of lazy loading includes AI-powered predictive loading, integration with edge computing, and advanced browser APIs for optimal resource management. Whether building web applications, mobile apps, or distributed systems, implementing effective lazy loading strategies is essential for optimal performance and user experience.
