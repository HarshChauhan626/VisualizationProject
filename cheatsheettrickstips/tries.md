# Tries Data Structure - Comprehensive Cheatsheet

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

### What is a Trie?

A Trie (Prefix Tree) is a tree-like data structure used to store strings where each node represents a character. Think of it as a digital dictionary where you can efficiently search for words by following character paths from root to leaves.

**Key Characteristics:**
- **Prefix-based**: Shared prefixes use same path
- **Character nodes**: Each node represents one character
- **String termination**: Marks complete words
- **Efficient prefix operations**: Fast prefix matching

### Basic Trie Structure
```python
class TrieNode:
    def __init__(self):
        self.children = {}  # Dictionary of character -> TrieNode
        self.is_end_of_word = False  # Marks complete word
        self.word_count = 0  # Optional: count of words ending here

class Trie:
    def __init__(self):
        self.root = TrieNode()
```

---

## Key Properties & Rules

### Fundamental Operations

#### 1. **Insert Operation**
```python
def insert(self, word):
    node = self.root
    for char in word:
        if char not in node.children:
            node.children[char] = TrieNode()
        node = node.children[char]
    node.is_end_of_word = True
    node.word_count += 1
```

#### 2. **Search Operation**
```python
def search(self, word):
    node = self.root
    for char in word:
        if char not in node.children:
            return False
        node = node.children[char]
    return node.is_end_of_word

def starts_with(self, prefix):
    node = self.root
    for char in prefix:
        if char not in node.children:
            return False
        node = node.children[char]
    return True
```

#### 3. **Delete Operation**
```python
def delete(self, word):
    def _delete_helper(node, word, index):
        if index == len(word):
            if not node.is_end_of_word:
                return False
            node.is_end_of_word = False
            return len(node.children) == 0
        
        char = word[index]
        if char not in node.children:
            return False
        
        should_delete_child = _delete_helper(node.children[char], word, index + 1)
        
        if should_delete_child:
            del node.children[char]
            return not node.is_end_of_word and len(node.children) == 0
        
        return False
    
    _delete_helper(self.root, word, 0)
```

---

## Patterns & Use Cases

### Core Trie Patterns

#### 1. **Word Dictionary Pattern**
```python
class WordDictionary:
    def __init__(self):
        self.trie = Trie()
    
    def add_word(self, word):
        self.trie.insert(word)
    
    def search(self, word):
        def dfs(node, index):
            if index == len(word):
                return node.is_end_of_word
            
            char = word[index]
            if char == '.':
                # Wildcard - try all children
                for child in node.children.values():
                    if dfs(child, index + 1):
                        return True
                return False
            else:
                if char not in node.children:
                    return False
                return dfs(node.children[char], index + 1)
        
        return dfs(self.trie.root, 0)
```

#### 2. **Autocomplete Pattern**
```python
def find_words_with_prefix(self, prefix):
    node = self.root
    for char in prefix:
        if char not in node.children:
            return []
        node = node.children[char]
    
    # DFS to find all words with this prefix
    words = []
    
    def dfs(current_node, current_word):
        if current_node.is_end_of_word:
            words.append(current_word)
        
        for char, child_node in current_node.children.items():
            dfs(child_node, current_word + char)
    
    dfs(node, prefix)
    return words
```

#### 3. **Word Break Pattern**
```python
def word_break(self, s):
    def backtrack(start):
        if start == len(s):
            return True
        
        node = self.root
        for end in range(start, len(s)):
            char = s[end]
            if char not in node.children:
                break
            
            node = node.children[char]
            if node.is_end_of_word and backtrack(end + 1):
                return True
        
        return False
    
    return backtrack(0)
```

#### 4. **Longest Common Prefix**
```python
def longest_common_prefix(self, words):
    if not words:
        return ""
    
    # Insert all words
    for word in words:
        self.insert(word)
    
    # Find LCP by traversing until branch or end
    node = self.root
    prefix = ""
    
    while len(node.children) == 1 and not node.is_end_of_word:
        char = next(iter(node.children))
        prefix += char
        node = node.children[char]
    
    return prefix
```

---

## Common Algorithms

### 1. **Word Search II (Boggle)**
```python
def find_words(self, board, words):
    # Build trie
    trie = Trie()
    for word in words:
        trie.insert(word)
    
    result = set()
    rows, cols = len(board), len(board[0])
    
    def dfs(row, col, node, path):
        if (row < 0 or row >= rows or col < 0 or col >= cols or
            board[row][col] == '#'):
            return
        
        char = board[row][col]
        if char not in node.children:
            return
        
        node = node.children[char]
        path += char
        
        if node.is_end_of_word:
            result.add(path)
        
        # Mark as visited
        board[row][col] = '#'
        
        # Explore neighbors
        for dr, dc in [(0,1), (1,0), (0,-1), (-1,0)]:
            dfs(row + dr, col + dc, node, path)
        
        # Restore
        board[row][col] = char
    
    for i in range(rows):
        for j in range(cols):
            dfs(i, j, trie.root, "")
    
    return list(result)
```

### 2. **Replace Words**
```python
def replace_words(self, dictionary, sentence):
    trie = Trie()
    for root in dictionary:
        trie.insert(root)
    
    def find_root(word):
        node = trie.root
        prefix = ""
        
        for char in word:
            if char not in node.children:
                return word
            
            prefix += char
            node = node.children[char]
            
            if node.is_end_of_word:
                return prefix
        
        return word
    
    words = sentence.split()
    return " ".join(find_root(word) for word in words)
```

### 3. **Maximum XOR**
```python
class BinaryTrie:
    def __init__(self):
        self.root = TrieNode()
    
    def insert(self, num):
        node = self.root
        for i in range(31, -1, -1):
            bit = (num >> i) & 1
            if bit not in node.children:
                node.children[bit] = TrieNode()
            node = node.children[bit]
    
    def find_max_xor(self, num):
        node = self.root
        max_xor = 0
        
        for i in range(31, -1, -1):
            bit = (num >> i) & 1
            toggled_bit = 1 - bit
            
            if toggled_bit in node.children:
                max_xor |= (1 << i)
                node = node.children[toggled_bit]
            else:
                node = node.children[bit]
        
        return max_xor

def find_maximum_xor(nums):
    trie = BinaryTrie()
    for num in nums:
        trie.insert(num)
    
    max_xor = 0
    for num in nums:
        max_xor = max(max_xor, trie.find_max_xor(num))
    
    return max_xor
```

---

## Example Problems

### Problem 1: **Implement Trie**
```python
class Trie:
    def __init__(self):
        self.root = TrieNode()
    
    def insert(self, word):
        node = self.root
        for char in word:
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]
        node.is_end_of_word = True
    
    def search(self, word):
        node = self.root
        for char in word:
            if char not in node.children:
                return False
            node = node.children[char]
        return node.is_end_of_word
    
    def starts_with(self, prefix):
        node = self.root
        for char in prefix:
            if char not in node.children:
                return False
            node = node.children[char]
        return True
```

### Problem 2: **Word Squares**
```python
def word_squares(words):
    def build_prefix_map(words):
        prefix_map = {}
        for word in words:
            for i in range(len(word)):
                prefix = word[:i+1]
                if prefix not in prefix_map:
                    prefix_map[prefix] = []
                prefix_map[prefix].append(word)
        return prefix_map
    
    if not words:
        return []
    
    n = len(words[0])
    prefix_map = build_prefix_map(words)
    result = []
    
    def backtrack(square):
        if len(square) == n:
            result.append(square[:])
            return
        
        # Find prefix for next row
        pos = len(square)
        prefix = ""
        for i in range(pos):
            prefix += square[i][pos]
        
        if prefix in prefix_map:
            for word in prefix_map[prefix]:
                square.append(word)
                backtrack(square)
                square.pop()
    
    for word in words:
        backtrack([word])
    
    return result
```

---

## Problem Categories

### 1. **String Search and Matching**
- Word search in grids
- Pattern matching
- Dictionary lookups

### 2. **Prefix Operations**
- Autocomplete systems
- Longest common prefix
- Prefix counting

### 3. **Word Games**
- Boggle/Word search
- Word squares
- Crossword validation

### 4. **Optimization Problems**
- Maximum XOR using binary trie
- String compression
- IP routing (longest prefix match)

---

## Complexity Analysis

### Time Complexities
- **Insert**: O(m) where m is string length
- **Search**: O(m)
- **Delete**: O(m)
- **Prefix search**: O(p) where p is prefix length

### Space Complexity
- **Storage**: O(ALPHABET_SIZE * N * M) worst case
- **Practical**: Much better with shared prefixes
- **Each node**: O(ALPHABET_SIZE) for children array

---

## Pro Tips & Interview Tricks

### Essential Patterns

#### Trie Node Template:
```python
class TrieNode:
    def __init__(self):
        self.children = {}
        self.is_end_of_word = False
        self.count = 0  # For frequency counting
```

#### DFS Template for Word Collection:
```python
def collect_words(self, node, prefix, words):
    if node.is_end_of_word:
        words.append(prefix)
    
    for char, child in node.children.items():
        self.collect_words(child, prefix + char, words)
```

### Common Optimizations

1. **Array vs Dictionary**: Use arrays for fixed alphabets
2. **Compression**: Compress single-child paths
3. **Lazy deletion**: Mark nodes instead of removing
4. **Memory pooling**: Reuse TrieNode objects

### Interview Success Tips

1. **Recognize trie problems**: Prefix operations, word games, dictionaries
2. **Handle edge cases**: Empty strings, case sensitivity
3. **Consider alternatives**: Hash sets might be simpler for some problems
4. **Optimize for use case**: Read-heavy vs write-heavy workloads
5. **Memory awareness**: Tries can be memory-intensive
6. **Binary tries**: For bit manipulation problems

Tries are powerful for string processing and prefix operations. Master the core patterns and understand when to use them over simpler alternatives!