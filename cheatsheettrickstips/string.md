# String Algorithms - Comprehensive Cheatsheet

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

### What are Strings?

Strings are sequences of characters - the fundamental data type for text processing. From DNA sequences to web search, string algorithms power countless applications in computer science.

**String Properties:**
- **Immutable** (in many languages): Cannot modify in-place
- **Indexed**: Access characters by position
- **Sequential**: Order matters
- **Variable Length**: Can grow/shrink (depending on implementation)

### String Representations

#### ASCII vs Unicode
- **ASCII**: 7-bit encoding (128 characters)
- **Unicode**: Universal character encoding
- **UTF-8**: Variable-length Unicode encoding

#### Internal Storage
```python
# Python strings (immutable)
s = "hello"
s[0]  # 'h' - indexing allowed
s[0] = 'H'  # Error - modification not allowed

# Character arrays (mutable)
chars = ['h', 'e', 'l', 'l', 'o']
chars[0] = 'H'  # Allowed
```

---

## Key Properties & Rules

### String Operations Complexity

| Operation | Time | Space | Notes |
|-----------|------|-------|---------|
| Access | O(1) | O(1) | Direct indexing |
| Search | O(n) | O(1) | Linear scan |
| Concatenation | O(n+m) | O(n+m) | Creates new string |
| Substring | O(k) | O(k) | k = substring length |
| Comparison | O(min(n,m)) | O(1) | Lexicographic |

### Pattern Matching Algorithms

| Algorithm | Preprocessing | Matching | Space |
|-----------|---------------|----------|-------|
| Naive | O(1) | O(nm) | O(1) |
| KMP | O(m) | O(n+m) | O(m) |
| Rabin-Karp | O(m) | O(n+m) avg | O(1) |
| Boyer-Moore | O(m+σ) | O(n/m) best | O(m+σ) |

*n = text length, m = pattern length, σ = alphabet size*

---

## Patterns & Use Cases

### Core String Patterns

#### 1. **Two Pointers**
- Palindrome checking
- String reversal
- Valid parentheses

#### 2. **Sliding Window**
- Longest substring without repeating characters
- Minimum window substring
- Anagram detection

#### 3. **Pattern Matching**
- String search algorithms
- Regular expression matching
- Wildcard matching

#### 4. **Dynamic Programming**
- Edit distance
- Longest common subsequence
- Palindrome problems

---

## Step-by-Step Approaches

### String Problem Framework

1. **Identify Problem Type**:
   - Pattern matching?
   - Transformation?
   - Parsing?
   - Generation?

2. **Choose Data Structure**:
   - String/char array for modifications
   - StringBuilder for concatenations
   - Hash map for character counting

3. **Select Algorithm**:
   - Two pointers for palindromes
   - Sliding window for substring problems
   - DP for edit distance
   - KMP for pattern matching

---

## Common Algorithms

### 1. Pattern Matching

#### Naive String Search
```python
def naive_search(text, pattern):
    n, m = len(text), len(pattern)
    positions = []
    
    for i in range(n - m + 1):
        match = True
        for j in range(m):
            if text[i + j] != pattern[j]:
                match = False
                break
        if match:
            positions.append(i)
    
    return positions
```

#### KMP Algorithm
```python
def compute_lps(pattern):
    """Compute Longest Proper Prefix which is also Suffix"""
    m = len(pattern)
    lps = [0] * m
    length = 0
    i = 1
    
    while i < m:
        if pattern[i] == pattern[length]:
            length += 1
            lps[i] = length
            i += 1
        else:
            if length != 0:
                length = lps[length - 1]
            else:
                lps[i] = 0
                i += 1
    
    return lps

def kmp_search(text, pattern):
    n, m = len(text), len(pattern)
    if m == 0:
        return []
    
    lps = compute_lps(pattern)
    positions = []
    
    i = j = 0
    while i < n:
        if text[i] == pattern[j]:
            i += 1
            j += 1
        
        if j == m:
            positions.append(i - j)
            j = lps[j - 1]
        elif i < n and text[i] != pattern[j]:
            if j != 0:
                j = lps[j - 1]
            else:
                i += 1
    
    return positions
```

#### Rabin-Karp Algorithm
```python
def rabin_karp(text, pattern, prime=101):
    n, m = len(text), len(pattern)
    if m > n:
        return []
    
    # Calculate hash values
    pattern_hash = 0
    text_hash = 0
    h = 1
    
    # h = pow(256, m-1) % prime
    for i in range(m - 1):
        h = (h * 256) % prime
    
    # Calculate initial hash values
    for i in range(m):
        pattern_hash = (256 * pattern_hash + ord(pattern[i])) % prime
        text_hash = (256 * text_hash + ord(text[i])) % prime
    
    positions = []
    
    # Slide pattern over text
    for i in range(n - m + 1):
        # Check hash values
        if pattern_hash == text_hash:
            # Check character by character
            match = True
            for j in range(m):
                if text[i + j] != pattern[j]:
                    match = False
                    break
            if match:
                positions.append(i)
        
        # Calculate next hash value
        if i < n - m:
            text_hash = (256 * (text_hash - ord(text[i]) * h) + ord(text[i + m])) % prime
            if text_hash < 0:
                text_hash += prime
    
    return positions
```

### 2. String Transformation

#### Edit Distance (Levenshtein Distance)
```python
def edit_distance(word1, word2):
    m, n = len(word1), len(word2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    
    # Initialize base cases
    for i in range(m + 1):
        dp[i][0] = i
    for j in range(n + 1):
        dp[0][j] = j
    
    # Fill the DP table
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if word1[i-1] == word2[j-1]:
                dp[i][j] = dp[i-1][j-1]
            else:
                dp[i][j] = 1 + min(
                    dp[i-1][j],    # Deletion
                    dp[i][j-1],    # Insertion
                    dp[i-1][j-1]   # Substitution
                )
    
    return dp[m][n]
```

#### Longest Common Subsequence
```python
def lcs_length(text1, text2):
    m, n = len(text1), len(text2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if text1[i-1] == text2[j-1]:
                dp[i][j] = dp[i-1][j-1] + 1
            else:
                dp[i][j] = max(dp[i-1][j], dp[i][j-1])
    
    return dp[m][n]

def lcs_string(text1, text2):
    m, n = len(text1), len(text2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    
    # Build the DP table
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if text1[i-1] == text2[j-1]:
                dp[i][j] = dp[i-1][j-1] + 1
            else:
                dp[i][j] = max(dp[i-1][j], dp[i][j-1])
    
    # Reconstruct the LCS
    lcs = []
    i, j = m, n
    while i > 0 and j > 0:
        if text1[i-1] == text2[j-1]:
            lcs.append(text1[i-1])
            i -= 1
            j -= 1
        elif dp[i-1][j] > dp[i][j-1]:
            i -= 1
        else:
            j -= 1
    
    return ''.join(reversed(lcs))
```

### 3. Palindrome Algorithms

#### Check Palindrome
```python
def is_palindrome(s):
    left, right = 0, len(s) - 1
    
    while left < right:
        if s[left] != s[right]:
            return False
        left += 1
        right -= 1
    
    return True

def is_palindrome_ignore_case(s):
    # Clean string: remove non-alphanumeric, convert to lowercase
    clean = ''.join(c.lower() for c in s if c.isalnum())
    return is_palindrome(clean)
```

#### Longest Palindromic Substring
```python
def longest_palindrome_expand(s):
    if not s:
        return ""
    
    start = 0
    max_len = 1
    
    def expand_around_center(left, right):
        while left >= 0 and right < len(s) and s[left] == s[right]:
            left -= 1
            right += 1
        return right - left - 1
    
    for i in range(len(s)):
        # Odd length palindromes
        len1 = expand_around_center(i, i)
        # Even length palindromes
        len2 = expand_around_center(i, i + 1)
        
        current_max = max(len1, len2)
        if current_max > max_len:
            max_len = current_max
            start = i - (current_max - 1) // 2
    
    return s[start:start + max_len]

def longest_palindrome_dp(s):
    n = len(s)
    if n == 0:
        return ""
    
    dp = [[False] * n for _ in range(n)]
    start = 0
    max_len = 1
    
    # Single characters are palindromes
    for i in range(n):
        dp[i][i] = True
    
    # Check for 2-character palindromes
    for i in range(n - 1):
        if s[i] == s[i + 1]:
            dp[i][i + 1] = True
            start = i
            max_len = 2
    
    # Check for palindromes of length 3 and more
    for length in range(3, n + 1):
        for i in range(n - length + 1):
            j = i + length - 1
            if s[i] == s[j] and dp[i + 1][j - 1]:
                dp[i][j] = True
                start = i
                max_len = length
    
    return s[start:start + max_len]
```

### 4. Trie (Prefix Tree)

```python
class TrieNode:
    def __init__(self):
        self.children = {}
        self.is_end_word = False
        self.word = None

class Trie:
    def __init__(self):
        self.root = TrieNode()
    
    def insert(self, word):
        node = self.root
        for char in word:
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]
        node.is_end_word = True
        node.word = word
    
    def search(self, word):
        node = self.root
        for char in word:
            if char not in node.children:
                return False
            node = node.children[char]
        return node.is_end_word
    
    def starts_with(self, prefix):
        node = self.root
        for char in prefix:
            if char not in node.children:
                return False
            node = node.children[char]
        return True
    
    def find_words_with_prefix(self, prefix):
        node = self.root
        # Navigate to prefix end
        for char in prefix:
            if char not in node.children:
                return []
            node = node.children[char]
        
        # DFS to find all words
        words = []
        def dfs(node):
            if node.is_end_word:
                words.append(node.word)
            for child in node.children.values():
                dfs(child)
        
        dfs(node)
        return words
```

---

## Edge Cases

### Critical Edge Cases
1. **Empty Strings**: Handle null and empty string inputs
2. **Single Character**: Special case for many algorithms
3. **All Same Characters**: "aaaa" - affects pattern matching
4. **Case Sensitivity**: 'A' vs 'a'
5. **Unicode Characters**: Multi-byte characters
6. **Very Long Strings**: Memory and performance concerns

### Algorithm-Specific Edge Cases
- **Pattern Matching**: Pattern longer than text
- **Palindromes**: Even vs odd length
- **DP Problems**: Empty string base cases

---

## Problem Categories

### 1. **String Matching**
- Find All Anagrams in String
- Implement strStr() (indexOf)
- Repeated Substring Pattern

### 2. **Palindromes**
- Valid Palindrome
- Longest Palindromic Substring
- Palindromic Substrings

### 3. **String Transformation**
- Edit Distance
- One Edit Distance
- String to Integer (atoi)

### 4. **Subsequence Problems**
- Longest Common Subsequence
- Is Subsequence
- Distinct Subsequences

### 5. **Sliding Window**
- Longest Substring Without Repeating
- Minimum Window Substring
- Permutation in String

---

## Pro Tips & Interview Tricks

### Problem Recognition
```
Substring Problems → Sliding Window
Pattern Matching → KMP or Rolling Hash
Edit Operations → Dynamic Programming
Palindrome Detection → Two Pointers or DP
Prefix/Suffix → Trie or Z-Algorithm
```

### Optimization Techniques

1. **Use StringBuilder**: For multiple concatenations
2. **Character Arrays**: When in-place modification needed
3. **Rolling Hash**: For fast substring comparison
4. **Two Pointers**: For palindrome and reversal problems

### Common Mistakes

1. **String Immutability**: Forgetting strings are immutable
2. **Off-by-One Errors**: String indexing mistakes
3. **Case Sensitivity**: Not handling case properly
4. **Empty String Handling**: Not checking for null/empty

### Interview-Specific Tips

1. **Clarify Requirements**:
   - Case sensitive?
   - ASCII or Unicode?
   - In-place modification allowed?

2. **Discuss Complexity**:
   - Time vs space trade-offs
   - Best vs average case

3. **Handle Edge Cases**:
   - Empty strings
   - Single characters
   - Very long strings

### Code Templates

#### Two Pointers Template
```python
def two_pointers_string(s):
    left, right = 0, len(s) - 1
    
    while left < right:
        if condition(s[left], s[right]):
            # Process and move both
            left += 1
            right -= 1
        elif should_move_left():
            left += 1
        else:
            right -= 1
```

#### Sliding Window Template
```python
def sliding_window_string(s):
    left = 0
    result = 0
    window_state = {}
    
    for right in range(len(s)):
        # Expand window
        char = s[right]
        window_state[char] = window_state.get(char, 0) + 1
        
        # Contract window if needed
        while not is_valid_window(window_state):
            left_char = s[left]
            window_state[left_char] -= 1
            if window_state[left_char] == 0:
                del window_state[left_char]
            left += 1
        
        # Update result
        result = max(result, right - left + 1)
    
    return result
```

---

## Conclusion

String algorithms are essential for text processing, pattern matching, and many real-world applications. Master these key concepts:

1. **Pattern Matching**: KMP for exact matching, rolling hash for efficiency
2. **Dynamic Programming**: Edit distance, LCS for transformation problems
3. **Two Pointers**: Palindromes and string reversal
4. **Sliding Window**: Substring optimization problems
5. **Trie**: Prefix-based operations and string storage

**Success Formula**: Pattern Recognition + Right Algorithm + Edge Case Handling = String Mastery

Practice these patterns and you'll handle most string problems with confidence!