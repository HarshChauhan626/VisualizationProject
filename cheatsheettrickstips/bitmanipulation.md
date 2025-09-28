# Bit Manipulation - Comprehensive Cheatsheet

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

### What is Bit Manipulation?

Bit manipulation is the act of algorithmically manipulating bits or other pieces of data shorter than a word. It involves using bitwise operations to perform calculations and solve problems at the binary level. Think of bit manipulation as working directly with the fundamental language of computers - the binary representation of data.

**Key Characteristics:**
- **Binary Foundation**: All operations work at the bit level (0s and 1s)
- **High Performance**: Direct hardware operations, extremely fast
- **Memory Efficient**: Can pack multiple boolean values into single integers
- **Mathematical Elegance**: Many problems have beautiful bit-based solutions
- **Universal Application**: Works across all programming languages and platforms

### Real-World Analogies

1. **Light Switches**: Each bit is like a light switch - it can be either ON (1) or OFF (0)
2. **Binary Combination Lock**: Each position has two states, and the combination represents a number
3. **Boolean Flags**: Like checkboxes on a form where each checkbox represents a different option
4. **Traffic Light States**: Though more complex, you could represent all combinations with bits

### Binary Number System Fundamentals

**Positional Notation:**
In binary, each position represents a power of 2:
```
Binary: 1 1 0 1 0 1
Powers: 2^5 2^4 2^3 2^2 2^1 2^0
Values: 32  16  8   4   2   1
Result: 32 + 16 + 0 + 4 + 0 + 1 = 53 (decimal)
```

**Two's Complement System:**
Most systems use two's complement for signed integers:
- Positive numbers: Standard binary representation
- Negative numbers: Flip all bits and add 1

```
+5 in 8-bit: 0000 0101
-5 in 8-bit: 1111 1011 (flip bits: 1111 1010, add 1: 1111 1011)
```

### Memory Representation

**Bit Layout in Memory:**
```
32-bit Integer: 42
Binary: 00000000 00000000 00000000 00101010
Bit #:  31...24  23...16  15...8   7...0

Each bit position i has value: bit_i × 2^i
```

**Endianness Considerations:**
- **Big Endian**: Most significant byte first (network byte order)
- **Little Endian**: Least significant byte first (most x86 systems)

### Historical Context and Importance

Bit manipulation has been fundamental since the earliest computers:

**Timeline:**
- **1940s**: Boolean algebra formalized by George Boole
- **1950s**: First computer logic circuits implemented Boolean operations
- **1960s**: Assembly language programming heavily used bit operations
- **1970s**: C language made bit operations accessible to higher-level programming
- **1980s**: Microprocessors optimized bitwise operations for performance
- **1990s**: Cryptographic algorithms extensively used bit manipulation
- **2000s**: Graphics programming and game development leveraged bit tricks
- **2010s**: Big data and high-frequency trading used bit manipulation for optimization

**Modern Applications:**
- Graphics and game programming (color manipulation, collision detection)
- Cryptography and security (encryption algorithms, hash functions)
- Database indexing (bitmap indexes, bloom filters)
- Network programming (IP address manipulation, protocol headers)
- Embedded systems (GPIO control, register manipulation)
- Compression algorithms (Huffman coding, LZ compression)

---

## Key Properties & Rules

### Fundamental Bitwise Operations

#### 1. **AND Operation (&)**
- Result bit is 1 only if both input bits are 1
- Commonly used for masking and clearing bits

**Truth Table:**
```
A | B | A & B
0 | 0 |   0
0 | 1 |   0
1 | 0 |   0
1 | 1 |   1
```

**Properties:**
- **Commutative**: `a & b = b & a`
- **Associative**: `(a & b) & c = a & (b & c)`
- **Identity**: `a & 1 = a`, `a & 0 = 0`
- **Idempotent**: `a & a = a`

#### 2. **OR Operation (|)**
- Result bit is 1 if at least one input bit is 1
- Commonly used for setting bits

**Truth Table:**
```
A | B | A | B
0 | 0 |   0
0 | 1 |   1
1 | 0 |   1
1 | 1 |   1
```

**Properties:**
- **Commutative**: `a | b = b | a`
- **Associative**: `(a | b) | c = a | (b | c)`
- **Identity**: `a | 0 = a`, `a | 1 = 1`
- **Idempotent**: `a | a = a`

#### 3. **XOR Operation (^)**
- Result bit is 1 if input bits are different
- Extremely useful for toggling and finding unique elements

**Truth Table:**
```
A | B | A ^ B
0 | 0 |   0
0 | 1 |   1
1 | 0 |   1
1 | 1 |   0
```

**Properties:**
- **Commutative**: `a ^ b = b ^ a`
- **Associative**: `(a ^ b) ^ c = a ^ (b ^ c)`
- **Identity**: `a ^ 0 = a`
- **Self-Inverse**: `a ^ a = 0`
- **Cancellation**: `a ^ b ^ b = a`

#### 4. **NOT Operation (~)**
- Flips all bits (1s become 0s, 0s become 1s)
- Also called bitwise complement

```
~0101 = 1010 (in 4-bit representation)
```

#### 5. **Left Shift (<<)**
- Shifts bits to the left, filling with zeros on the right
- Equivalent to multiplication by powers of 2

```
5 << 2:
Original: 0101 (5)
Result:   10100 (20)  // 5 × 2^2 = 20
```

#### 6. **Right Shift (>>)**
- Shifts bits to the right
- **Logical Right Shift**: Fills with zeros (unsigned)
- **Arithmetic Right Shift**: Fills with sign bit (signed)

```
20 >> 2:
Original: 10100 (20)
Result:   00101 (5)   // 20 ÷ 2^2 = 5
```

### Mathematical Properties and Laws

#### De Morgan's Laws
Essential for logical reasoning with bits:
- `~(a & b) = ~a | ~b`
- `~(a | b) = ~a & ~b`

#### Distributive Laws
- `a & (b | c) = (a & b) | (a & c)`
- `a | (b & c) = (a | b) & (a | c)`

#### Absorption Laws
- `a & (a | b) = a`
- `a | (a & b) = a`

#### XOR Properties
- **Cancellation**: `a ^ a = 0`
- **Identity**: `a ^ 0 = a`
- **Commutativity**: Order doesn't matter in XOR chains
- **Association**: Grouping doesn't matter in XOR chains

### Binary Arithmetic Rules

#### Addition Without Carry
XOR operation performs addition without carry:
```
  1 0 1 1  (11)
^ 0 1 1 0  (6)
---------
  1 1 0 1  (13, but this is XOR, not true addition)
```

#### Carry Generation
AND operation generates carry bits:
```
  1 0 1 1  (11)
& 0 1 1 0  (6)
---------
  0 0 1 0  (carry bits)
```

#### Full Addition Algorithm
```python
def add_without_operator(a, b):
    while b != 0:
        carry = a & b       # Calculate carry
        a = a ^ b          # Sum without carry
        b = carry << 1     # Shift carry left
    return a
```

### Sign Extension Rules

When extending the width of signed numbers:
- **Positive numbers**: Pad with zeros on the left
- **Negative numbers**: Pad with ones on the left (sign extension)

```
8-bit:  1111 1100 (-4)
16-bit: 1111 1111 1111 1100 (-4)
```

### Overflow and Underflow

#### Unsigned Overflow
```
255 + 1 = 0 (in 8-bit unsigned)
11111111 + 1 = 100000000 → 00000000 (overflow bit discarded)
```

#### Signed Overflow
```
127 + 1 = -128 (in 8-bit signed two's complement)
01111111 + 1 = 10000000 (-128)
```

---

## Patterns & Use Cases

### Core Bit Manipulation Patterns

#### 1. **Bit Masking**

**When to Use:**
- Extracting specific bits from a number
- Setting or clearing specific bits
- Working with flags and permissions
- Implementing bit sets

**Pattern Recognition:**
- Need to isolate certain bit positions
- Working with boolean flags packed into integers
- Implementing permission systems
- Optimizing space by packing multiple values

**Common Masks:**
```python
# Single bit masks
MASK_BIT_0 = 1      # 0000 0001
MASK_BIT_3 = 8      # 0000 1000
MASK_BIT_7 = 128    # 1000 0000

# Range masks
LOWER_4_BITS = 15   # 0000 1111
UPPER_4_BITS = 240  # 1111 0000
ALL_BITS = 255      # 1111 1111
```

**Operations:**
```python
# Check if bit i is set
def is_bit_set(num, i):
    return (num & (1 << i)) != 0

# Set bit i
def set_bit(num, i):
    return num | (1 << i)

# Clear bit i
def clear_bit(num, i):
    return num & ~(1 << i)

# Toggle bit i
def toggle_bit(num, i):
    return num ^ (1 << i)
```

#### 2. **Power of Two Detection**

**When to Use:**
- Validating array sizes for algorithms requiring power-of-2
- Hash table implementations
- Memory allocation alignment
- Binary tree level calculations

**Key Insight:**
A number is a power of 2 if and only if it has exactly one bit set.

**Algorithms:**
```python
# Method 1: Brian Kernighan's algorithm
def is_power_of_two_v1(n):
    return n > 0 and (n & (n - 1)) == 0

# Method 2: Using bit count
def is_power_of_two_v2(n):
    return n > 0 and bin(n).count('1') == 1

# Method 3: Mathematical approach
def is_power_of_two_v3(n):
    return n > 0 and (n & -n) == n
```

**Mathematical Proof:**
For any power of 2: `n = 2^k`
- Binary representation: `1000...0` (one 1 followed by k zeros)
- `n - 1 = 2^k - 1`: `0111...1` (k ones)
- `n & (n - 1) = 1000...0 & 0111...1 = 0000...0 = 0`

#### 3. **Bit Counting (Population Count)**

**When to Use:**
- Calculating Hamming distance between numbers
- Implementing sparse data structures
- Counting set flags in bitmasks
- Genetic algorithms and error correction

**Algorithms:**

**Brian Kernighan's Algorithm:**
```python
def count_set_bits_kernighan(n):
    count = 0
    while n:
        n &= n - 1  # Remove the lowest set bit
        count += 1
    return count
```

**Lookup Table Method:**
```python
def count_set_bits_lookup(n):
    # Precomputed lookup table for 8-bit values
    lookup = [0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4, ...]
    count = 0
    while n:
        count += lookup[n & 0xFF]  # Process 8 bits at a time
        n >>= 8
    return count
```

**Parallel Bit Counting (SWAR):**
```python
def count_set_bits_parallel(n):
    # For 32-bit integers
    n = n - ((n >> 1) & 0x55555555)
    n = (n & 0x33333333) + ((n >> 2) & 0x33333333)
    n = ((n + (n >> 4)) & 0x0F0F0F0F)
    n = n + (n >> 8)
    n = n + (n >> 16)
    return n & 0x3F
```

#### 4. **XOR Swap and Unique Element Finding**

**When to Use:**
- Finding elements that appear odd number of times
- Swapping variables without temporary storage
- Implementing simple encryption/decryption
- Array difference problems

**XOR Swap:**
```python
def xor_swap(a, b):
    if a != b:  # Avoid swapping same memory location
        a ^= b
        b ^= a
        a ^= b
    return a, b
```

**Find Single Number:**
```python
def find_single_number(nums):
    """Find the number that appears odd number of times"""
    result = 0
    for num in nums:
        result ^= num
    return result
```

**Find Two Single Numbers:**
```python
def find_two_single_numbers(nums):
    """Find two numbers that appear once while others appear twice"""
    xor_all = 0
    for num in nums:
        xor_all ^= num
    
    # Find rightmost set bit in xor_all
    rightmost_set_bit = xor_all & -xor_all
    
    # Divide numbers into two groups and XOR separately
    group1 = group2 = 0
    for num in nums:
        if num & rightmost_set_bit:
            group1 ^= num
        else:
            group2 ^= num
    
    return [group1, group2]
```

#### 5. **Bit Reversal and Rotation**

**When to Use:**
- Implementing certain cryptographic algorithms
- Bit-reversal permutations in FFT algorithms
- Endianness conversion
- Graphics programming (pixel manipulation)

**Bit Reversal:**
```python
def reverse_bits_32(n):
    """Reverse bits in a 32-bit integer"""
    result = 0
    for i in range(32):
        if n & (1 << i):
            result |= 1 << (31 - i)
    return result

def reverse_bits_optimized(n):
    """Optimized bit reversal using lookup and divide-and-conquer"""
    n = ((n & 0xAAAAAAAA) >> 1) | ((n & 0x55555555) << 1)
    n = ((n & 0xCCCCCCCC) >> 2) | ((n & 0x33333333) << 2)
    n = ((n & 0xF0F0F0F0) >> 4) | ((n & 0x0F0F0F0F) << 4)
    n = ((n & 0xFF00FF00) >> 8) | ((n & 0x00FF00FF) << 8)
    n = (n >> 16) | (n << 16)
    return n & 0xFFFFFFFF
```

**Bit Rotation:**
```python
def rotate_left(n, d, bits=32):
    """Rotate n left by d positions"""
    d %= bits
    return ((n << d) | (n >> (bits - d))) & ((1 << bits) - 1)

def rotate_right(n, d, bits=32):
    """Rotate n right by d positions"""
    d %= bits
    return ((n >> d) | (n << (bits - d))) & ((1 << bits) - 1)
```

#### 6. **Gray Code Generation**

**When to Use:**
- Solving Tower of Hanoi problems
- Error correction in digital communications
- Implementing rotary encoders
- Genetic algorithms with minimal mutation

**Gray Code Properties:**
- Consecutive numbers differ by exactly one bit
- Cyclic: last number differs from first by one bit
- Reflective: second half is reverse of first half with MSB flipped

**Generation Algorithm:**
```python
def generate_gray_code(n):
    """Generate n-bit Gray code sequence"""
    if n == 0:
        return [0]
    
    # Recursive approach
    prev_gray = generate_gray_code(n - 1)
    result = []
    
    # First half: prefix with 0
    for code in prev_gray:
        result.append(code)
    
    # Second half: prefix with 1 and reverse order
    for code in reversed(prev_gray):
        result.append(code | (1 << (n - 1)))
    
    return result

def binary_to_gray(n):
    """Convert binary to Gray code"""
    return n ^ (n >> 1)

def gray_to_binary(n):
    """Convert Gray code to binary"""
    while n:
        n >>= 1
        binary ^= n
    return binary
```

### Advanced Patterns

#### 7. **Subset Generation using Bitmasks**

**When to Use:**
- Generating all possible combinations
- Dynamic programming on subsets
- Implementing powerset operations
- Solving optimization problems with small state spaces

**Algorithm:**
```python
def generate_all_subsets(arr):
    """Generate all subsets using bitmasks"""
    n = len(arr)
    subsets = []
    
    # 2^n possible subsets
    for mask in range(1 << n):
        subset = []
        for i in range(n):
            if mask & (1 << i):
                subset.append(arr[i])
        subsets.append(subset)
    
    return subsets

def next_subset(mask, superset_mask):
    """Generate next subset of a given superset"""
    return (mask - superset_mask) & superset_mask
```

#### 8. **Bit Field Implementation**

**When to Use:**
- Implementing efficient data structures
- System programming (register manipulation)
- Network protocol implementations
- Compiler optimization flags

**Example Implementation:**
```python
class BitField:
    def __init__(self, size):
        self.size = size
        self.data = [0] * ((size + 31) // 32)  # Use 32-bit chunks
    
    def set_bit(self, pos):
        if 0 <= pos < self.size:
            chunk = pos // 32
            bit = pos % 32
            self.data[chunk] |= (1 << bit)
    
    def clear_bit(self, pos):
        if 0 <= pos < self.size:
            chunk = pos // 32
            bit = pos % 32
            self.data[chunk] &= ~(1 << bit)
    
    def get_bit(self, pos):
        if 0 <= pos < self.size:
            chunk = pos // 32
            bit = pos % 32
            return bool(self.data[chunk] & (1 << bit))
        return False
    
    def count_set_bits(self):
        count = 0
        for chunk in self.data:
            count += bin(chunk).count('1')
        return count
```

---

## Step-by-Step Approaches

### General Problem-Solving Framework

#### Step 1: **Problem Analysis**
1. **Identify the bit manipulation nature**:
   - Are we working with individual bits?
   - Do we need to find patterns in binary representation?
   - Is there a mathematical property we can exploit?

2. **Determine the bit width**:
   - 32-bit integers? 64-bit?
   - Fixed-width requirements?
   - Sign considerations?

3. **Identify key operations needed**:
   - Setting/clearing/toggling bits?
   - Counting bits?
   - Finding patterns?
   - Mathematical computations?

#### Step 2: **Choose the Right Tools**
Based on problem characteristics:

**For Bit Counting Problems:**
- Brian Kernighan's algorithm for sparse bit patterns
- Lookup tables for repeated operations
- Built-in population count for performance

**For Set Operations:**
- Bitmasks for subset problems
- XOR for finding unique elements
- AND/OR for set intersections/unions

**For Mathematical Problems:**
- Bit shifts for multiplication/division by powers of 2
- XOR properties for addition without carry
- Two's complement for sign handling

#### Step 3: **Implementation Strategy**

**Template for Bit Manipulation Problems:**
```python
def solve_bit_problem(input_data):
    # Step 1: Handle edge cases
    if not input_data:
        return default_result
    
    # Step 2: Initialize variables
    result = 0
    mask = 1
    
    # Step 3: Process bit by bit or use mathematical properties
    while condition:
        # Core bit manipulation logic
        if some_condition:
            result |= mask  # Set bit
        else:
            result &= ~mask  # Clear bit
        
        mask <<= 1  # Move to next bit
    
    # Step 4: Handle final result transformation
    return transform_result(result)
```

### Specific Approach Patterns

#### Approach 1: **Bit-by-Bit Processing**

**When to Use:**
- When you need to examine each bit position individually
- When the problem requires bit-level transformations
- When working with custom bit patterns

**Steps:**
1. Initialize bit position counter
2. Create appropriate bitmask (usually `1 << i`)
3. Test/modify bit at current position
4. Update result based on bit state
5. Move to next bit position
6. Repeat until all bits processed

**Example: Count Set Bits**
```python
def count_set_bits_iterative(n):
    count = 0
    position = 0
    
    while n > 0:
        if n & 1:  # Check least significant bit
            count += 1
        n >>= 1    # Shift right to process next bit
        position += 1
    
    return count
```

#### Approach 2: **Mathematical Property Exploitation**

**When to Use:**
- When there's a mathematical relationship in bit patterns
- When you can use bit arithmetic instead of traditional arithmetic
- When leveraging properties like XOR cancellation or power-of-2 detection

**Steps:**
1. Identify mathematical properties in the problem
2. Look for bit patterns that can be exploited
3. Use algebraic properties of bitwise operations
4. Optimize using mathematical insights

**Example: Power of Two Check**
```python
def is_power_of_two(n):
    # Mathematical insight: power of 2 has exactly one bit set
    # n & (n-1) clears the lowest set bit
    return n > 0 and (n & (n - 1)) == 0
```

#### Approach 3: **Divide and Conquer with Bits**

**When to Use:**
- When processing large bit patterns
- When you can break the problem into smaller subproblems
- When implementing parallel algorithms

**Steps:**
1. Divide the bit pattern into smaller chunks
2. Process each chunk independently
3. Combine results using bitwise operations
4. Optimize by processing multiple bits simultaneously

**Example: Parallel Bit Count**
```python
def parallel_bit_count(n):
    # Process pairs of bits
    n = n - ((n >> 1) & 0x55555555)
    # Process nibbles (4-bit groups)
    n = (n & 0x33333333) + ((n >> 2) & 0x33333333)
    # Process bytes
    n = ((n + (n >> 4)) & 0x0F0F0F0F)
    # Final summation
    n = n + (n >> 8)
    n = n + (n >> 16)
    return n & 0x3F
```

#### Approach 4: **State Machine with Bit Tracking**

**When to Use:**
- When the problem involves tracking multiple states
- When implementing finite state machines
- When dealing with complex bit patterns

**Steps:**
1. Define all possible states as bit patterns
2. Create transition logic using bitwise operations
3. Track current state and update based on input
4. Extract final result from state

**Example: Single Number III (Finding Two Unique Numbers)**
```python
def find_two_unique(nums):
    # Step 1: XOR all numbers to get xor of the two unique numbers
    xor_result = 0
    for num in nums:
        xor_result ^= num
    
    # Step 2: Find a bit that differs between the two numbers
    rightmost_set_bit = xor_result & (-xor_result)
    
    # Step 3: Partition numbers based on this bit
    num1 = num2 = 0
    for num in nums:
        if num & rightmost_set_bit:
            num1 ^= num
        else:
            num2 ^= num
    
    return [num1, num2]
```

---

## Common Algorithms

### Fundamental Bit Manipulation Algorithms

#### 1. **Brian Kernighan's Algorithm**

**Purpose**: Efficiently count set bits by clearing them one by one

**Algorithm:**
```python
def kernighan_count_bits(n):
    count = 0
    while n:
        n &= n - 1  # Clear the lowest set bit
        count += 1
    return count
```

**How it Works:**
- `n - 1` flips all bits after and including the lowest set bit
- `n & (n - 1)` clears the lowest set bit
- Continue until all bits are cleared

**Example Trace:**
```
n = 12 (1100)
n - 1 = 11 (1011)
n & (n-1) = 8 (1000), count = 1

n = 8 (1000)
n - 1 = 7 (0111)
n & (n-1) = 0 (0000), count = 2
```

**Time Complexity**: O(number of set bits)
**Space Complexity**: O(1)

#### 2. **Fast Exponentiation using Bits**

**Purpose**: Compute a^b efficiently using binary representation of exponent

**Algorithm:**
```python
def fast_power(base, exponent):
    result = 1
    base = base % MOD  # If working with modular arithmetic
    
    while exponent > 0:
        # If exponent is odd, multiply base with result
        if exponent & 1:
            result = (result * base) % MOD
        
        # Square the base and halve the exponent
        exponent >>= 1
        base = (base * base) % MOD
    
    return result
```

**How it Works:**
Expresses exponent in binary and processes bit by bit:
```
a^13 = a^(8+4+1) = a^8 * a^4 * a^1
Binary of 13: 1101
Process bits from right to left
```

**Time Complexity**: O(log b)
**Space Complexity**: O(1)

#### 3. **Bit Reversal Algorithm**

**Purpose**: Reverse the order of bits in a number

**Simple Algorithm:**
```python
def reverse_bits_simple(n, bits=32):
    result = 0
    for i in range(bits):
        if n & (1 << i):
            result |= 1 << (bits - 1 - i)
    return result
```

**Optimized Algorithm (Divide and Conquer):**
```python
def reverse_bits_optimized(n):
    # Swap adjacent bits
    n = ((n & 0xAAAAAAAA) >> 1) | ((n & 0x55555555) << 1)
    # Swap adjacent pairs
    n = ((n & 0xCCCCCCCC) >> 2) | ((n & 0x33333333) << 2)
    # Swap adjacent nibbles
    n = ((n & 0xF0F0F0F0) >> 4) | ((n & 0x0F0F0F0F) << 4)
    # Swap adjacent bytes
    n = ((n & 0xFF00FF00) >> 8) | ((n & 0x00FF00FF) << 8)
    # Swap adjacent 16-bit chunks
    n = (n >> 16) | (n << 16)
    return n & 0xFFFFFFFF
```

**Time Complexity**: O(1) for optimized, O(bits) for simple
**Space Complexity**: O(1)

#### 4. **Gray Code Generation**

**Purpose**: Generate sequence where consecutive numbers differ by exactly one bit

**Recursive Algorithm:**
```python
def generate_gray_code(n):
    if n == 0:
        return ['0']
    if n == 1:
        return ['0', '1']
    
    # Get previous Gray code
    prev_gray = generate_gray_code(n - 1)
    result = []
    
    # Add '0' prefix to first half
    for code in prev_gray:
        result.append('0' + code)
    
    # Add '1' prefix to second half (reversed)
    for code in reversed(prev_gray):
        result.append('1' + code)
    
    return result
```

**Binary to Gray Conversion:**
```python
def binary_to_gray(n):
    return n ^ (n >> 1)

def gray_to_binary(gray):
    binary = gray
    while gray:
        gray >>= 1
        binary ^= gray
    return binary
```

#### 5. **Subset Sum using Bitmasks**

**Purpose**: Find all subsets that sum to a target value

**Algorithm:**
```python
def subset_sum_bitmask(arr, target):
    n = len(arr)
    solutions = []
    
    # Check all possible subsets (2^n)
    for mask in range(1 << n):
        current_sum = 0
        subset = []
        
        for i in range(n):
            if mask & (1 << i):
                current_sum += arr[i]
                subset.append(arr[i])
        
        if current_sum == target:
            solutions.append(subset)
    
    return solutions
```

**Optimized for DP:**
```python
def subset_sum_dp_bitmask(arr, target):
    n = len(arr)
    # dp[i] represents which sums are possible using first i elements
    dp = [0] * (n + 1)
    dp[0] = 1  # Empty subset sums to 0
    
    for i in range(n):
        # For each element, update possible sums
        dp[i + 1] = dp[i] | (dp[i] << arr[i])
    
    # Check if target sum is possible
    return bool(dp[n] & (1 << target))
```

#### 6. **Bitwise Sieve of Eratosthenes**

**Purpose**: Find all prime numbers up to n using bit manipulation

**Algorithm:**
```python
def bitwise_sieve(n):
    # Use bits to represent numbers (bit i represents number i)
    is_prime = (1 << (n + 1)) - 1  # All bits set initially
    is_prime &= ~3  # Clear bits for 0 and 1 (not prime)
    
    for i in range(2, int(n**0.5) + 1):
        if is_prime & (1 << i):  # If i is prime
            # Mark all multiples of i as composite
            for j in range(i * i, n + 1, i):
                is_prime &= ~(1 << j)
    
    primes = []
    for i in range(2, n + 1):
        if is_prime & (1 << i):
            primes.append(i)
    
    return primes
```

### Advanced Algorithms

#### 7. **Bit Manipulation in Graph Algorithms**

**Traveling Salesman Problem with Bitmask DP:**
```python
def tsp_bitmask(graph):
    n = len(graph)
    # dp[mask][i] = minimum cost to visit all cities in mask ending at city i
    dp = [[float('inf')] * n for _ in range(1 << n)]
    dp[1][0] = 0  # Start at city 0
    
    for mask in range(1 << n):
        for u in range(n):
            if not (mask & (1 << u)):
                continue
            
            for v in range(n):
                if mask & (1 << v):
                    continue
                
                new_mask = mask | (1 << v)
                dp[new_mask][v] = min(dp[new_mask][v], 
                                     dp[mask][u] + graph[u][v])
    
    # Find minimum cost to return to start
    result = float('inf')
    final_mask = (1 << n) - 1
    for i in range(1, n):
        result = min(result, dp[final_mask][i] + graph[i][0])
    
    return result
```

#### 8. **Bit Manipulation in Number Theory**

**Fast GCD using Binary GCD Algorithm:**
```python
def binary_gcd(a, b):
    if a == 0:
        return b
    if b == 0:
        return a
    
    # Count common factors of 2
    shift = 0
    while ((a | b) & 1) == 0:
        a >>= 1
        b >>= 1
        shift += 1
    
    # Remove factors of 2 from a
    while (a & 1) == 0:
        a >>= 1
    
    while b != 0:
        # Remove factors of 2 from b
        while (b & 1) == 0:
            b >>= 1
        
        # Ensure a <= b
        if a > b:
            a, b = b, a
        
        b -= a
    
    return a << shift
```

---

## Edge Cases

### Common Edge Cases in Bit Manipulation

#### 1. **Zero and Negative Numbers**

**Zero Handling:**
```python
# Many bit operations behave differently with zero
def safe_bit_operations(n):
    if n == 0:
        return handle_zero_case()
    
    # Example: Counting set bits
    if n == 0:
        return 0  # Zero has no set bits
    
    # Example: Finding rightmost set bit
    if n == 0:
        return 0  # Zero has no set bits
    
    return n & (-n)  # Normal case
```

**Negative Number Handling:**
```python
def handle_negative_bits(n):
    if n < 0:
        # In two's complement, negative numbers have many set bits
        # May need to handle differently based on problem
        if problem_type == "count_bits":
            # Use unsigned representation
            return count_bits(n & 0xFFFFFFFF)
        elif problem_type == "power_of_two":
            return False  # Negative numbers can't be powers of 2
    
    return normal_processing(n)
```

#### 2. **Integer Overflow**

**Overflow in Bit Shifts:**
```python
def safe_left_shift(n, shift):
    # Check for overflow before shifting
    if shift >= 32:  # For 32-bit integers
        return 0 if shift > 32 else n << (shift % 32)
    
    # Check if result would overflow
    if n > (0x7FFFFFFF >> shift):
        raise OverflowError("Shift would cause overflow")
    
    return n << shift

def safe_power_of_two_check(n):
    # Large numbers might overflow in calculations
    if n <= 0 or n > 0x80000000:  # 2^31
        return False
    
    return (n & (n - 1)) == 0
```

#### 3. **Bit Width Considerations**

**Different Integer Sizes:**
```python
def count_bits_universal(n, bit_width=32):
    """Count bits considering different integer widths"""
    if bit_width == 8:
        n &= 0xFF
    elif bit_width == 16:
        n &= 0xFFFF
    elif bit_width == 32:
        n &= 0xFFFFFFFF
    elif bit_width == 64:
        n &= 0xFFFFFFFFFFFFFFFF
    
    count = 0
    while n:
        n &= n - 1
        count += 1
    return count
```

#### 4. **Sign Extension Issues**

**Arithmetic vs Logical Right Shift:**
```python
def logical_right_shift(n, shift, bit_width=32):
    """Perform logical right shift (fill with zeros)"""
    # Create mask to clear sign bits
    mask = (1 << (bit_width - shift)) - 1
    return (n >> shift) & mask

def arithmetic_right_shift(n, shift):
    """Perform arithmetic right shift (fill with sign bit)"""
    # Python's >> is arithmetic for negative numbers
    return n >> shift
```

#### 5. **Endianness Sensitivity**

**Byte Order Issues:**
```python
def reverse_bytes(n):
    """Reverse byte order in a 32-bit integer"""
    return ((n & 0x000000FF) << 24) | \
           ((n & 0x0000FF00) << 8) | \
           ((n & 0x00FF0000) >> 8) | \
           ((n & 0xFF000000) >> 24)

def is_little_endian():
    """Check system endianness"""
    import sys
    return sys.byteorder == 'little'
```

#### 6. **Empty Input Handling**

**Array/List Edge Cases:**
```python
def find_single_number_safe(nums):
    """Find single number with edge case handling"""
    if not nums:
        raise ValueError("Empty array")
    
    if len(nums) == 1:
        return nums[0]
    
    if len(nums) % 2 == 0:
        raise ValueError("Even number of elements - no single number")
    
    result = 0
    for num in nums:
        result ^= num
    return result
```

#### 7. **Floating Point Bit Manipulation**

**IEEE 754 Considerations:**
```python
import struct

def float_to_bits(f):
    """Convert float to its bit representation"""
    return struct.unpack('>I', struct.pack('>f', f))[0]

def bits_to_float(bits):
    """Convert bit representation to float"""
    return struct.unpack('>f', struct.pack('>I', bits))[0]

def is_power_of_two_float(f):
    """Check if float is power of 2"""
    if f <= 0 or not math.isfinite(f):
        return False
    
    bits = float_to_bits(f)
    # IEEE 754: power of 2 has mantissa = 0
    mantissa = bits & 0x7FFFFF
    return mantissa == 0
```

### Testing Edge Cases

**Comprehensive Edge Case Testing:**
```python
def test_bit_manipulation_edge_cases():
    test_cases = [
        # Basic edge cases
        (0, "zero"),
        (1, "single bit"),
        (-1, "all bits set"),
        (0x7FFFFFFF, "max positive 32-bit"),
        (-0x80000000, "min negative 32-bit"),
        
        # Power of 2 edge cases
        (1, "2^0"),
        (0x40000000, "2^30"),
        (0x80000000, "2^31 - overflow case"),
        
        # Bit counting edge cases
        (0xAAAAAAAA, "alternating bits"),
        (0x55555555, "alternating bits inverse"),
        (0xFFFFFFFF, "all bits set"),
    ]
    
    for value, description in test_cases:
        print(f"Testing {description}: {value:08X}")
        test_all_operations(value)
```

---

## Complexity Analysis

### Time Complexity Analysis

#### **Bit-by-Bit Operations**

**Linear in Bit Width: O(w)**
Where w is the width of the integer (typically 32 or 64 bits)

```python
# Examples of O(w) operations:
def naive_bit_count(n):
    count = 0
    for i in range(32):  # O(32) = O(1) for fixed-width
        if n & (1 << i):
            count += 1
    return count

def reverse_bits(n):
    result = 0
    for i in range(32):  # O(32) = O(1)
        if n & (1 << i):
            result |= 1 << (31 - i)
    return result
```

**Note**: For fixed-width integers, O(w) is effectively O(1) since w is constant.

#### **Sparse Bit Operations**

**Linear in Number of Set Bits: O(s)**
Where s is the number of set bits

```python
# Brian Kernighan's algorithm: O(s)
def kernighan_count(n):
    count = 0
    while n:  # Runs s times where s = number of set bits
        n &= n - 1
        count += 1
    return count

# Finding all set bit positions: O(s)
def find_set_positions(n):
    positions = []
    pos = 0
    while n:
        if n & 1:
            positions.append(pos)
        n >>= 1
        pos += 1
    return positions
```

#### **Exponential Operations**

**Subset Generation: O(2^n)**
Where n is the number of elements

```python
# Generating all subsets: O(2^n)
def generate_subsets(arr):
    n = len(arr)
    subsets = []
    for mask in range(1 << n):  # 2^n iterations
        subset = []
        for i in range(n):  # O(n) per iteration
            if mask & (1 << i):
                subset.append(arr[i])
        subsets.append(subset)
    return subsets
# Total: O(n * 2^n)
```

#### **Logarithmic Operations**

**Binary Operations: O(log n)**
Where n is the value of the number

```python
# Fast exponentiation: O(log b)
def fast_power(a, b):
    result = 1
    while b > 0:  # Runs log(b) times
        if b & 1:
            result *= a
        a *= a
        b >>= 1
    return result

# Finding highest set bit: O(log n)
def highest_set_bit(n):
    pos = 0
    while n > 1:  # Runs log(n) times
        n >>= 1
        pos += 1
    return pos
```

### Space Complexity Analysis

#### **Constant Space: O(1)**
Most basic bit operations use constant space:

```python
# All these operations use O(1) space:
def basic_operations(n):
    count = bin(n).count('1')  # O(1) space
    reversed_n = reverse_bits(n)  # O(1) space
    is_power = (n & (n - 1)) == 0  # O(1) space
    return count, reversed_n, is_power
```

#### **Linear Space: O(n)**
When storing results or using auxiliary data structures:

```python
# Storing all subsets: O(n * 2^n) space
def store_all_subsets(arr):
    n = len(arr)
    subsets = []
    for mask in range(1 << n):
        subset = []
        for i in range(n):
            if mask & (1 << i):
                subset.append(arr[i])  # O(n) per subset
        subsets.append(subset)
    return subsets  # O(n * 2^n) total space

# Bit array: O(n) space
def create_bit_array(n):
    return [0] * ((n + 31) // 32)  # O(n/32) = O(n) space
```

#### **Lookup Table Space: O(2^k)**
For precomputed lookup tables:

```python
# Precomputed bit counts for 8-bit values: O(256) = O(1) space
BIT_COUNT_TABLE = [bin(i).count('1') for i in range(256)]

def fast_bit_count(n):
    return (BIT_COUNT_TABLE[n & 0xFF] +
            BIT_COUNT_TABLE[(n >> 8) & 0xFF] +
            BIT_COUNT_TABLE[(n >> 16) & 0xFF] +
            BIT_COUNT_TABLE[(n >> 24) & 0xFF])
```

### Complexity Comparison Table

| Algorithm | Time Complexity | Space Complexity | Best Use Case |
|-----------|----------------|------------------|---------------|
| Naive bit count | O(w) | O(1) | Simple, readable code |
| Kernighan count | O(s) | O(1) | Sparse bit patterns |
| Lookup table count | O(1) | O(2^k) | Repeated operations |
| Parallel bit count | O(1) | O(1) | High-performance needs |
| Subset generation | O(n*2^n) | O(n*2^n) | Small sets only |
| Fast exponentiation | O(log b) | O(1) | Large exponents |
| Bit reversal (naive) | O(w) | O(1) | Simple cases |
| Bit reversal (parallel) | O(1) | O(1) | Performance critical |

### Amortized Analysis

**Dynamic Bit Arrays:**
When implementing growable bit arrays, operations have amortized complexity:

```python
class DynamicBitArray:
    def __init__(self):
        self.data = [0]
        self.size = 32
        self.used = 0
    
    def set_bit(self, pos):
        if pos >= self.size:
            # Amortized O(1) - occasional O(n) for resizing
            self._resize(pos + 1)
        
        chunk = pos // 32
        bit = pos % 32
        self.data[chunk] |= (1 << bit)
        self.used = max(self.used, pos + 1)
    
    def _resize(self, new_size):
        # Doubling strategy gives amortized O(1)
        while self.size < new_size:
            self.data.extend([0] * len(self.data))
            self.size *= 2
```

---

## Example Problems

### Problem 1: **Single Number**

**Problem Statement:**
Given a non-empty array of integers where every element appears twice except for one, find that single element.

**Example:**
```
Input: [2,2,1]
Output: 1

Input: [4,1,2,1,2]
Output: 4
```

**Solution:**
```python
def single_number(nums):
    """
    Use XOR property: a ^ a = 0, a ^ 0 = a
    All paired numbers cancel out, leaving only the single number
    """
    result = 0
    for num in nums:
        result ^= num
    return result

# Mathematical proof:
# [4,1,2,1,2] -> 4^1^2^1^2 -> 4^(1^1)^(2^2) -> 4^0^0 -> 4
```

**Time Complexity:** O(n)
**Space Complexity:** O(1)

### Problem 2: **Number of 1 Bits (Hamming Weight)**

**Problem Statement:**
Write a function that takes an unsigned integer and returns the number of '1' bits it has.

**Example:**
```
Input: 11 (binary: 1011)
Output: 3

Input: 128 (binary: 10000000)
Output: 1
```

**Multiple Solutions:**

```python
# Solution 1: Simple bit checking
def hamming_weight_v1(n):
    count = 0
    while n:
        count += n & 1
        n >>= 1
    return count

# Solution 2: Brian Kernighan's algorithm
def hamming_weight_v2(n):
    count = 0
    while n:
        n &= n - 1  # Remove lowest set bit
        count += 1
    return count

# Solution 3: Built-in function
def hamming_weight_v3(n):
    return bin(n).count('1')

# Solution 4: Lookup table
POPCOUNT_TABLE = [bin(i).count('1') for i in range(256)]

def hamming_weight_v4(n):
    return (POPCOUNT_TABLE[n & 0xFF] +
            POPCOUNT_TABLE[(n >> 8) & 0xFF] +
            POPCOUNT_TABLE[(n >> 16) & 0xFF] +
            POPCOUNT_TABLE[(n >> 24) & 0xFF])
```

### Problem 3: **Power of Two**

**Problem Statement:**
Given an integer n, return true if it is a power of two. Otherwise, return false.

**Example:**
```
Input: 1
Output: true (2^0 = 1)

Input: 16
Output: true (2^4 = 16)

Input: 3
Output: false
```

**Solution with Analysis:**
```python
def is_power_of_two(n):
    """
    A power of 2 has exactly one bit set in binary representation.
    Key insight: n & (n-1) removes the lowest set bit.
    If n is power of 2, this results in 0.
    """
    return n > 0 and (n & (n - 1)) == 0

# Alternative approaches:
def is_power_of_two_v2(n):
    # Using bit count
    return n > 0 and bin(n).count('1') == 1

def is_power_of_two_v3(n):
    # Using rightmost set bit isolation
    return n > 0 and (n & -n) == n

# Verification examples:
# n = 8 (1000), n-1 = 7 (0111), n & (n-1) = 0000 -> True
# n = 6 (0110), n-1 = 5 (0101), n & (n-1) = 0100 -> False
```

### Problem 4: **Missing Number**

**Problem Statement:**
Given an array containing n distinct numbers taken from 0, 1, 2, ..., n, find the one that is missing.

**Example:**
```
Input: [3,0,1]
Output: 2

Input: [0,1]
Output: 2
```

**Bit Manipulation Solution:**
```python
def missing_number(nums):
    """
    XOR all numbers from 0 to n with all numbers in array.
    Missing number will remain after cancellation.
    """
    n = len(nums)
    result = n  # Start with n (the maximum expected number)
    
    for i, num in enumerate(nums):
        result ^= i ^ num  # XOR with both index and value
    
    return result

# Mathematical explanation:
# Expected: 0^1^2^3 = X
# Actual (missing 2): 0^1^3 = Y
# Missing number: X^Y = (0^1^2^3)^(0^1^3) = 2
```

---

## Problem Categories

### Category 1: **XOR-Based Problems**

**Common Patterns:**
- Finding unique elements
- Canceling paired elements
- Bit difference calculations

**Representative Problems:**
1. **Single Number** - Find element appearing once
2. **Missing Number** - Find missing element in sequence
3. **Find the Difference** - Find added character between strings

### Category 2: **Bit Counting Problems**

**Common Patterns:**
- Count number of set bits
- Find positions of set bits
- Compare bit counts between numbers

**Representative Problems:**
1. **Hamming Weight** - Count 1s in binary representation
2. **Hamming Distance** - Count differing bits between two numbers
3. **Counting Bits** - Count bits for all numbers 0 to n

### Category 3: **Power of Two Problems**

**Common Patterns:**
- Detecting powers of 2
- Working with binary tree levels
- Hash table sizing

**Representative Problems:**
1. **Power of Two** - Check if number is power of 2
2. **Power of Four** - Check if number is power of 4
3. **Smallest Power of 2** - Find smallest power of 2 ≥ n

---

## Pro Tips & Interview Tricks

### Essential Interview Insights

#### 1. **Recognize Bit Manipulation Opportunities**

**Key Indicators:**
- Problem mentions "unique", "single", "missing", or "duplicate"
- Working with boolean flags or sets
- Need to optimize space (packing multiple values)
- Mathematical operations can be replaced with bit operations
- Problem involves powers of 2

#### 2. **Master the Core Tricks**

**Trick 1: Remove Lowest Set Bit**
```python
# n & (n-1) removes the lowest set bit
n = 12  # 1100
n & (n-1)  # 1100 & 1011 = 1000 (8)

# Applications:
def is_power_of_two(n):
    return n > 0 and (n & (n-1)) == 0

def count_set_bits(n):
    count = 0
    while n:
        n &= n-1
        count += 1
    return count
```

**Trick 2: Isolate Lowest Set Bit**
```python
# n & (-n) isolates the lowest set bit
n = 12  # 1100
n & (-n)  # 1100 & ...10100 = 0100 (4)

# Applications:
def find_lowest_set_bit_position(n):
    return (n & (-n)).bit_length() - 1
```

**Trick 3: XOR Properties**
```python
# XOR properties: a^a = 0, a^0 = a, XOR is commutative
def find_single_number(nums):
    result = 0
    for num in nums:
        result ^= num
    return result
```

#### 3. **Quick Reference Formulas**

```python
# Check if bit i is set
if n & (1 << i):
    print(f"Bit {i} is set")

# Set bit i
n |= (1 << i)

# Clear bit i
n &= ~(1 << i)

# Toggle bit i
n ^= (1 << i)

# Check if power of 2
if n > 0 and (n & (n-1)) == 0:
    print("Power of 2")

# Count set bits (Brian Kernighan)
count = 0
while n:
    n &= n-1
    count += 1

# Swap two numbers without temp
a ^= b
b ^= a
a ^= b
```

#### 4. **Common Patterns Recognition**

**Pattern: Single Element in Pairs**
```python
# When all elements appear twice except one
result = 0
for num in nums:
    result ^= num
return result
```

**Pattern: Generate All Subsets**
```python
# Use bitmask to represent subset membership
for mask in range(1 << n):
    subset = []
    for i in range(n):
        if mask & (1 << i):
            subset.append(arr[i])
    process(subset)
```

**Pattern: Fast Mathematical Operations**
```python
# Multiply/divide by powers of 2
result = n << k  # n * (2^k)
result = n >> k  # n // (2^k)

# Check even/odd
if n & 1:  # odd
else:      # even
```

### Final Success Tips

1. **Always consider edge cases**: zero, negative numbers, overflow
2. **Think about bit width**: 32-bit vs 64-bit implications
3. **Use built-in functions when available**: `bin()`, `bit_length()`, etc.
4. **Practice bit visualization**: convert between decimal and binary mentally
5. **Know your language specifics**: Python's arbitrary precision vs C++'s fixed width
6. **Master the fundamental operations**: AND, OR, XOR, NOT, shifts
7. **Recognize mathematical properties**: use algebra to simplify bit operations

This comprehensive guide provides the foundation for mastering bit manipulation in interviews and competitive programming. Practice these patterns, understand the underlying mathematics, and you'll be equipped to tackle any bit manipulation challenge efficiently!