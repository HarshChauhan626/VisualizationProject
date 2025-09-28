# Hashing Algorithms - Comprehensive Cheatsheet

## Table of Contents
1. [Definition & Intuition](#definition--intuition)
2. [Key Properties & Rules](#key-properties--rules)
3. [Patterns & Use Cases](#patterns--use-cases)
4. [Step-by-Step Approaches](#step-by-step-approaches)
5. [Common Algorithms](#common-algorithms)
6. [Edge Cases](#edge-cases)
7. [Complexity Analysis](#complexity-analysis)
8. [Example Problems](#example-problems)
9. [Problem Categories](#problem-categories)
10. [Pro Tips & Interview Tricks](#pro-tips--interview-tricks)

---

## Definition & Intuition

### What is Hashing?

Hashing is a technique that maps data of arbitrary size to fixed-size values using a hash function. Think of it as creating a fingerprint for data - a unique identifier that allows rapid lookup, insertion, and deletion operations.

**Key Concepts:**
- **Hash Function**: Maps keys to array indices
- **Hash Table**: Array-based data structure using hashing
- **Collision**: When different keys map to same index
- **Load Factor**: Ratio of stored elements to table size

### Types of Hashing

#### 1. **Division Method**
```python
def hash_division(key, table_size):
    return key % table_size
```

#### 2. **Multiplication Method**
```python
def hash_multiplication(key, table_size):
    A = 0.6180339887  # (sqrt(5) - 1) / 2
    return int(table_size * ((key * A) % 1))
```

#### 3. **Universal Hashing**
```python
import random

class UniversalHashFunction:
    def __init__(self, table_size, prime=1000000007):
        self.table_size = table_size
        self.prime = prime
        self.a = random.randint(1, prime - 1)
        self.b = random.randint(0, prime - 1)
    
    def hash(self, key):
        return ((self.a * key + self.b) % self.prime) % self.table_size
```

---

## Key Properties & Rules

### Hash Function Properties

#### 1. **Good Hash Function Characteristics**
- **Uniform Distribution**: Spreads keys evenly
- **Deterministic**: Same input gives same output
- **Efficient**: Fast computation
- **Avalanche Effect**: Small input change causes large output change

#### 2. **Collision Resolution**

**Separate Chaining:**
```python
class HashTableChaining:
    def __init__(self, size=10):
        self.size = size
        self.table = [[] for _ in range(size)]
    
    def _hash(self, key):
        return hash(key) % self.size
    
    def insert(self, key, value):
        index = self._hash(key)
        bucket = self.table[index]
        
        for i, (k, v) in enumerate(bucket):
            if k == key:
                bucket[i] = (key, value)
                return
        
        bucket.append((key, value))
    
    def get(self, key):
        index = self._hash(key)
        bucket = self.table[index]
        
        for k, v in bucket:
            if k == key:
                return v
        
        raise KeyError(key)
    
    def delete(self, key):
        index = self._hash(key)
        bucket = self.table[index]
        
        for i, (k, v) in enumerate(bucket):
            if k == key:
                del bucket[i]
                return
        
        raise KeyError(key)
```

**Open Addressing:**
```python
class HashTableOpenAddressing:
    def __init__(self, size=10):
        self.size = size
        self.table = [None] * size
        self.deleted = [False] * size
    
    def _hash(self, key, attempt=0):
        # Linear probing
        return (hash(key) + attempt) % self.size
    
    def insert(self, key, value):
        for i in range(self.size):
            index = self._hash(key, i)
            
            if self.table[index] is None or self.deleted[index]:
                self.table[index] = (key, value)
                self.deleted[index] = False
                return
            
            if self.table[index][0] == key:
                self.table[index] = (key, value)
                return
        
        raise Exception("Hash table is full")
    
    def get(self, key):
        for i in range(self.size):
            index = self._hash(key, i)
            
            if self.table[index] is None:
                break
            
            if not self.deleted[index] and self.table[index][0] == key:
                return self.table[index][1]
        
        raise KeyError(key)
```

### Cryptographic Hash Functions

#### 1. **Rolling Hash (Rabin-Karp)**
```python
class RollingHash:
    def __init__(self, base=256, mod=1000000007):
        self.base = base
        self.mod = mod
    
    def compute_hash(self, s):
        hash_value = 0
        for char in s:
            hash_value = (hash_value * self.base + ord(char)) % self.mod
        return hash_value
    
    def rolling_hash(self, s, pattern_length):
        if len(s) < pattern_length:
            return []
        
        # Compute hash of first window
        current_hash = self.compute_hash(s[:pattern_length])
        hashes = [current_hash]
        
        # Precompute base^(pattern_length-1)
        base_power = pow(self.base, pattern_length - 1, self.mod)
        
        # Roll the hash
        for i in range(pattern_length, len(s)):
            # Remove leading character
            current_hash = (current_hash - ord(s[i - pattern_length]) * base_power) % self.mod
            # Add trailing character
            current_hash = (current_hash * self.base + ord(s[i])) % self.mod
            hashes.append(current_hash)
        
        return hashes
```

---

## Patterns & Use Cases

### Core Hashing Patterns

#### 1. **Frequency Counting Pattern**
```python
def frequency_analysis(items):
    frequency = {}
    for item in items:
        frequency[item] = frequency.get(item, 0) + 1
    return frequency

def most_frequent_k(items, k):
    from collections import Counter
    import heapq
    
    counter = Counter(items)
    return heapq.nlargest(k, counter.keys(), key=counter.get)
```

#### 2. **Two Sum Pattern**
```python
def two_sum(nums, target):
    seen = {}
    for i, num in enumerate(nums):
        complement = target - num
        if complement in seen:
            return [seen[complement], i]
        seen[num] = i
    return []

def three_sum(nums):
    nums.sort()
    result = []
    
    for i in range(len(nums) - 2):
        if i > 0 and nums[i] == nums[i-1]:
            continue
        
        left, right = i + 1, len(nums) - 1
        target = -nums[i]
        
        while left < right:
            current_sum = nums[left] + nums[right]
            if current_sum == target:
                result.append([nums[i], nums[left], nums[right]])
                
                while left < right and nums[left] == nums[left + 1]:
                    left += 1
                while left < right and nums[right] == nums[right - 1]:
                    right -= 1
                
                left += 1
                right -= 1
            elif current_sum < target:
                left += 1
            else:
                right -= 1
    
    return result
```

#### 3. **Substring Search Pattern**
```python
def rabin_karp_search(text, pattern):
    rh = RollingHash()
    pattern_hash = rh.compute_hash(pattern)
    text_hashes = rh.rolling_hash(text, len(pattern))
    
    matches = []
    for i, text_hash in enumerate(text_hashes):
        if text_hash == pattern_hash:
            # Verify actual match (avoid hash collisions)
            if text[i:i + len(pattern)] == pattern:
                matches.append(i)
    
    return matches
```

#### 4. **Caching Pattern**
```python
class LRUCache:
    def __init__(self, capacity):
        self.capacity = capacity
        self.cache = {}
        self.order = []
    
    def get(self, key):
        if key in self.cache:
            # Move to end (most recently used)
            self.order.remove(key)
            self.order.append(key)
            return self.cache[key]
        return -1
    
    def put(self, key, value):
        if key in self.cache:
            self.order.remove(key)
        elif len(self.cache) >= self.capacity:
            # Remove least recently used
            lru = self.order.pop(0)
            del self.cache[lru]
        
        self.cache[key] = value
        self.order.append(key)
```

---

## Common Algorithms

### 1. **Consistent Hashing**
```python
import hashlib
import bisect

class ConsistentHash:
    def __init__(self, replicas=3):
        self.replicas = replicas
        self.ring = {}
        self.sorted_keys = []
    
    def _hash(self, key):
        return int(hashlib.md5(key.encode()).hexdigest(), 16)
    
    def add_node(self, node):
        for i in range(self.replicas):
            replica_key = f"{node}:{i}"
            key = self._hash(replica_key)
            self.ring[key] = node
            bisect.insort(self.sorted_keys, key)
    
    def remove_node(self, node):
        for i in range(self.replicas):
            replica_key = f"{node}:{i}"
            key = self._hash(replica_key)
            del self.ring[key]
            self.sorted_keys.remove(key)
    
    def get_node(self, key):
        if not self.ring:
            return None
        
        hash_key = self._hash(key)
        idx = bisect.bisect_right(self.sorted_keys, hash_key)
        
        if idx == len(self.sorted_keys):
            idx = 0
        
        return self.ring[self.sorted_keys[idx]]
```

### 2. **Bloom Filter**
```python
import hashlib
from bitarray import bitarray

class BloomFilter:
    def __init__(self, size, hash_count):
        self.size = size
        self.hash_count = hash_count
        self.bit_array = bitarray(size)
        self.bit_array.setall(0)
    
    def _hashes(self, item):
        hashes = []
        for i in range(self.hash_count):
            digest = hashlib.md5((str(item) + str(i)).encode()).hexdigest()
            hashes.append(int(digest, 16) % self.size)
        return hashes
    
    def add(self, item):
        for hash_val in self._hashes(item):
            self.bit_array[hash_val] = 1
    
    def contains(self, item):
        for hash_val in self._hashes(item):
            if not self.bit_array[hash_val]:
                return False
        return True
```

### 3. **String Hashing for Pattern Matching**
```python
def find_all_anagrams(s, p):
    from collections import Counter
    
    if len(p) > len(s):
        return []
    
    p_count = Counter(p)
    window_count = Counter()
    
    result = []
    left = 0
    
    for right in range(len(s)):
        # Expand window
        char = s[right]
        window_count[char] += 1
        
        # Shrink window
        if right - left + 1 > len(p):
            left_char = s[left]
            window_count[left_char] -= 1
            if window_count[left_char] == 0:
                del window_count[left_char]
            left += 1
        
        # Check for anagram
        if window_count == p_count:
            result.append(left)
    
    return result
```

---

## Example Problems

### Problem 1: **Group Anagrams**
```python
def group_anagrams(strs):
    from collections import defaultdict
    
    groups = defaultdict(list)
    
    for s in strs:
        # Sort characters to create key
        key = ''.join(sorted(s))
        groups[key].append(s)
    
    return list(groups.values())

def group_anagrams_counting(strs):
    from collections import defaultdict
    
    groups = defaultdict(list)
    
    for s in strs:
        # Count characters to create key
        count = [0] * 26
        for char in s:
            count[ord(char) - ord('a')] += 1
        key = tuple(count)
        groups[key].append(s)
    
    return list(groups.values())
```

### Problem 2: **Longest Substring Without Repeating Characters**
```python
def length_of_longest_substring(s):
    char_index = {}
    left = 0
    max_length = 0
    
    for right, char in enumerate(s):
        if char in char_index and char_index[char] >= left:
            left = char_index[char] + 1
        
        char_index[char] = right
        max_length = max(max_length, right - left + 1)
    
    return max_length
```

### Problem 3: **Valid Anagram**
```python
def is_anagram(s, t):
    if len(s) != len(t):
        return False
    
    from collections import Counter
    return Counter(s) == Counter(t)

def is_anagram_sorting(s, t):
    return sorted(s) == sorted(t)

def is_anagram_counting(s, t):
    if len(s) != len(t):
        return False
    
    count = {}
    for char in s:
        count[char] = count.get(char, 0) + 1
    
    for char in t:
        if char not in count:
            return False
        count[char] -= 1
        if count[char] == 0:
            del count[char]
    
    return len(count) == 0
```

---

## Problem Categories

### 1. **Frequency and Counting**
- Character/element frequency
- Most frequent elements
- Duplicate detection

### 2. **Subset and Grouping**
- Group anagrams
- Finding pairs/triplets
- Subset problems

### 3. **String Processing**
- Pattern matching
- Substring problems
- Anagram detection

### 4. **Caching and Memoization**
- LRU Cache
- Function memoization
- Data deduplication

---

## Complexity Analysis

### Time Complexities
- **Hash Table Operations**: O(1) average, O(n) worst case
- **Hash Function Computation**: O(k) where k is key size
- **Collision Resolution**: Depends on method and load factor

### Space Complexities
- **Hash Table**: O(n) where n is number of elements
- **Load Factor**: n/m where m is table size
- **Optimal Load Factor**: ~0.75 for good performance

---

## Pro Tips & Interview Tricks

### Essential Patterns

#### Hash Table as Counter:
```python
# Frequency counting
freq = {}
for item in items:
    freq[item] = freq.get(item, 0) + 1

# Using collections.Counter
from collections import Counter
freq = Counter(items)
```

#### Hash Table for Lookup:
```python
# Fast membership testing
seen = set(items)
if target in seen:
    # O(1) lookup
    pass

# Index mapping
index_map = {val: i for i, val in enumerate(items)}
```

#### Rolling Hash Template:
```python
def rolling_hash_search(text, pattern):
    base = 256
    mod = 10**9 + 7
    
    pattern_hash = 0
    for char in pattern:
        pattern_hash = (pattern_hash * base + ord(char)) % mod
    
    # Continue with rolling hash logic
```

### Common Mistakes
1. **Hash Collisions**: Always handle collisions properly
2. **Hash Function Choice**: Use appropriate hash function for data type
3. **Load Factor**: Monitor and resize when necessary
4. **Key Immutability**: Ensure hash keys don't change

### Interview Success Tips
1. **Recognize hash table opportunities**: Fast lookup, counting, grouping
2. **Choose right collision resolution**: Separate chaining vs open addressing
3. **Handle edge cases**: Empty inputs, single elements
4. **Consider space-time tradeoffs**: Hash table space for time improvement
5. **Know built-in functions**: dict, set, Counter in Python

Hashing is fundamental to many efficient algorithms. Master the core concepts and common patterns to excel in technical interviews!