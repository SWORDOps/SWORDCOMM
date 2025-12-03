#!/usr/bin/env python3
"""
Token Optimizer for Claude Rejection Reducer Integration

This module optimizes token usage while preserving message intent and quality.
It works with the Claude Rejection Reducer to ensure optimizations don't
inadvertently trigger false positives.

Key Features:
- Intelligent token reduction
- Context-preserving compression
- Claude Rejection Reducer awareness
- Legitimacy-aware optimization
- Quality vs. token trade-off management

Author: SWORD Communications Security Team
Integration: Claude Rejection Reducer + Context Optimizer
"""

import re
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum
import json


class CompressionLevel(Enum):
    """Token compression level"""
    NONE = 0
    LIGHT = 1
    MODERATE = 2
    AGGRESSIVE = 3


@dataclass
class TokenOptimizationResult:
    """Result of token optimization"""
    original_content: str
    optimized_content: str
    original_tokens: int
    optimized_tokens: int
    tokens_saved: int
    compression_ratio: float
    compression_level: CompressionLevel
    quality_score: float
    legitimacy_preserved: bool
    metadata: Dict


class TokenOptimizer:
    """
    Optimize token usage while preserving legitimacy context

    This optimizer reduces token count intelligently without triggering
    Claude Rejection Reducer false positives.
    """

    # Common word replacements (shorter equivalents)
    WORD_REPLACEMENTS = {
        'therefore': 'so',
        'however': 'but',
        'additionally': 'also',
        'furthermore': 'also',
        'nevertheless': 'still',
        'consequently': 'so',
        'accordingly': 'so',
        'subsequently': 'then',
        'initialize': 'init',
        'configuration': 'config',
        'implementation': 'impl',
        'documentation': 'docs',
        'application': 'app',
        'development': 'dev',
        'production': 'prod',
        'environment': 'env',
        'repository': 'repo',
        'directory': 'dir',
        'parameter': 'param',
        'argument': 'arg',
        'temporary': 'temp',
        'administrator': 'admin',
        'authenticate': 'auth',
        'authorization': 'auth',
    }

    # Patterns for whitespace optimization
    WHITESPACE_PATTERNS = [
        (re.compile(r'\n\s*\n\s*\n+'), '\n\n'),  # Multiple blank lines
        (re.compile(r' {2,}'), ' '),               # Multiple spaces
        (re.compile(r'\t+'), ' '),                 # Tabs to space
        (re.compile(r'^ +', re.MULTILINE), ''),    # Leading spaces
        (re.compile(r' +$', re.MULTILINE), ''),    # Trailing spaces
    ]

    def __init__(self):
        """Initialize token optimizer"""
        self.statistics = {
            'total_optimizations': 0,
            'total_tokens_saved': 0,
            'total_original_tokens': 0,
            'compression_levels_used': {level.name: 0 for level in CompressionLevel}
        }

    def estimate_tokens(self, text: str) -> int:
        """
        Estimate token count (rough approximation)

        Args:
            text: Text to estimate

        Returns:
            Estimated token count
        """
        # Rough estimation: ~4 characters per token on average
        # This is a simplification; actual tokenization is more complex
        return len(text) // 4 + text.count(' ')

    def determine_compression_level(
        self,
        content_length: int,
        legitimacy_score: int,
        trusted_contact: bool
    ) -> CompressionLevel:
        """
        Determine appropriate compression level

        Args:
            content_length: Length of content
            legitimacy_score: Score from Claude Rejection Reducer
            trusted_contact: Whether this is a trusted contact

        Returns:
            CompressionLevel to use
        """
        # Short content doesn't need compression
        if content_length < 200:
            return CompressionLevel.NONE

        # Trusted contacts with high legitimacy - light compression
        if trusted_contact and legitimacy_score >= 80:
            return CompressionLevel.LIGHT

        # High legitimacy - moderate compression
        if legitimacy_score >= 70:
            return CompressionLevel.MODERATE

        # Medium/low legitimacy - aggressive compression
        # (less content = less risk of rejection)
        return CompressionLevel.AGGRESSIVE

    def optimize_tokens(
        self,
        content: str,
        legitimacy_score: int = 50,
        trusted_contact: bool = False,
        target_compression: Optional[float] = None
    ) -> TokenOptimizationResult:
        """
        Optimize token usage

        Args:
            content: Content to optimize
            legitimacy_score: Score from Claude Rejection Reducer
            trusted_contact: Whether this is a trusted contact
            target_compression: Target compression ratio (0.0-1.0), None for auto

        Returns:
            TokenOptimizationResult with optimized content
        """
        self.statistics['total_optimizations'] += 1

        original_tokens = self.estimate_tokens(content)
        self.statistics['total_original_tokens'] += original_tokens

        # Determine compression level
        if target_compression is not None:
            compression_level = self._get_level_for_target(target_compression)
        else:
            compression_level = self.determine_compression_level(
                len(content),
                legitimacy_score,
                trusted_contact
            )

        self.statistics['compression_levels_used'][compression_level.name] += 1

        # Apply optimization based on level
        if compression_level == CompressionLevel.NONE:
            optimized = content
            quality_score = 1.0

        elif compression_level == CompressionLevel.LIGHT:
            optimized, quality_score = self._light_optimization(content)

        elif compression_level == CompressionLevel.MODERATE:
            optimized, quality_score = self._moderate_optimization(content)

        else:  # AGGRESSIVE
            optimized, quality_score = self._aggressive_optimization(content)

        # Calculate metrics
        optimized_tokens = self.estimate_tokens(optimized)
        tokens_saved = original_tokens - optimized_tokens
        compression_ratio = optimized_tokens / original_tokens if original_tokens > 0 else 1.0

        self.statistics['total_tokens_saved'] += tokens_saved

        # Check legitimacy preservation
        legitimacy_preserved = self._check_legitimacy_preservation(
            content,
            optimized,
            legitimacy_score
        )

        return TokenOptimizationResult(
            original_content=content,
            optimized_content=optimized,
            original_tokens=original_tokens,
            optimized_tokens=optimized_tokens,
            tokens_saved=tokens_saved,
            compression_ratio=compression_ratio,
            compression_level=compression_level,
            quality_score=quality_score,
            legitimacy_preserved=legitimacy_preserved,
            metadata={
                'legitimacy_score': legitimacy_score,
                'trusted_contact': trusted_contact,
                'original_length': len(content),
                'optimized_length': len(optimized)
            }
        )

    def _light_optimization(self, content: str) -> Tuple[str, float]:
        """
        Light optimization - minimal changes

        - Remove excessive whitespace
        - Basic cleanup
        """
        optimized = content

        # Apply whitespace patterns
        for pattern, replacement in self.WHITESPACE_PATTERNS[:2]:  # Only first 2
            optimized = pattern.sub(replacement, optimized)

        # Quality score (minimal degradation)
        quality_score = 0.95

        return optimized, quality_score

    def _moderate_optimization(self, content: str) -> Tuple[str, float]:
        """
        Moderate optimization - balanced approach

        - All whitespace optimization
        - Common word replacements
        - Remove redundant phrases
        """
        optimized = content

        # Apply all whitespace patterns
        for pattern, replacement in self.WHITESPACE_PATTERNS:
            optimized = pattern.sub(replacement, optimized)

        # Apply word replacements (case-insensitive)
        for long_word, short_word in self.WORD_REPLACEMENTS.items():
            pattern = re.compile(r'\b' + re.escape(long_word) + r'\b', re.IGNORECASE)
            optimized = pattern.sub(short_word, optimized)

        # Remove common redundant phrases
        redundant_phrases = [
            r'basically,?\s*',
            r'actually,?\s*',
            r'really,?\s*',
            r'very\s+very\s+',
            r'in order to\s+',
            r'due to the fact that\s+',
        ]

        for phrase in redundant_phrases:
            optimized = re.sub(phrase, '', optimized, flags=re.IGNORECASE)

        quality_score = 0.85

        return optimized, quality_score

    def _aggressive_optimization(self, content: str) -> Tuple[str, float]:
        """
        Aggressive optimization - maximum token reduction

        - All moderate optimizations
        - Sentence compression
        - Acronym use
        - Article removal (where safe)
        """
        optimized = content

        # Start with moderate optimization
        optimized, _ = self._moderate_optimization(optimized)

        # Remove articles in some contexts (be careful not to break meaning)
        # Only remove where it's grammatically acceptable
        optimized = re.sub(r'\b(a|an|the)\s+(\w+)\s+(of|in|on|at|to|for)\s+', r'\2 \3 ', optimized, flags=re.IGNORECASE)

        # Compress common technical phrases
        technical_compressions = {
            r'command line interface': 'CLI',
            r'application programming interface': 'API',
            r'graphical user interface': 'GUI',
            r'for example': 'e.g.',
            r'that is': 'i.e.',
            r'and so on': 'etc.',
        }

        for phrase, acronym in technical_compressions.items():
            optimized = re.sub(phrase, acronym, optimized, flags=re.IGNORECASE)

        quality_score = 0.70

        return optimized, quality_score

    def _get_level_for_target(self, target: float) -> CompressionLevel:
        """Get compression level for target ratio"""
        if target >= 0.95:
            return CompressionLevel.LIGHT
        elif target >= 0.80:
            return CompressionLevel.MODERATE
        else:
            return CompressionLevel.AGGRESSIVE

    def _check_legitimacy_preservation(
        self,
        original: str,
        optimized: str,
        legitimacy_score: int
    ) -> bool:
        """
        Check if optimization preserved legitimacy context

        Important: Ensure optimizations don't introduce patterns that
        could trigger Claude Rejection Reducer false positives
        """
        # Check if critical legitimacy indicators are preserved

        # System contact indicators
        contact_indicators = ['contact', 'profile', 'friend', 'group', 'member']
        original_has_indicators = any(indicator in original.lower() for indicator in contact_indicators)
        optimized_has_indicators = any(indicator in optimized.lower() for indicator in contact_indicators)

        if original_has_indicators and not optimized_has_indicators:
            return False

        # Check if optimization accidentally introduced risky patterns
        risky_patterns = [r'\b(rm|del|destroy)\s+-[rf]+\s+/', r'\bsudo\s+rm\s+']

        for pattern in risky_patterns:
            if not re.search(pattern, original) and re.search(pattern, optimized):
                # Optimization introduced risky pattern - not legitimate
                return False

        # If high legitimacy score, ensure quality is maintained
        if legitimacy_score >= 80:
            length_ratio = len(optimized) / len(original) if original else 1.0
            if length_ratio < 0.70:  # Too aggressive compression for high legitimacy
                return False

        return True

    def get_statistics(self) -> Dict:
        """Get optimizer statistics"""
        avg_tokens_saved = (
            self.statistics['total_tokens_saved'] / self.statistics['total_optimizations']
            if self.statistics['total_optimizations'] > 0 else 0
        )

        avg_compression_ratio = (
            1.0 - (self.statistics['total_tokens_saved'] / self.statistics['total_original_tokens'])
            if self.statistics['total_original_tokens'] > 0 else 1.0
        )

        return {
            'total_optimizations': self.statistics['total_optimizations'],
            'total_tokens_saved': self.statistics['total_tokens_saved'],
            'average_tokens_saved': f"{avg_tokens_saved:.1f}",
            'average_compression_ratio': f"{avg_compression_ratio:.2f}",
            'compression_levels_distribution': self.statistics['compression_levels_used']
        }


def main():
    """Example usage"""
    optimizer = TokenOptimizer()

    # Test case 1: Trusted contact
    print("=" * 70)
    print("Test Case 1: Trusted Contact (Light Compression)")
    print("=" * 70)

    trusted_text = """
    Hello! I wanted to reach out and ask if you could help me with the
    configuration of the application. Basically, I need to initialize
    the development environment and set up the documentation repository.
    Could you please provide guidance on this?
    """

    result1 = optimizer.optimize_tokens(
        trusted_text,
        legitimacy_score=85,
        trusted_contact=True
    )

    print(f"\nCompression Level: {result1.compression_level.name}")
    print(f"Original Tokens: {result1.original_tokens}")
    print(f"Optimized Tokens: {result1.optimized_tokens}")
    print(f"Tokens Saved: {result1.tokens_saved} ({(1-result1.compression_ratio)*100:.1f}%)")
    print(f"Quality Score: {result1.quality_score:.2f}")
    print(f"Legitimacy Preserved: {result1.legitimacy_preserved}")
    print(f"\nOptimized Content:\n{result1.optimized_content}")

    # Test case 2: Low legitimacy (aggressive compression)
    print("\n" + "=" * 70)
    print("Test Case 2: Low Legitimacy (Aggressive Compression)")
    print("=" * 70)

    low_leg_text = """
    In order to properly configure the command line interface, you need to
    basically follow these steps. First of all, you should initialize the
    application programming interface configuration. Then, you need to set
    up the graphical user interface. That is to say, you need to configure
    the settings for example in the configuration file, and so on.
    """

    result2 = optimizer.optimize_tokens(
        low_leg_text,
        legitimacy_score=45,
        trusted_contact=False
    )

    print(f"\nCompression Level: {result2.compression_level.name}")
    print(f"Original Tokens: {result2.original_tokens}")
    print(f"Optimized Tokens: {result2.optimized_tokens}")
    print(f"Tokens Saved: {result2.tokens_saved} ({(1-result2.compression_ratio)*100:.1f}%)")
    print(f"Quality Score: {result2.quality_score:.2f}")
    print(f"Legitimacy Preserved: {result2.legitimacy_preserved}")
    print(f"\nOptimized Content:\n{result2.optimized_content}")

    # Statistics
    print("\n" + "=" * 70)
    print("Token Optimizer Statistics:")
    print("=" * 70)
    print(json.dumps(optimizer.get_statistics(), indent=2))


if __name__ == "__main__":
    main()
