# Database Indexing: Accelerating Data Retrieval

## 🎯 What is Database Indexing?

Database indexing is like creating a detailed table of contents or index in a book. Just as you use an index to quickly find specific topics without reading every page, database indexes help the database engine quickly locate specific data without scanning every row. Without indexes, finding data would be like searching for a specific sentence in a library by reading every book page by page.

## 🏗️ Core Concepts

### The Library Analogy Extended
- **Table Data**: Books on shelves (stored sequentially)
- **Index**: Card catalog or digital index system
- **Primary Key**: Unique book ID number
- **Secondary Index**: Subject, author, or title indexes
- **Composite Index**: Multi-field search system (author + year + genre)
- **Query Optimizer**: Librarian who knows the best way to find information

### Why Indexing Matters
1. **Query Performance**: Dramatically reduce data retrieval time
2. **Scalability**: Handle large datasets efficiently
3. **User Experience**: Faster application response times
4. **Resource Efficiency**: Reduce CPU and I/O usage
5. **Concurrent Access**: Better performance under load

## 📊 Types of Database Indexes

### 1. Primary Index (Clustered Index)
```python
class PrimaryIndex:
    """
    Primary index determines the physical order of data storage.
    Only one primary index per table (usually on primary key).
    """
    
    def __init__(self, table_name, primary_key_column):
        self.table_name = table_name
        self.primary_key_column = primary_key_column
        self.data_pages = {}  # Physical storage pages
        self.index_structure = BPlusTree()  # B+ tree for fast lookups
    
    def insert_record(self, primary_key, record_data):
        """Insert record maintaining sorted order"""
        
        # Find correct page for insertion
        target_page = self.find_insertion_page(primary_key)
        
        if target_page.has_space():
            target_page.insert_sorted(primary_key, record_data)
        else:
            # Split page if full
            new_page = self.split_page(target_page)
            self.update_index_structure(target_page, new_page)
            
            # Insert in appropriate page
            if primary_key < new_page.min_key:
                target_page.insert_sorted(primary_key, record_data)
            else:
                new_page.insert_sorted(primary_key, record_data)
        
        # Update index structure
        self.index_structure.insert(primary_key, target_page.page_id)
    
    def search_record(self, primary_key):
        """Search record using primary index - O(log n)"""
        
        # Use B+ tree to find page
        page_id = self.index_structure.search(primary_key)
        
        if page_id:
            page = self.data_pages[page_id]
            return page.binary_search(primary_key)
        
        return None
    
    def range_query(self, start_key, end_key):
        """Efficient range queries using clustered data"""
        
        results = []
        start_page_id = self.index_structure.search(start_key)
        
        if not start_page_id:
            return results
        
        current_page = self.data_pages[start_page_id]
        
        while current_page and current_page.min_key <= end_key:
            # Get records in range from current page
            page_results = current_page.get_range(start_key, end_key)
            results.extend(page_results)
            
            # Move to next page
            current_page = current_page.next_page
        
        return results

# Example usage
class UserTable:
    def __init__(self):
        self.primary_index = PrimaryIndex('users', 'user_id')
        self.record_count = 0
    
    def create_user(self, user_id, name, email, created_at):
        """Create user with automatic indexing"""
        
        user_record = {
            'user_id': user_id,
            'name': name,
            'email': email,
            'created_at': created_at
        }
        
        self.primary_index.insert_record(user_id, user_record)
        self.record_count += 1
        
        print(f"User {user_id} created and indexed")
    
    def get_user(self, user_id):
        """Get user by ID - O(log n) with index"""
        return self.primary_index.search_record(user_id)
    
    def get_users_in_range(self, start_id, end_id):
        """Get users in ID range - efficient with clustered index"""
        return self.primary_index.range_query(start_id, end_id)

# Demonstrate primary index performance
user_table = UserTable()

# Insert users
for i in range(1, 10001):  # 10,000 users
    user_table.create_user(
        user_id=i,
        name=f"User {i}",
        email=f"user{i}@example.com",
        created_at=time.time()
    )

# Fast lookup by primary key
user = user_table.get_user(5000)  # O(log n) - very fast
print(f"Found user: {user['name']}")

# Efficient range query
users_batch = user_table.get_users_in_range(1000, 2000)  # Fast sequential read
print(f"Retrieved {len(users_batch)} users in range")
```

### 2. Secondary Index (Non-Clustered Index)
```python
class SecondaryIndex:
    """
    Secondary index provides alternative access paths to data.
    Points to primary key or row location.
    """
    
    def __init__(self, table_name, indexed_column, primary_key_column):
        self.table_name = table_name
        self.indexed_column = indexed_column
        self.primary_key_column = primary_key_column
        self.index_structure = BPlusTree()  # B+ tree for indexed column
        self.statistics = IndexStatistics()
    
    def build_index(self, table_data):
        """Build secondary index from existing table data"""
        
        print(f"Building secondary index on {self.indexed_column}...")
        start_time = time.time()
        
        for record in table_data:
            indexed_value = record[self.indexed_column]
            primary_key = record[self.primary_key_column]
            
            # Handle duplicate values (multiple records with same indexed value)
            if self.index_structure.contains(indexed_value):
                existing_keys = self.index_structure.get(indexed_value)
                if isinstance(existing_keys, list):
                    existing_keys.append(primary_key)
                else:
                    self.index_structure.update(indexed_value, [existing_keys, primary_key])
            else:
                self.index_structure.insert(indexed_value, primary_key)
        
        build_time = time.time() - start_time
        self.statistics.record_build_time(build_time)
        print(f"Index built in {build_time:.2f} seconds")
    
    def search_by_indexed_column(self, value):
        """Search using secondary index"""
        
        search_start = time.time()
        
        # Step 1: Search secondary index
        primary_keys = self.index_structure.search(value)
        
        if not primary_keys:
            return []
        
        # Step 2: Lookup actual records using primary keys
        results = []
        if isinstance(primary_keys, list):
            for pk in primary_keys:
                record = self.lookup_by_primary_key(pk)
                if record:
                    results.append(record)
        else:
            record = self.lookup_by_primary_key(primary_keys)
            if record:
                results.append(record)
        
        search_time = time.time() - search_start
        self.statistics.record_search_time(search_time)
        
        return results
    
    def update_index(self, old_value, new_value, primary_key):
        """Update secondary index when data changes"""
        
        # Remove old entry
        if old_value is not None:
            self.remove_from_index(old_value, primary_key)
        
        # Add new entry
        if new_value is not None:
            self.add_to_index(new_value, primary_key)
    
    def get_index_statistics(self):
        """Get index usage and performance statistics"""
        return {
            'index_name': f"{self.table_name}_{self.indexed_column}_idx",
            'indexed_column': self.indexed_column,
            'total_searches': self.statistics.total_searches,
            'average_search_time_ms': self.statistics.get_average_search_time() * 1000,
            'index_size_mb': self.calculate_index_size() / (1024 * 1024),
            'selectivity': self.calculate_selectivity(),
            'usage_frequency': self.statistics.get_usage_frequency()
        }
    
    def calculate_selectivity(self):
        """Calculate index selectivity (uniqueness)"""
        unique_values = self.index_structure.get_unique_count()
        total_records = self.index_structure.get_total_records()
        
        if total_records == 0:
            return 0
        
        return unique_values / total_records

# Example: Email index for user lookups
class EmailIndex(SecondaryIndex):
    def __init__(self, user_table):
        super().__init__('users', 'email', 'user_id')
        self.user_table = user_table
    
    def find_user_by_email(self, email):
        """Find user by email address"""
        users = self.search_by_indexed_column(email)
        return users[0] if users else None
    
    def lookup_by_primary_key(self, user_id):
        """Lookup user record by primary key"""
        return self.user_table.get_user(user_id)

# Usage example
email_index = EmailIndex(user_table)
email_index.build_index(user_table.get_all_records())

# Fast email lookup
user = email_index.find_user_by_email("user5000@example.com")
print(f"Found user by email: {user['name']}")

# Index statistics
stats = email_index.get_index_statistics()
print(f"Email index selectivity: {stats['selectivity']:.3f}")
print(f"Average search time: {stats['average_search_time_ms']:.2f}ms")
```

### 3. Composite Index
```python
class CompositeIndex:
    """
    Composite index on multiple columns.
    Column order matters for query optimization.
    """
    
    def __init__(self, table_name, indexed_columns, primary_key_column):
        self.table_name = table_name
        self.indexed_columns = indexed_columns  # Ordered list of columns
        self.primary_key_column = primary_key_column
        self.index_structure = BPlusTree()
        self.column_statistics = {}
    
    def build_composite_key(self, record):
        """Build composite key from multiple columns"""
        key_parts = []
        for column in self.indexed_columns:
            value = record.get(column, '')
            # Normalize values for consistent sorting
            if isinstance(value, str):
                key_parts.append(value.lower().strip())
            else:
                key_parts.append(str(value))
        
        return '|'.join(key_parts)  # Use delimiter to separate parts
    
    def insert_record(self, record):
        """Insert record into composite index"""
        composite_key = self.build_composite_key(record)
        primary_key = record[self.primary_key_column]
        
        self.index_structure.insert(composite_key, primary_key)
    
    def search_exact_match(self, **column_values):
        """Search with exact match on all indexed columns"""
        
        # Ensure all indexed columns are provided
        if set(column_values.keys()) != set(self.indexed_columns):
            missing_columns = set(self.indexed_columns) - set(column_values.keys())
            raise ValueError(f"Missing columns for composite index: {missing_columns}")
        
        # Build search key in correct column order
        search_record = {col: column_values[col] for col in self.indexed_columns}
        composite_key = self.build_composite_key(search_record)
        
        return self.index_structure.search(composite_key)
    
    def search_prefix_match(self, **column_values):
        """Search with prefix match (left-most columns)"""
        
        # Validate that provided columns are left-most
        provided_columns = list(column_values.keys())
        expected_prefix = self.indexed_columns[:len(provided_columns)]
        
        if provided_columns != expected_prefix:
            raise ValueError(f"Prefix search must use left-most columns in order: {expected_prefix}")
        
        # Build partial composite key
        partial_record = {col: column_values[col] for col in provided_columns}
        partial_key = self.build_composite_key(partial_record)
        
        # Perform prefix search
        return self.index_structure.search_prefix(partial_key)
    
    def analyze_query_efficiency(self, query_columns):
        """Analyze how efficiently a query can use this composite index"""
        
        # Check if query can use index
        usable_columns = []
        for i, indexed_col in enumerate(self.indexed_columns):
            if indexed_col in query_columns:
                usable_columns.append(indexed_col)
            else:
                break  # Can't skip columns in composite index
        
        efficiency_score = len(usable_columns) / len(self.indexed_columns)
        
        return {
            'can_use_index': len(usable_columns) > 0,
            'usable_columns': usable_columns,
            'efficiency_score': efficiency_score,
            'recommendation': self.get_efficiency_recommendation(efficiency_score)
        }
    
    def get_efficiency_recommendation(self, efficiency_score):
        """Get recommendation based on efficiency score"""
        
        if efficiency_score == 1.0:
            return "Excellent - Query uses entire composite index"
        elif efficiency_score >= 0.7:
            return "Good - Query uses most of the composite index"
        elif efficiency_score >= 0.5:
            return "Fair - Query uses some of the composite index"
        else:
            return "Poor - Consider reordering composite index or creating separate index"

# Example: Order search index (customer_id, order_date, status)
class OrderSearchIndex(CompositeIndex):
    def __init__(self):
        super().__init__('orders', ['customer_id', 'order_date', 'status'], 'order_id')
    
    def find_customer_orders(self, customer_id, start_date=None, end_date=None, status=None):
        """Find orders with various search criteria"""
        
        if start_date and end_date and status:
            # Can use full composite index efficiently
            results = []
            current_date = start_date
            
            while current_date <= end_date:
                date_str = current_date.strftime('%Y-%m-%d')
                orders = self.search_exact_match(
                    customer_id=customer_id,
                    order_date=date_str,
                    status=status
                )
                results.extend(orders)
                current_date += timedelta(days=1)
            
            return results
        
        elif status:
            # Can use prefix match on customer_id
            return self.search_prefix_match(customer_id=customer_id)
        
        else:
            # Can only use customer_id part of index
            return self.search_prefix_match(customer_id=customer_id)

# Usage examples
order_index = OrderSearchIndex()

# Efficient queries (use composite index well)
orders = order_index.find_customer_orders(
    customer_id=12345,
    start_date=datetime(2024, 1, 1),
    end_date=datetime(2024, 1, 31),
    status='shipped'
)

# Analyze query efficiency
efficiency = order_index.analyze_query_efficiency(['customer_id', 'status'])
print(f"Query efficiency: {efficiency['efficiency_score']:.2f}")
print(f"Recommendation: {efficiency['recommendation']}")
```

### 4. Unique Index
```python
class UniqueIndex:
    """
    Unique index ensures no duplicate values and provides fast lookups.
    """
    
    def __init__(self, table_name, unique_column):
        self.table_name = table_name
        self.unique_column = unique_column
        self.index_structure = HashTable()  # Hash table for O(1) lookups
        self.duplicate_violations = []
    
    def insert_unique_value(self, value, primary_key):
        """Insert value ensuring uniqueness"""
        
        if self.index_structure.contains(value):
            violation = {
                'value': value,
                'existing_key': self.index_structure.get(value),
                'attempted_key': primary_key,
                'timestamp': time.time()
            }
            self.duplicate_violations.append(violation)
            raise UniqueConstraintViolation(f"Duplicate value '{value}' in unique index")
        
        self.index_structure.insert(value, primary_key)
    
    def delete_value(self, value):
        """Delete value from unique index"""
        if self.index_structure.contains(value):
            self.index_structure.delete(value)
    
    def update_value(self, old_value, new_value, primary_key):
        """Update value in unique index"""
        
        # Check if new value already exists (and it's not the same record)
        if (self.index_structure.contains(new_value) and 
            self.index_structure.get(new_value) != primary_key):
            raise UniqueConstraintViolation(f"Duplicate value '{new_value}' in unique index")
        
        # Remove old value and add new value
        self.delete_value(old_value)
        self.insert_unique_value(new_value, primary_key)
    
    def validate_uniqueness(self, dataset):
        """Validate uniqueness across entire dataset"""
        
        seen_values = set()
        duplicates = []
        
        for record in dataset:
            value = record[self.unique_column]
            
            if value in seen_values:
                duplicates.append(value)
            else:
                seen_values.add(value)
        
        return {
            'is_unique': len(duplicates) == 0,
            'duplicate_values': duplicates,
            'unique_count': len(seen_values),
            'total_count': len(dataset)
        }

# Example: Username unique index
class UsernameIndex(UniqueIndex):
    def __init__(self):
        super().__init__('users', 'username')
    
    def register_username(self, username, user_id):
        """Register new username ensuring uniqueness"""
        try:
            self.insert_unique_value(username.lower(), user_id)
            return True
        except UniqueConstraintViolation as e:
            print(f"Username registration failed: {e}")
            return False
    
    def is_username_available(self, username):
        """Check if username is available"""
        return not self.index_structure.contains(username.lower())
    
    def suggest_alternative_usernames(self, desired_username):
        """Suggest alternative usernames if desired one is taken"""
        
        if self.is_username_available(desired_username):
            return [desired_username]
        
        suggestions = []
        base_username = desired_username.lower()
        
        # Try with numbers
        for i in range(1, 100):
            candidate = f"{base_username}{i}"
            if self.is_username_available(candidate):
                suggestions.append(candidate)
                if len(suggestions) >= 5:
                    break
        
        # Try with prefixes/suffixes
        prefixes = ['the', 'real', 'official']
        suffixes = ['user', 'account', 'profile']
        
        for prefix in prefixes:
            candidate = f"{prefix}{base_username}"
            if self.is_username_available(candidate):
                suggestions.append(candidate)
        
        for suffix in suffixes:
            candidate = f"{base_username}{suffix}"
            if self.is_username_available(candidate):
                suggestions.append(candidate)
        
        return suggestions[:10]  # Return top 10 suggestions

# Usage example
username_index = UsernameIndex()

# Register usernames
success = username_index.register_username("john_doe", 1001)
print(f"Registration successful: {success}")

# Try to register duplicate
duplicate_success = username_index.register_username("john_doe", 1002)
print(f"Duplicate registration successful: {duplicate_success}")

# Get suggestions for taken username
suggestions = username_index.suggest_alternative_usernames("john_doe")
print(f"Alternative usernames: {suggestions}")
```

## 🚀 Index Performance Analysis

### Query Performance Comparison
```python
class IndexPerformanceAnalyzer:
    def __init__(self):
        self.test_results = {}
    
    def benchmark_query_performance(self, table_size, query_types):
        """Benchmark different query scenarios with and without indexes"""
        
        # Create test data
        test_data = self.generate_test_data(table_size)
        
        results = {}
        
        for query_type in query_types:
            results[query_type] = {
                'without_index': self.benchmark_without_index(test_data, query_type),
                'with_index': self.benchmark_with_index(test_data, query_type)
            }
        
        return results
    
    def generate_test_data(self, size):
        """Generate test dataset"""
        import random
        
        data = []
        for i in range(size):
            record = {
                'id': i + 1,
                'name': f"User {i + 1}",
                'email': f"user{i + 1}@example.com",
                'age': random.randint(18, 80),
                'city': random.choice(['New York', 'London', 'Tokyo', 'Paris', 'Sydney']),
                'salary': random.randint(30000, 150000),
                'department': random.choice(['Engineering', 'Sales', 'Marketing', 'HR', 'Finance'])
            }
            data.append(record)
        
        return data
    
    def benchmark_without_index(self, data, query_type):
        """Benchmark query without index (full table scan)"""
        
        start_time = time.time()
        
        if query_type == 'single_record_lookup':
            # Linear search through all records
            target_id = len(data) // 2  # Search for middle record
            result = None
            for record in data:
                if record['id'] == target_id:
                    result = record
                    break
        
        elif query_type == 'range_query':
            # Find all records in age range
            results = []
            for record in data:
                if 25 <= record['age'] <= 35:
                    results.append(record)
        
        elif query_type == 'group_by_query':
            # Group by department
            groups = {}
            for record in data:
                dept = record['department']
                if dept not in groups:
                    groups[dept] = []
                groups[dept].append(record)
        
        execution_time = time.time() - start_time
        
        return {
            'execution_time_ms': execution_time * 1000,
            'complexity': 'O(n)',
            'records_scanned': len(data)
        }
    
    def benchmark_with_index(self, data, query_type):
        """Benchmark query with appropriate index"""
        
        # Build indexes
        id_index = {}
        age_index = {}
        dept_index = {}
        
        index_build_start = time.time()
        
        for record in data:
            # Build ID index (hash table)
            id_index[record['id']] = record
            
            # Build age index (sorted list)
            age = record['age']
            if age not in age_index:
                age_index[age] = []
            age_index[age].append(record)
            
            # Build department index
            dept = record['department']
            if dept not in dept_index:
                dept_index[dept] = []
            dept_index[dept].append(record)
        
        index_build_time = time.time() - index_build_start
        
        # Execute query with index
        query_start = time.time()
        
        if query_type == 'single_record_lookup':
            target_id = len(data) // 2
            result = id_index.get(target_id)
        
        elif query_type == 'range_query':
            results = []
            for age in range(25, 36):  # Ages 25-35
                if age in age_index:
                    results.extend(age_index[age])
        
        elif query_type == 'group_by_query':
            groups = dept_index  # Already grouped by department
        
        query_time = time.time() - query_start
        
        return {
            'index_build_time_ms': index_build_time * 1000,
            'query_execution_time_ms': query_time * 1000,
            'total_time_ms': (index_build_time + query_time) * 1000,
            'complexity': 'O(log n) or O(1)',
            'records_scanned': 'Minimal (index lookup)'
        }
    
    def generate_performance_report(self, results):
        """Generate comprehensive performance report"""
        
        report = {
            'summary': {},
            'detailed_results': results,
            'recommendations': []
        }
        
        for query_type, performance in results.items():
            without_index = performance['without_index']
            with_index = performance['with_index']
            
            # Calculate improvement
            improvement_factor = (without_index['execution_time_ms'] / 
                                with_index['query_execution_time_ms'])
            
            report['summary'][query_type] = {
                'improvement_factor': f"{improvement_factor:.1f}x faster",
                'without_index_time': f"{without_index['execution_time_ms']:.2f}ms",
                'with_index_time': f"{with_index['query_execution_time_ms']:.2f}ms"
            }
            
            # Generate recommendations
            if improvement_factor > 10:
                report['recommendations'].append(
                    f"Strong recommendation: Index for {query_type} queries "
                    f"({improvement_factor:.1f}x performance improvement)"
                )
            elif improvement_factor > 2:
                report['recommendations'].append(
                    f"Consider indexing for {query_type} queries "
                    f"({improvement_factor:.1f}x performance improvement)"
                )
        
        return report

# Performance benchmarking example
analyzer = IndexPerformanceAnalyzer()

# Test with different table sizes
table_sizes = [1000, 10000, 100000]
query_types = ['single_record_lookup', 'range_query', 'group_by_query']

for table_size in table_sizes:
    print(f"\n=== Performance Analysis for {table_size:,} records ===")
    
    results = analyzer.benchmark_query_performance(table_size, query_types)
    report = analyzer.generate_performance_report(results)
    
    for query_type, summary in report['summary'].items():
        print(f"{query_type}: {summary['improvement_factor']} "
              f"({summary['without_index_time']} → {summary['with_index_time']})")
    
    print("\nRecommendations:")
    for recommendation in report['recommendations']:
        print(f"- {recommendation}")
```

## ⚖️ Index Trade-offs and Considerations

### Storage and Maintenance Overhead
```python
class IndexOverheadAnalyzer:
    def __init__(self):
        self.overhead_metrics = {}
    
    def calculate_storage_overhead(self, table_info, index_info):
        """Calculate storage overhead of indexes"""
        
        # Base table storage
        record_size = table_info['average_record_size_bytes']
        record_count = table_info['record_count']
        table_size = record_size * record_count
        
        # Index storage calculation
        total_index_size = 0
        index_details = {}
        
        for index_name, index_config in index_info.items():
            if index_config['type'] == 'primary':
                # Primary index: typically 10-15% overhead
                index_size = table_size * 0.12
            
            elif index_config['type'] == 'secondary':
                # Secondary index: key + pointer
                key_size = index_config['key_size_bytes']
                pointer_size = 8  # 64-bit pointer
                index_size = record_count * (key_size + pointer_size)
                
                # Add B-tree overhead (approximately 25%)
                index_size *= 1.25
            
            elif index_config['type'] == 'composite':
                # Composite index: sum of key sizes + pointer
                total_key_size = sum(index_config['key_sizes_bytes'])
                pointer_size = 8
                index_size = record_count * (total_key_size + pointer_size)
                index_size *= 1.25  # B-tree overhead
            
            total_index_size += index_size
            index_details[index_name] = {
                'size_bytes': index_size,
                'size_mb': index_size / (1024 * 1024),
                'percentage_of_table': (index_size / table_size) * 100
            }
        
        return {
            'table_size_mb': table_size / (1024 * 1024),
            'total_index_size_mb': total_index_size / (1024 * 1024),
            'total_storage_mb': (table_size + total_index_size) / (1024 * 1024),
            'storage_overhead_percentage': (total_index_size / table_size) * 100,
            'index_details': index_details
        }
    
    def calculate_maintenance_overhead(self, operation_stats, index_count):
        """Calculate maintenance overhead for different operations"""
        
        overhead = {}
        
        # INSERT overhead
        base_insert_time = operation_stats['base_insert_time_ms']
        index_update_time_per_index = 0.5  # 0.5ms per index update
        insert_overhead = index_count * index_update_time_per_index
        
        overhead['insert'] = {
            'base_time_ms': base_insert_time,
            'index_overhead_ms': insert_overhead,
            'total_time_ms': base_insert_time + insert_overhead,
            'overhead_percentage': (insert_overhead / base_insert_time) * 100
        }
        
        # UPDATE overhead
        base_update_time = operation_stats['base_update_time_ms']
        # Updates may need to update multiple indexes
        update_overhead = index_count * 0.8  # 0.8ms per index update
        
        overhead['update'] = {
            'base_time_ms': base_update_time,
            'index_overhead_ms': update_overhead,
            'total_time_ms': base_update_time + update_overhead,
            'overhead_percentage': (update_overhead / base_update_time) * 100
        }
        
        # DELETE overhead
        base_delete_time = operation_stats['base_delete_time_ms']
        delete_overhead = index_count * 0.3  # 0.3ms per index cleanup
        
        overhead['delete'] = {
            'base_time_ms': base_delete_time,
            'index_overhead_ms': delete_overhead,
            'total_time_ms': base_delete_time + delete_overhead,
            'overhead_percentage': (delete_overhead / base_delete_time) * 100
        }
        
        return overhead

# Example overhead analysis
analyzer = IndexOverheadAnalyzer()

# Define table and index configuration
table_info = {
    'record_count': 1000000,  # 1 million records
    'average_record_size_bytes': 256  # 256 bytes per record
}

index_info = {
    'primary_key_idx': {
        'type': 'primary',
        'columns': ['id']
    },
    'email_idx': {
        'type': 'secondary',
        'columns': ['email'],
        'key_size_bytes': 64  # Average email length
    },
    'name_age_idx': {
        'type': 'composite',
        'columns': ['last_name', 'age'],
        'key_sizes_bytes': [32, 4]  # 32 bytes for name, 4 for age
    },
    'department_idx': {
        'type': 'secondary',
        'columns': ['department'],
        'key_size_bytes': 16  # Department code
    }
}

operation_stats = {
    'base_insert_time_ms': 2.0,
    'base_update_time_ms': 1.5,
    'base_delete_time_ms': 1.0
}

# Calculate overheads
storage_overhead = analyzer.calculate_storage_overhead(table_info, index_info)
maintenance_overhead = analyzer.calculate_maintenance_overhead(operation_stats, len(index_info))

print("=== Storage Overhead Analysis ===")
print(f"Table size: {storage_overhead['table_size_mb']:.1f} MB")
print(f"Total index size: {storage_overhead['total_index_size_mb']:.1f} MB")
print(f"Storage overhead: {storage_overhead['storage_overhead_percentage']:.1f}%")

print("\n=== Index Details ===")
for index_name, details in storage_overhead['index_details'].items():
    print(f"{index_name}: {details['size_mb']:.1f} MB ({details['percentage_of_table']:.1f}% of table)")

print("\n=== Maintenance Overhead Analysis ===")
for operation, overhead in maintenance_overhead.items():
    print(f"{operation.upper()}: {overhead['base_time_ms']:.1f}ms → "
          f"{overhead['total_time_ms']:.1f}ms ({overhead['overhead_percentage']:.1f}% overhead)")
```

## 🔧 Index Optimization Strategies

### Query-Driven Index Design
```python
class IndexOptimizer:
    def __init__(self):
        self.query_patterns = {}
        self.existing_indexes = {}
        self.performance_history = {}
    
    def analyze_query_patterns(self, query_log):
        """Analyze query patterns to recommend optimal indexes"""
        
        patterns = {
            'frequent_columns': {},
            'where_clauses': {},
            'join_columns': {},
            'order_by_columns': {},
            'group_by_columns': {}
        }
        
        for query in query_log:
            # Parse query to extract patterns
            parsed = self.parse_query(query)
            
            # Count column usage frequency
            for column in parsed['columns_used']:
                patterns['frequent_columns'][column] = patterns['frequent_columns'].get(column, 0) + 1
            
            # Analyze WHERE clauses
            for condition in parsed['where_conditions']:
                column = condition['column']
                patterns['where_clauses'][column] = patterns['where_clauses'].get(column, 0) + 1
            
            # Analyze JOINs
            for join in parsed['joins']:
                for column in join['columns']:
                    patterns['join_columns'][column] = patterns['join_columns'].get(column, 0) + 1
            
            # Analyze ORDER BY
            for column in parsed['order_by_columns']:
                patterns['order_by_columns'][column] = patterns['order_by_columns'].get(column, 0) + 1
            
            # Analyze GROUP BY
            for column in parsed['group_by_columns']:
                patterns['group_by_columns'][column] = patterns['group_by_columns'].get(column, 0) + 1
        
        return patterns
    
    def recommend_indexes(self, query_patterns, table_stats):
        """Recommend indexes based on query patterns and table statistics"""
        
        recommendations = []
        
        # Single column indexes for frequently filtered columns
        frequent_where_columns = sorted(
            query_patterns['where_clauses'].items(),
            key=lambda x: x[1],
            reverse=True
        )
        
        for column, frequency in frequent_where_columns[:5]:  # Top 5
            if frequency > 10:  # Threshold for recommendation
                selectivity = self.calculate_column_selectivity(column, table_stats)
                
                if selectivity > 0.1:  # Good selectivity
                    recommendations.append({
                        'type': 'single_column',
                        'columns': [column],
                        'reason': f'Frequently used in WHERE clauses ({frequency} times)',
                        'priority': 'High' if frequency > 50 else 'Medium',
                        'estimated_benefit': self.estimate_performance_benefit(column, frequency, selectivity)
                    })
        
        # Composite indexes for common column combinations
        column_combinations = self.find_common_column_combinations(query_patterns)
        
        for combination, frequency in column_combinations:
            if frequency > 5 and len(combination) <= 4:  # Reasonable composite index
                recommendations.append({
                    'type': 'composite',
                    'columns': combination,
                    'reason': f'Common column combination in queries ({frequency} times)',
                    'priority': 'Medium',
                    'column_order_recommendation': self.optimize_column_order(combination, query_patterns)
                })
        
        # Covering indexes for expensive queries
        covering_opportunities = self.find_covering_index_opportunities(query_patterns)
        
        for opportunity in covering_opportunities:
            recommendations.append({
                'type': 'covering',
                'columns': opportunity['columns'],
                'reason': 'Can eliminate table lookups for common query pattern',
                'priority': 'Low',
                'queries_affected': opportunity['query_count']
            })
        
        return recommendations
    
    def calculate_column_selectivity(self, column, table_stats):
        """Calculate selectivity of a column"""
        unique_values = table_stats['columns'][column]['unique_count']
        total_rows = table_stats['total_rows']
        
        return unique_values / total_rows if total_rows > 0 else 0
    
    def estimate_performance_benefit(self, column, frequency, selectivity):
        """Estimate performance benefit of creating an index"""
        
        # Base benefit from avoiding full table scans
        base_benefit = frequency * selectivity * 100  # Simplified calculation
        
        # Adjust for selectivity (higher selectivity = more benefit)
        selectivity_multiplier = min(selectivity * 2, 1.5)
        
        estimated_benefit = base_benefit * selectivity_multiplier
        
        if estimated_benefit > 1000:
            return 'Very High'
        elif estimated_benefit > 500:
            return 'High'
        elif estimated_benefit > 100:
            return 'Medium'
        else:
            return 'Low'
    
    def find_common_column_combinations(self, query_patterns):
        """Find commonly used column combinations"""
        
        combinations = {}
        
        # Analyze WHERE clause combinations
        # This is a simplified version - real implementation would be more sophisticated
        for query_type in ['where_clauses', 'join_columns']:
            columns = list(query_patterns[query_type].keys())
            
            # Find pairs and triplets
            for i in range(len(columns)):
                for j in range(i + 1, len(columns)):
                    pair = tuple(sorted([columns[i], columns[j]]))
                    combinations[pair] = combinations.get(pair, 0) + 1
                    
                    # Check triplets
                    for k in range(j + 1, len(columns)):
                        triplet = tuple(sorted([columns[i], columns[j], columns[k]]))
                        combinations[triplet] = combinations.get(triplet, 0) + 1
        
        return sorted(combinations.items(), key=lambda x: x[1], reverse=True)
    
    def optimize_column_order(self, columns, query_patterns):
        """Optimize column order in composite index"""
        
        # Order by selectivity (most selective first)
        column_selectivity = {}
        for column in columns:
            # Simplified selectivity calculation
            where_frequency = query_patterns['where_clauses'].get(column, 0)
            column_selectivity[column] = where_frequency
        
        optimized_order = sorted(columns, key=lambda c: column_selectivity[c], reverse=True)
        
        return {
            'recommended_order': optimized_order,
            'reasoning': 'Ordered by query frequency (most frequent first)',
            'alternative_orders': [
                {
                    'order': sorted(columns),  # Alphabetical
                    'use_case': 'If queries often filter by first column alphabetically'
                }
            ]
        }

# Example usage
optimizer = IndexOptimizer()

# Sample query log analysis
sample_query_patterns = {
    'where_clauses': {
        'user_id': 150,
        'email': 75,
        'status': 120,
        'created_date': 90,
        'department_id': 45
    },
    'join_columns': {
        'user_id': 80,
        'department_id': 60,
        'manager_id': 30
    },
    'order_by_columns': {
        'created_date': 40,
        'last_name': 25
    }
}

sample_table_stats = {
    'total_rows': 1000000,
    'columns': {
        'user_id': {'unique_count': 1000000},  # Unique
        'email': {'unique_count': 1000000},    # Unique
        'status': {'unique_count': 5},         # Low selectivity
        'created_date': {'unique_count': 365}, # Medium selectivity
        'department_id': {'unique_count': 50}  # Medium selectivity
    }
}

# Get index recommendations
recommendations = optimizer.recommend_indexes(sample_query_patterns, sample_table_stats)

print("=== Index Recommendations ===")
for i, rec in enumerate(recommendations, 1):
    print(f"\n{i}. {rec['type'].title()} Index")
    print(f"   Columns: {', '.join(rec['columns'])}")
    print(f"   Priority: {rec['priority']}")
    print(f"   Reason: {rec['reason']}")
    if 'estimated_benefit' in rec:
        print(f"   Estimated Benefit: {rec['estimated_benefit']}")
```

## 📊 Monitoring Index Performance

### Index Usage Statistics
```python
class IndexMonitor:
    def __init__(self):
        self.usage_stats = {}
        self.performance_metrics = {}
        self.maintenance_logs = {}
    
    def track_index_usage(self, index_name, query_type, execution_time_ms):
        """Track index usage statistics"""
        
        if index_name not in self.usage_stats:
            self.usage_stats[index_name] = {
                'total_uses': 0,
                'query_types': {},
                'total_execution_time_ms': 0,
                'last_used': None
            }
        
        stats = self.usage_stats[index_name]
        stats['total_uses'] += 1
        stats['total_execution_time_ms'] += execution_time_ms
        stats['last_used'] = time.time()
        
        if query_type not in stats['query_types']:
            stats['query_types'][query_type] = {'count': 0, 'total_time_ms': 0}
        
        stats['query_types'][query_type]['count'] += 1
        stats['query_types'][query_type]['total_time_ms'] += execution_time_ms
    
    def identify_unused_indexes(self, time_threshold_days=30):
        """Identify indexes that haven't been used recently"""
        
        threshold_timestamp = time.time() - (time_threshold_days * 24 * 3600)
        unused_indexes = []
        
        for index_name, stats in self.usage_stats.items():
            if stats['last_used'] is None or stats['last_used'] < threshold_timestamp:
                unused_indexes.append({
                    'index_name': index_name,
                    'last_used_days_ago': (time.time() - (stats['last_used'] or 0)) / (24 * 3600),
                    'total_uses': stats['total_uses'],
                    'storage_impact': self.estimate_storage_impact(index_name)
                })
        
        return sorted(unused_indexes, key=lambda x: x['storage_impact'], reverse=True)
    
    def identify_inefficient_indexes(self):
        """Identify indexes with poor performance characteristics"""
        
        inefficient_indexes = []
        
        for index_name, stats in self.usage_stats.items():
            if stats['total_uses'] > 0:
                avg_execution_time = stats['total_execution_time_ms'] / stats['total_uses']
                
                # Flag indexes with consistently high execution times
                if avg_execution_time > 100:  # 100ms threshold
                    inefficient_indexes.append({
                        'index_name': index_name,
                        'average_execution_time_ms': avg_execution_time,
                        'total_uses': stats['total_uses'],
                        'issue': 'High average execution time',
                        'recommendation': self.get_performance_recommendation(index_name, avg_execution_time)
                    })
        
        return inefficient_indexes
    
    def generate_index_health_report(self):
        """Generate comprehensive index health report"""
        
        report = {
            'summary': {
                'total_indexes': len(self.usage_stats),
                'active_indexes': 0,
                'unused_indexes': 0,
                'inefficient_indexes': 0
            },
            'usage_analysis': {},
            'performance_issues': [],
            'recommendations': []
        }
        
        # Analyze usage patterns
        for index_name, stats in self.usage_stats.items():
            if stats['total_uses'] > 0:
                report['summary']['active_indexes'] += 1
                
                avg_time = stats['total_execution_time_ms'] / stats['total_uses']
                usage_frequency = stats['total_uses'] / max(1, (time.time() - (stats['last_used'] or time.time())) / 86400)
                
                report['usage_analysis'][index_name] = {
                    'usage_frequency_per_day': usage_frequency,
                    'average_execution_time_ms': avg_time,
                    'most_common_query_type': max(stats['query_types'].items(), key=lambda x: x[1]['count'])[0] if stats['query_types'] else 'Unknown',
                    'health_score': self.calculate_index_health_score(stats)
                }
            else:
                report['summary']['unused_indexes'] += 1
        
        # Identify issues and recommendations
        unused = self.identify_unused_indexes()
        inefficient = self.identify_inefficient_indexes()
        
        report['summary']['unused_indexes'] = len(unused)
        report['summary']['inefficient_indexes'] = len(inefficient)
        
        # Generate recommendations
        for index in unused:
            if index['storage_impact'] > 100:  # MB
                report['recommendations'].append({
                    'type': 'DROP_INDEX',
                    'index_name': index['index_name'],
                    'reason': f"Unused for {index['last_used_days_ago']:.0f} days, consuming {index['storage_impact']:.0f} MB",
                    'priority': 'Medium'
                })
        
        for index in inefficient:
            report['recommendations'].append({
                'type': 'OPTIMIZE_INDEX',
                'index_name': index['index_name'],
                'reason': index['issue'],
                'recommendation': index['recommendation'],
                'priority': 'High'
            })
        
        return report
    
    def calculate_index_health_score(self, stats):
        """Calculate health score for an index (0-100)"""
        
        score = 100
        
        # Penalize high execution times
        if stats['total_uses'] > 0:
            avg_time = stats['total_execution_time_ms'] / stats['total_uses']
            if avg_time > 50:
                score -= min(50, avg_time / 2)
        
        # Reward frequent usage
        if stats['total_uses'] > 100:
            score += min(20, stats['total_uses'] / 50)
        
        # Penalize lack of recent usage
        if stats['last_used']:
            days_since_use = (time.time() - stats['last_used']) / 86400
            if days_since_use > 7:
                score -= min(30, days_since_use * 2)
        
        return max(0, min(100, score))

# Example monitoring usage
monitor = IndexMonitor()

# Simulate index usage tracking
indexes = ['user_id_idx', 'email_idx', 'created_date_idx', 'status_idx', 'composite_user_status_idx']
query_types = ['SELECT', 'JOIN', 'ORDER_BY', 'WHERE']

# Simulate usage over time
import random

for _ in range(1000):  # 1000 queries
    index = random.choice(indexes)
    query_type = random.choice(query_types)
    execution_time = random.gauss(25, 10)  # 25ms average, 10ms std dev
    
    monitor.track_index_usage(index, query_type, max(1, execution_time))

# Generate health report
health_report = monitor.generate_index_health_report()

print("=== Index Health Report ===")
print(f"Total indexes: {health_report['summary']['total_indexes']}")
print(f"Active indexes: {health_report['summary']['active_indexes']}")
print(f"Unused indexes: {health_report['summary']['unused_indexes']}")
print(f"Inefficient indexes: {health_report['summary']['inefficient_indexes']}")

print("\n=== Usage Analysis ===")
for index_name, analysis in health_report['usage_analysis'].items():
    print(f"{index_name}:")
    print(f"  Health Score: {analysis['health_score']:.0f}/100")
    print(f"  Usage Frequency: {analysis['usage_frequency_per_day']:.1f} queries/day")
    print(f"  Avg Execution Time: {analysis['average_execution_time_ms']:.1f}ms")

print("\n=== Recommendations ===")
for rec in health_report['recommendations']:
    print(f"- {rec['type']}: {rec['index_name']}")
    print(f"  Reason: {rec['reason']}")
    print(f"  Priority: {rec['priority']}")
```

## 📚 Conclusion

Database indexing is a critical performance optimization technique that can transform slow, unusable applications into fast, responsive systems. Understanding when and how to use different types of indexes—primary, secondary, composite, and unique—is essential for building scalable database applications.

**Key Takeaways:**

1. **Choose the Right Index Type**: Different index types serve different purposes and query patterns
2. **Monitor Performance Impact**: Indexes improve read performance but add overhead to writes
3. **Design for Your Queries**: Analyze query patterns to create optimal indexes
4. **Balance Storage and Performance**: More indexes mean better query performance but higher storage costs
5. **Maintain Index Health**: Regularly monitor and optimize indexes based on actual usage

The future of database indexing includes AI-powered automatic index recommendations, adaptive indexes that adjust to changing query patterns, and new index structures optimized for modern hardware and workloads. Whether you're building a simple web application or a complex data warehouse, mastering indexing concepts is crucial for creating performant, scalable database systems.

Remember: indexes are powerful tools, but they're not magic—they must be carefully designed, implemented, and maintained to provide maximum benefit while minimizing overhead.
