# Compression: Efficient Data Storage and Transmission

## 🎯 What is Compression?

Compression is like packing for a trip - finding clever ways to fit more into less space without losing what's important. Just as you might roll clothes instead of folding them or use vacuum bags to compress bulky items, data compression uses mathematical algorithms to represent information more efficiently, reducing storage requirements and transmission times while preserving the original data's integrity.

## 🏗️ Core Concepts

### The Packing Analogy
- **Space Optimization**: Fit more data in less space
- **Smart Packing**: Use patterns and redundancy to compress efficiently
- **Lossless Packing**: Everything can be perfectly restored
- **Lossy Packing**: Accept some loss for dramatic space savings
- **Quick Access**: Balance compression ratio with decompression speed

### Why Compression Matters
1. **Storage Efficiency**: Reduce disk space and storage costs
2. **Network Performance**: Faster data transmission and reduced bandwidth
3. **Memory Optimization**: Fit more data in RAM
4. **Cost Reduction**: Lower storage and bandwidth expenses
5. **User Experience**: Faster loading times and better responsiveness

## 🗜️ Compression Implementation

```python
import time
import zlib
import gzip
import bz2
import lzma
import json
import pickle
from typing import Dict, List, Optional, Any, Tuple, Union
from dataclasses import dataclass
from abc import ABC, abstractmethod
import threading
from collections import defaultdict, Counter
import heapq
import struct

@dataclass
class CompressionResult:
    original_size: int
    compressed_size: int
    compression_ratio: float
    compression_time: float
    algorithm: str
    metadata: Dict[str, Any] = None
    
    @property
    def space_saved(self) -> int:
        return self.original_size - self.compressed_size
    
    @property
    def space_saved_percent(self) -> float:
        return (self.space_saved / self.original_size) * 100 if self.original_size > 0 else 0

class CompressionAlgorithm(ABC):
    """Abstract base class for compression algorithms"""
    
    @abstractmethod
    def compress(self, data: bytes) -> Tuple[bytes, CompressionResult]:
        """Compress data and return compressed bytes with metadata"""
        pass
    
    @abstractmethod
    def decompress(self, compressed_data: bytes) -> bytes:
        """Decompress data back to original form"""
        pass
    
    @abstractmethod
    def get_name(self) -> str:
        """Get algorithm name"""
        pass

class ZlibCompression(CompressionAlgorithm):
    """Zlib compression implementation"""
    
    def __init__(self, level: int = 6):
        self.level = level  # 1-9, higher = better compression, slower
    
    def compress(self, data: bytes) -> Tuple[bytes, CompressionResult]:
        start_time = time.time()
        compressed = zlib.compress(data, self.level)
        compression_time = time.time() - start_time
        
        result = CompressionResult(
            original_size=len(data),
            compressed_size=len(compressed),
            compression_ratio=len(compressed) / len(data) if len(data) > 0 else 0,
            compression_time=compression_time,
            algorithm=f"zlib-{self.level}"
        )
        
        return compressed, result
    
    def decompress(self, compressed_data: bytes) -> bytes:
        return zlib.decompress(compressed_data)
    
    def get_name(self) -> str:
        return f"zlib-{self.level}"

class GzipCompression(CompressionAlgorithm):
    """Gzip compression implementation"""
    
    def __init__(self, level: int = 6):
        self.level = level
    
    def compress(self, data: bytes) -> Tuple[bytes, CompressionResult]:
        start_time = time.time()
        compressed = gzip.compress(data, compresslevel=self.level)
        compression_time = time.time() - start_time
        
        result = CompressionResult(
            original_size=len(data),
            compressed_size=len(compressed),
            compression_ratio=len(compressed) / len(data) if len(data) > 0 else 0,
            compression_time=compression_time,
            algorithm=f"gzip-{self.level}"
        )
        
        return compressed, result
    
    def decompress(self, compressed_data: bytes) -> bytes:
        return gzip.decompress(compressed_data)
    
    def get_name(self) -> str:
        return f"gzip-{self.level}"

class Bz2Compression(CompressionAlgorithm):
    """Bzip2 compression implementation"""
    
    def __init__(self, level: int = 9):
        self.level = level
    
    def compress(self, data: bytes) -> Tuple[bytes, CompressionResult]:
        start_time = time.time()
        compressed = bz2.compress(data, compresslevel=self.level)
        compression_time = time.time() - start_time
        
        result = CompressionResult(
            original_size=len(data),
            compressed_size=len(compressed),
            compression_ratio=len(compressed) / len(data) if len(data) > 0 else 0,
            compression_time=compression_time,
            algorithm=f"bz2-{self.level}"
        )
        
        return compressed, result
    
    def decompress(self, compressed_data: bytes) -> bytes:
        return bz2.decompress(compressed_data)
    
    def get_name(self) -> str:
        return f"bz2-{self.level}"

class LzmaCompression(CompressionAlgorithm):
    """LZMA compression implementation"""
    
    def __init__(self, preset: int = 6):
        self.preset = preset
    
    def compress(self, data: bytes) -> Tuple[bytes, CompressionResult]:
        start_time = time.time()
        compressed = lzma.compress(data, preset=self.preset)
        compression_time = time.time() - start_time
        
        result = CompressionResult(
            original_size=len(data),
            compressed_size=len(compressed),
            compression_ratio=len(compressed) / len(data) if len(data) > 0 else 0,
            compression_time=compression_time,
            algorithm=f"lzma-{self.preset}"
        )
        
        return compressed, result
    
    def decompress(self, compressed_data: bytes) -> bytes:
        return lzma.decompress(compressed_data)
    
    def get_name(self) -> str:
        return f"lzma-{self.preset}"

class SimpleHuffmanCompression(CompressionAlgorithm):
    """Simple Huffman coding implementation for demonstration"""
    
    class HuffmanNode:
        def __init__(self, char=None, freq=0, left=None, right=None):
            self.char = char
            self.freq = freq
            self.left = left
            self.right = right
        
        def __lt__(self, other):
            return self.freq < other.freq
    
    def _build_huffman_tree(self, text: str) -> 'SimpleHuffmanCompression.HuffmanNode':
        """Build Huffman tree from text"""
        if not text:
            return None
        
        # Count character frequencies
        freq_map = Counter(text)
        
        # Create priority queue of nodes
        heap = []
        for char, freq in freq_map.items():
            node = self.HuffmanNode(char, freq)
            heapq.heappush(heap, node)
        
        # Build tree
        while len(heap) > 1:
            left = heapq.heappop(heap)
            right = heapq.heappop(heap)
            
            merged = self.HuffmanNode(freq=left.freq + right.freq, left=left, right=right)
            heapq.heappush(heap, merged)
        
        return heap[0] if heap else None
    
    def _build_codes(self, root: 'SimpleHuffmanCompression.HuffmanNode') -> Dict[str, str]:
        """Build character codes from Huffman tree"""
        if not root:
            return {}
        
        codes = {}
        
        def traverse(node, code):
            if node.char is not None:
                codes[node.char] = code or "0"  # Single character case
            else:
                if node.left:
                    traverse(node.left, code + "0")
                if node.right:
                    traverse(node.right, code + "1")
        
        traverse(root, "")
        return codes
    
    def compress(self, data: bytes) -> Tuple[bytes, CompressionResult]:
        start_time = time.time()
        
        try:
            text = data.decode('utf-8')
        except UnicodeDecodeError:
            # Fallback to zlib for binary data
            compressed = zlib.compress(data)
            compression_time = time.time() - start_time
            
            result = CompressionResult(
                original_size=len(data),
                compressed_size=len(compressed),
                compression_ratio=len(compressed) / len(data),
                compression_time=compression_time,
                algorithm="huffman-fallback-zlib"
            )
            return compressed, result
        
        if not text:
            return data, CompressionResult(len(data), len(data), 1.0, 0, "huffman-empty")
        
        # Build Huffman tree and codes
        root = self._build_huffman_tree(text)
        codes = self._build_codes(root)
        
        # Encode text
        encoded_bits = ""
        for char in text:
            encoded_bits += codes[char]
        
        # Convert bits to bytes
        # Pad to byte boundary
        while len(encoded_bits) % 8 != 0:
            encoded_bits += "0"
        
        # Convert to bytes
        compressed_bytes = bytearray()
        for i in range(0, len(encoded_bits), 8):
            byte_str = encoded_bits[i:i+8]
            compressed_bytes.append(int(byte_str, 2))
        
        # Store tree and compressed data
        tree_data = pickle.dumps(root)
        final_compressed = struct.pack('>I', len(tree_data)) + tree_data + bytes(compressed_bytes)
        
        compression_time = time.time() - start_time
        
        result = CompressionResult(
            original_size=len(data),
            compressed_size=len(final_compressed),
            compression_ratio=len(final_compressed) / len(data),
            compression_time=compression_time,
            algorithm="huffman",
            metadata={'unique_chars': len(codes)}
        )
        
        return final_compressed, result
    
    def decompress(self, compressed_data: bytes) -> bytes:
        if len(compressed_data) < 4:
            return compressed_data
        
        try:
            # Extract tree size
            tree_size = struct.unpack('>I', compressed_data[:4])[0]
            
            # Extract tree and compressed data
            tree_data = compressed_data[4:4+tree_size]
            compressed_bytes = compressed_data[4+tree_size:]
            
            # Reconstruct tree
            root = pickle.loads(tree_data)
            
            # Convert bytes back to bits
            bits = ""
            for byte in compressed_bytes:
                bits += format(byte, '08b')
            
            # Decode using Huffman tree
            decoded = ""
            current = root
            
            for bit in bits:
                if current.char is not None:
                    decoded += current.char
                    current = root
                
                if bit == "0" and current.left:
                    current = current.left
                elif bit == "1" and current.right:
                    current = current.right
            
            # Handle last character
            if current.char is not None:
                decoded += current.char
            
            return decoded.encode('utf-8')
            
        except Exception:
            # Fallback to zlib decompression
            return zlib.decompress(compressed_data)
    
    def get_name(self) -> str:
        return "huffman"

class AdaptiveCompressor:
    """Adaptive compressor that chooses best algorithm for data"""
    
    def __init__(self):
        self.algorithms = [
            ZlibCompression(1),   # Fast
            ZlibCompression(6),   # Balanced
            ZlibCompression(9),   # Best compression
            GzipCompression(6),
            Bz2Compression(9),
            LzmaCompression(6),
            SimpleHuffmanCompression()
        ]
        
        self.performance_history: Dict[str, List[CompressionResult]] = defaultdict(list)
    
    def compress(self, data: bytes, optimize_for: str = "balanced") -> Tuple[bytes, CompressionResult]:
        """Compress data using best algorithm for the use case"""
        
        if optimize_for == "speed":
            # Use fastest algorithm
            algorithm = ZlibCompression(1)
        elif optimize_for == "size":
            # Try multiple algorithms and pick best compression
            return self._find_best_compression(data)
        else:  # balanced
            # Use good balance of speed and compression
            algorithm = ZlibCompression(6)
        
        compressed, result = algorithm.compress(data)
        self.performance_history[algorithm.get_name()].append(result)
        
        return compressed, result
    
    def _find_best_compression(self, data: bytes) -> Tuple[bytes, CompressionResult]:
        """Find best compression algorithm for given data"""
        
        best_compressed = None
        best_result = None
        
        # Try subset of algorithms for speed
        test_algorithms = [
            ZlibCompression(9),
            Bz2Compression(9),
            LzmaCompression(6)
        ]
        
        for algorithm in test_algorithms:
            try:
                compressed, result = algorithm.compress(data)
                
                if (best_result is None or 
                    result.compression_ratio < best_result.compression_ratio):
                    best_compressed = compressed
                    best_result = result
                
                self.performance_history[algorithm.get_name()].append(result)
                
            except Exception as e:
                print(f"Algorithm {algorithm.get_name()} failed: {e}")
        
        return best_compressed or data, best_result or CompressionResult(
            len(data), len(data), 1.0, 0, "no-compression"
        )
    
    def get_algorithm_stats(self) -> Dict[str, Dict[str, float]]:
        """Get performance statistics for each algorithm"""
        
        stats = {}
        
        for algo_name, results in self.performance_history.items():
            if results:
                avg_ratio = sum(r.compression_ratio for r in results) / len(results)
                avg_time = sum(r.compression_time for r in results) / len(results)
                avg_space_saved = sum(r.space_saved_percent for r in results) / len(results)
                
                stats[algo_name] = {
                    'average_compression_ratio': avg_ratio,
                    'average_compression_time': avg_time,
                    'average_space_saved_percent': avg_space_saved,
                    'total_compressions': len(results)
                }
        
        return stats

class StreamingCompressor:
    """Compressor for streaming data"""
    
    def __init__(self, algorithm: CompressionAlgorithm, chunk_size: int = 8192):
        self.algorithm = algorithm
        self.chunk_size = chunk_size
        self.compressor = None
        
        # Initialize streaming compressor based on algorithm
        if isinstance(algorithm, ZlibCompression):
            self.compressor = zlib.compressobj(algorithm.level)
        elif isinstance(algorithm, GzipCompression):
            self.compressor = zlib.compressobj(
                algorithm.level, zlib.DEFLATED, 16 + zlib.MAX_WBITS
            )
    
    def compress_chunk(self, chunk: bytes) -> bytes:
        """Compress a chunk of data"""
        if self.compressor:
            return self.compressor.compress(chunk)
        else:
            # Fallback to regular compression
            compressed, _ = self.algorithm.compress(chunk)
            return compressed
    
    def finalize(self) -> bytes:
        """Finalize compression and return remaining data"""
        if self.compressor:
            return self.compressor.flush()
        return b""

class CompressionBenchmark:
    """Benchmark different compression algorithms"""
    
    def __init__(self):
        self.algorithms = [
            ZlibCompression(1),
            ZlibCompression(6),
            ZlibCompression(9),
            GzipCompression(6),
            Bz2Compression(9),
            LzmaCompression(6),
            SimpleHuffmanCompression()
        ]
    
    def benchmark(self, test_data: List[bytes]) -> Dict[str, Dict[str, Any]]:
        """Benchmark algorithms on test data"""
        
        results = defaultdict(lambda: {
            'total_original_size': 0,
            'total_compressed_size': 0,
            'total_compression_time': 0,
            'total_decompression_time': 0,
            'successful_compressions': 0,
            'failed_compressions': 0,
            'compression_results': []
        })
        
        for data in test_data:
            for algorithm in self.algorithms:
                algo_name = algorithm.get_name()
                
                try:
                    # Compression
                    compressed, comp_result = algorithm.compress(data)
                    
                    # Decompression
                    start_time = time.time()
                    decompressed = algorithm.decompress(compressed)
                    decomp_time = time.time() - start_time
                    
                    # Verify integrity
                    if decompressed == data:
                        results[algo_name]['total_original_size'] += comp_result.original_size
                        results[algo_name]['total_compressed_size'] += comp_result.compressed_size
                        results[algo_name]['total_compression_time'] += comp_result.compression_time
                        results[algo_name]['total_decompression_time'] += decomp_time
                        results[algo_name]['successful_compressions'] += 1
                        results[algo_name]['compression_results'].append(comp_result)
                    else:
                        results[algo_name]['failed_compressions'] += 1
                        print(f"Data integrity check failed for {algo_name}")
                
                except Exception as e:
                    results[algo_name]['failed_compressions'] += 1
                    print(f"Compression failed for {algo_name}: {e}")
        
        # Calculate averages
        final_results = {}
        for algo_name, data in results.items():
            if data['successful_compressions'] > 0:
                final_results[algo_name] = {
                    'average_compression_ratio': data['total_compressed_size'] / data['total_original_size'],
                    'average_compression_time': data['total_compression_time'] / data['successful_compressions'],
                    'average_decompression_time': data['total_decompression_time'] / data['successful_compressions'],
                    'space_saved_percent': ((data['total_original_size'] - data['total_compressed_size']) / data['total_original_size']) * 100,
                    'successful_compressions': data['successful_compressions'],
                    'failed_compressions': data['failed_compressions'],
                    'total_original_size': data['total_original_size'],
                    'total_compressed_size': data['total_compressed_size']
                }
        
        return final_results

# Example usage and testing
print("=== Compression Demo ===")

# Generate test data
def generate_test_data() -> List[bytes]:
    """Generate various types of test data"""
    
    test_data = []
    
    # Text data (highly compressible)
    text_data = "This is a sample text with lots of repetition. " * 100
    test_data.append(text_data.encode('utf-8'))
    
    # JSON data (structured, compressible)
    json_data = json.dumps({
        'users': [{'id': i, 'name': f'User {i}', 'active': i % 2 == 0} for i in range(100)],
        'metadata': {'version': '1.0', 'created': '2023-01-01'}
    })
    test_data.append(json_data.encode('utf-8'))
    
    # Random data (less compressible)
    import random
    random_data = bytes([random.randint(0, 255) for _ in range(1000)])
    test_data.append(random_data)
    
    # Log data (semi-structured)
    log_entries = []
    for i in range(50):
        log_entries.append(f"2023-01-01 12:{i:02d}:00 INFO [server] Request processed successfully")
    log_data = "\n".join(log_entries)
    test_data.append(log_data.encode('utf-8'))
    
    return test_data

# Test individual algorithms
print("\n--- Individual Algorithm Tests ---")

test_data = generate_test_data()
sample_data = test_data[0]  # Use text data for individual tests

algorithms = [
    ZlibCompression(6),
    GzipCompression(6),
    Bz2Compression(9),
    LzmaCompression(6),
    SimpleHuffmanCompression()
]

for algorithm in algorithms:
    try:
        compressed, result = algorithm.compress(sample_data)
        decompressed = algorithm.decompress(compressed)
        
        integrity_check = decompressed == sample_data
        
        print(f"{algorithm.get_name()}:")
        print(f"  Original size: {result.original_size:,} bytes")
        print(f"  Compressed size: {result.compressed_size:,} bytes")
        print(f"  Compression ratio: {result.compression_ratio:.3f}")
        print(f"  Space saved: {result.space_saved_percent:.1f}%")
        print(f"  Compression time: {result.compression_time:.4f}s")
        print(f"  Integrity check: {'✓' if integrity_check else '✗'}")
        print()
        
    except Exception as e:
        print(f"{algorithm.get_name()}: Failed - {e}")

# Test adaptive compressor
print("--- Adaptive Compressor Test ---")

adaptive = AdaptiveCompressor()

for i, data in enumerate(test_data):
    print(f"\nTest data {i+1} ({len(data):,} bytes):")
    
    # Test different optimization modes
    for mode in ['speed', 'balanced', 'size']:
        compressed, result = adaptive.compress(data, optimize_for=mode)
        
        print(f"  {mode}: {result.algorithm} - "
              f"{result.space_saved_percent:.1f}% saved, "
              f"{result.compression_time:.4f}s")

# Comprehensive benchmark
print("\n--- Compression Benchmark ---")

benchmark = CompressionBenchmark()
benchmark_results = benchmark.benchmark(test_data)

print("Algorithm Performance Summary:")
print(f"{'Algorithm':<20} {'Ratio':<8} {'Space Saved':<12} {'Comp Time':<10} {'Decomp Time':<12}")
print("-" * 70)

for algo_name, stats in sorted(benchmark_results.items(), 
                              key=lambda x: x[1]['average_compression_ratio']):
    print(f"{algo_name:<20} "
          f"{stats['average_compression_ratio']:.3f}    "
          f"{stats['space_saved_percent']:>8.1f}%     "
          f"{stats['average_compression_time']:>8.4f}s  "
          f"{stats['average_decompression_time']:>10.4f}s")

# Test streaming compression
print("\n--- Streaming Compression Test ---")

streaming_data = b"This is streaming data. " * 1000
streaming_compressor = StreamingCompressor(ZlibCompression(6), chunk_size=100)

compressed_chunks = []
for i in range(0, len(streaming_data), 100):
    chunk = streaming_data[i:i+100]
    compressed_chunk = streaming_compressor.compress_chunk(chunk)
    compressed_chunks.append(compressed_chunk)

# Finalize
final_chunk = streaming_compressor.finalize()
compressed_chunks.append(final_chunk)

total_compressed = b''.join(compressed_chunks)
original_size = len(streaming_data)
compressed_size = len(total_compressed)

print(f"Streaming compression:")
print(f"  Original size: {original_size:,} bytes")
print(f"  Compressed size: {compressed_size:,} bytes")
print(f"  Compression ratio: {compressed_size/original_size:.3f}")
print(f"  Space saved: {((original_size-compressed_size)/original_size)*100:.1f}%")

# Algorithm statistics from adaptive compressor
print("\n--- Algorithm Performance History ---")
algo_stats = adaptive.get_algorithm_stats()

for algo_name, stats in algo_stats.items():
    print(f"{algo_name}:")
    print(f"  Average compression ratio: {stats['average_compression_ratio']:.3f}")
    print(f"  Average compression time: {stats['average_compression_time']:.4f}s")
    print(f"  Average space saved: {stats['average_space_saved_percent']:.1f}%")
    print(f"  Total compressions: {stats['total_compressions']}")

print("\n--- Compression Demo Completed ---")
```

## 📚 Conclusion

Compression is essential for optimizing storage, bandwidth, and performance in modern systems. From simple text compression to adaptive algorithms that choose the best strategy for each data type, compression enables applications to handle larger datasets more efficiently while reducing costs and improving user experience.

**Key Takeaways:**

1. **Choose Appropriate Algorithm**: Match compression method to data type and use case
2. **Balance Trade-offs**: Consider compression ratio vs. speed vs. memory usage
3. **Adaptive Strategies**: Use different algorithms for different data patterns
4. **Streaming Support**: Handle large datasets with streaming compression
5. **Monitor Performance**: Track compression effectiveness and adjust strategies

The future of compression includes machine learning-powered adaptive algorithms, specialized compression for emerging data types, and hardware-accelerated compression. Whether building web applications, databases, or distributed systems, implementing effective compression strategies is crucial for optimal performance and resource utilization.
