# Mathematics Algorithms - Comprehensive Cheatsheet

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

### What are Mathematical Algorithms?

Mathematical algorithms are computational procedures that solve problems using mathematical concepts, including number theory, combinatorics, probability, and numerical methods. These algorithms form the foundation of computer science and enable efficient solutions to complex mathematical problems.

**Key Areas:**
- **Number Theory**: Primes, GCD, modular arithmetic
- **Combinatorics**: Permutations, combinations, counting
- **Linear Algebra**: Matrix operations, systems of equations
- **Probability**: Random algorithms, statistical methods
- **Numerical Methods**: Root finding, optimization

---

## Key Properties & Rules

### Number Theory Fundamentals

#### 1. **Greatest Common Divisor (GCD)**
**Euclidean Algorithm:**
```python
def gcd(a, b):
    while b:
        a, b = b, a % b
    return a

def extended_gcd(a, b):
    if a == 0:
        return b, 0, 1
    gcd, x1, y1 = extended_gcd(b % a, a)
    x = y1 - (b // a) * x1
    y = x1
    return gcd, x, y
```

#### 2. **Prime Numbers**
**Sieve of Eratosthenes:**
```python
def sieve_of_eratosthenes(n):
    is_prime = [True] * (n + 1)
    is_prime[0] = is_prime[1] = False
    
    for i in range(2, int(n**0.5) + 1):
        if is_prime[i]:
            for j in range(i*i, n + 1, i):
                is_prime[j] = False
    
    return [i for i in range(2, n + 1) if is_prime[i]]

def is_prime(n):
    if n < 2:
        return False
    if n == 2:
        return True
    if n % 2 == 0:
        return False
    
    for i in range(3, int(n**0.5) + 1, 2):
        if n % i == 0:
            return False
    return True
```

#### 3. **Modular Arithmetic**
```python
def mod_pow(base, exp, mod):
    """Fast modular exponentiation"""
    result = 1
    base = base % mod
    
    while exp > 0:
        if exp % 2 == 1:
            result = (result * base) % mod
        exp = exp >> 1
        base = (base * base) % mod
    
    return result

def mod_inverse(a, m):
    """Modular multiplicative inverse"""
    def extended_gcd(a, b):
        if a == 0:
            return b, 0, 1
        gcd, x1, y1 = extended_gcd(b % a, a)
        x = y1 - (b // a) * x1
        y = x1
        return gcd, x, y
    
    gcd, x, _ = extended_gcd(a, m)
    if gcd != 1:
        return None  # Inverse doesn't exist
    return (x % m + m) % m
```

### Combinatorics

#### 1. **Factorials and Combinations**
```python
def factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)

def combination(n, r):
    if r > n or r < 0:
        return 0
    if r == 0 or r == n:
        return 1
    
    r = min(r, n - r)  # Take advantage of symmetry
    result = 1
    for i in range(r):
        result = result * (n - i) // (i + 1)
    return result

def permutation(n, r):
    if r > n or r < 0:
        return 0
    result = 1
    for i in range(n, n - r, -1):
        result *= i
    return result
```

#### 2. **Catalan Numbers**
```python
def catalan_number(n):
    """nth Catalan number using dynamic programming"""
    if n <= 1:
        return 1
    
    catalan = [0] * (n + 1)
    catalan[0] = catalan[1] = 1
    
    for i in range(2, n + 1):
        for j in range(i):
            catalan[i] += catalan[j] * catalan[i - 1 - j]
    
    return catalan[n]

def catalan_formula(n):
    """Using direct formula: C(n) = (2n)! / ((n+1)! * n!)"""
    return combination(2 * n, n) // (n + 1)
```

---

## Patterns & Use Cases

### Core Mathematical Patterns

#### 1. **Fast Exponentiation Pattern**
```python
def fast_power(base, exp):
    if exp == 0:
        return 1
    if exp == 1:
        return base
    
    if exp % 2 == 0:
        half = fast_power(base, exp // 2)
        return half * half
    else:
        return base * fast_power(base, exp - 1)
```

#### 2. **Prime Factorization Pattern**
```python
def prime_factors(n):
    factors = []
    d = 2
    
    while d * d <= n:
        while n % d == 0:
            factors.append(d)
            n //= d
        d += 1
    
    if n > 1:
        factors.append(n)
    
    return factors

def count_divisors(n):
    count = 0
    i = 1
    while i * i <= n:
        if n % i == 0:
            count += 1 if i * i == n else 2
        i += 1
    return count
```

#### 3. **Matrix Operations Pattern**
```python
def matrix_multiply(A, B):
    rows_A, cols_A = len(A), len(A[0])
    rows_B, cols_B = len(B), len(B[0])
    
    if cols_A != rows_B:
        return None
    
    result = [[0] * cols_B for _ in range(rows_A)]
    
    for i in range(rows_A):
        for j in range(cols_B):
            for k in range(cols_A):
                result[i][j] += A[i][k] * B[k][j]
    
    return result

def matrix_power(matrix, n):
    size = len(matrix)
    result = [[1 if i == j else 0 for j in range(size)] for i in range(size)]
    
    while n > 0:
        if n % 2 == 1:
            result = matrix_multiply(result, matrix)
        matrix = matrix_multiply(matrix, matrix)
        n //= 2
    
    return result
```

---

## Common Algorithms

### 1. **Fibonacci Sequence**
```python
def fibonacci_matrix(n):
    """Fibonacci using matrix exponentiation - O(log n)"""
    if n <= 1:
        return n
    
    F = [[1, 1], [1, 0]]
    result = matrix_power(F, n)
    return result[0][1]

def fibonacci_iterative(n):
    """Fibonacci using iteration - O(n)"""
    if n <= 1:
        return n
    
    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
    return b
```

### 2. **Chinese Remainder Theorem**
```python
def chinese_remainder_theorem(remainders, moduli):
    """Solve system of congruences"""
    total = 0
    prod = 1
    for m in moduli:
        prod *= m
    
    for r, m in zip(remainders, moduli):
        p = prod // m
        total += r * mod_inverse(p, m) * p
    
    return total % prod
```

### 3. **Pascal's Triangle**
```python
def pascal_triangle(n):
    triangle = []
    for i in range(n):
        row = [1] * (i + 1)
        for j in range(1, i):
            row[j] = triangle[i-1][j-1] + triangle[i-1][j]
        triangle.append(row)
    return triangle

def pascal_element(n, k):
    """Direct calculation of Pascal's triangle element"""
    return combination(n, k)
```

### 4. **Miller-Rabin Primality Test**
```python
def miller_rabin(n, k=5):
    """Probabilistic primality test"""
    if n < 2:
        return False
    if n == 2 or n == 3:
        return True
    if n % 2 == 0:
        return False
    
    # Write n-1 as d * 2^r
    r = 0
    d = n - 1
    while d % 2 == 0:
        r += 1
        d //= 2
    
    # Witness loop
    import random
    for _ in range(k):
        a = random.randrange(2, n - 1)
        x = pow(a, d, n)
        
        if x == 1 or x == n - 1:
            continue
        
        for _ in range(r - 1):
            x = pow(x, 2, n)
            if x == n - 1:
                break
        else:
            return False
    
    return True
```

---

## Example Problems

### Problem 1: **Power of Numbers**
```python
def my_pow(x, n):
    if n == 0:
        return 1
    if n < 0:
        x = 1 / x
        n = -n
    
    result = 1
    while n > 0:
        if n % 2 == 1:
            result *= x
        x *= x
        n //= 2
    
    return result
```

### Problem 2: **Count Primes**
```python
def count_primes(n):
    if n <= 2:
        return 0
    
    is_prime = [True] * n
    is_prime[0] = is_prime[1] = False
    
    for i in range(2, int(n**0.5) + 1):
        if is_prime[i]:
            for j in range(i*i, n, i):
                is_prime[j] = False
    
    return sum(is_prime)
```

### Problem 3: **Happy Number**
```python
def is_happy(n):
    def get_sum_of_squares(num):
        total = 0
        while num > 0:
            digit = num % 10
            total += digit * digit
            num //= 10
        return total
    
    seen = set()
    while n != 1 and n not in seen:
        seen.add(n)
        n = get_sum_of_squares(n)
    
    return n == 1
```

---

## Problem Categories

### 1. **Number Theory**
- Prime number problems
- GCD/LCM calculations
- Modular arithmetic
- Factorization

### 2. **Combinatorics**
- Counting problems
- Permutation generation
- Combination calculations
- Catalan numbers

### 3. **Matrix Mathematics**
- Matrix operations
- Linear systems
- Determinants
- Eigenvalues

### 4. **Probability & Statistics**
- Random algorithms
- Expected value calculations
- Statistical measures

---

## Complexity Analysis

### Time Complexities

**Number Theory:**
- GCD (Euclidean): O(log min(a,b))
- Sieve of Eratosthenes: O(n log log n)
- Primality testing: O(√n) deterministic, O(k log³ n) probabilistic
- Modular exponentiation: O(log n)

**Combinatorics:**
- Factorial: O(n)
- Combination: O(min(k, n-k))
- Catalan numbers: O(n²) DP, O(n) direct formula

### Space Complexities
- Most algorithms: O(1) to O(n)
- Sieve: O(n)
- Matrix operations: O(n²)

---

## Pro Tips & Interview Tricks

### Essential Formulas

#### Number Theory:
```python
# GCD properties
gcd(a, b) = gcd(b, a % b)
gcd(a, 0) = a

# Modular arithmetic
(a + b) % m = ((a % m) + (b % m)) % m
(a * b) % m = ((a % m) * (b % m)) % m
```

#### Combinatorics:
```python
# Pascal's identity
C(n, k) = C(n-1, k-1) + C(n-1, k)

# Catalan numbers
C(n) = (2n)! / ((n+1)! * n!) = C(2n, n) / (n+1)
```

### Common Patterns

#### Fast Exponentiation Template:
```python
def fast_operation(base, exp, operation):
    result = identity_element
    while exp > 0:
        if exp % 2 == 1:
            result = operation(result, base)
        base = operation(base, base)
        exp //= 2
    return result
```

#### Sieve Template:
```python
def sieve_template(n, mark_multiples):
    marked = [False] * (n + 1)
    
    for i in range(2, n + 1):
        if not marked[i]:
            mark_multiples(marked, i, n)
    
    return marked
```

### Interview Success Tips

1. **Master basic operations**: GCD, prime checking, modular arithmetic
2. **Understand complexity**: Know when to use which algorithm
3. **Practice mathematical reasoning**: Be able to derive formulas
4. **Handle edge cases**: Zero, negative numbers, overflow
5. **Use mathematical properties**: Optimize using number theory
6. **Know standard algorithms**: Sieve, fast exponentiation, matrix operations

Mathematical algorithms require strong theoretical understanding combined with efficient implementation. Practice the core concepts and standard algorithms to excel in technical interviews!