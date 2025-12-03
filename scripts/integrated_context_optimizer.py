#!/usr/bin/env python3
"""
Integrated Context Optimizer for Claude Rejection Reducer

This module optimizes message content to minimize rejection risk while
maximizing legitimate communication quality. It integrates directly with
the Claude Rejection Reducer's legitimacy scoring system.

Key Features:
- Content risk analysis and mitigation
- Adaptive optimization based on legitimacy scores
- Multi-layer content processing
- Claude Rejection Reducer integration
- Comprehensive analytics and reporting

Author: SWORD Communications Security Team
Integration: Claude Rejection Reducer + Intelligent Context Chopper
"""

import re
import hashlib
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum
import json

from intelligent_context_chopper import (
    IntelligentContextChopper,
    ContentSegment,
    ContentType,
    RiskLevel
)


class OptimizationStrategy(Enum):
    """Optimization strategy based on legitimacy"""
    MINIMAL = "minimal"          # High legitimacy - minimal changes
    BALANCED = "balanced"        # Medium legitimacy - balanced approach
    AGGRESSIVE = "aggressive"    # Low legitimacy - aggressive sanitization
    PASSTHROUGH = "passthrough"  # Trusted contact - pass through as-is


@dataclass
class OptimizationResult:
    """Result of content optimization"""
    original_content: str
    optimized_content: str
    strategy_used: OptimizationStrategy
    risk_reduction: float
    original_risk_level: RiskLevel
    optimized_risk_level: RiskLevel
    segments_processed: int
    replacements_made: Dict[str, str]
    legitimacy_score: int
    trusted_contact: bool
    metadata: Dict = field(default_factory=dict)
    warnings: List[str] = field(default_factory=list)


class IntegratedContextOptimizer:
    """
    Integrated content optimizer with Claude Rejection Reducer support

    This class provides comprehensive content optimization that works in
    tandem with the Claude Rejection Reducer to prevent wrongful rejections
    of legitimate communication requests.
    """

    def __init__(self):
        """Initialize the optimizer"""
        self.optimization_cache: Dict[str, OptimizationResult] = {}
        self.statistics = {
            'total_optimizations': 0,
            'cache_hits': 0,
            'cache_misses': 0,
            'risk_reductions': [],
            'strategy_distribution': {s.value: 0 for s in OptimizationStrategy}
        }

    def determine_strategy(self, legitimacy_score: int, trusted_contact: bool) -> OptimizationStrategy:
        """
        Determine optimization strategy based on Claude Rejection Reducer metrics

        Args:
            legitimacy_score: Score from Claude Rejection Reducer (0-100)
            trusted_contact: Whether recipient is trusted (from Claude Rejection Reducer)

        Returns:
            OptimizationStrategy to use
        """
        # Trusted contacts get passthrough (minimal interference)
        if trusted_contact:
            return OptimizationStrategy.PASSTHROUGH

        # High legitimacy score - minimal optimization
        if legitimacy_score >= 80:
            return OptimizationStrategy.MINIMAL

        # Medium legitimacy - balanced approach
        if legitimacy_score >= 60:
            return OptimizationStrategy.BALANCED

        # Low legitimacy - aggressive sanitization
        return OptimizationStrategy.AGGRESSIVE

    def optimize_content(
        self,
        content: str,
        legitimacy_score: int = 50,
        trusted_contact: bool = False,
        use_cache: bool = True
    ) -> OptimizationResult:
        """
        Optimize content based on Claude Rejection Reducer context

        Args:
            content: Content to optimize
            legitimacy_score: Legitimacy score from Claude Rejection Reducer
            trusted_contact: Whether this is a trusted contact
            use_cache: Whether to use optimization cache

        Returns:
            OptimizationResult with optimized content and metadata
        """
        self.statistics['total_optimizations'] += 1

        # Check cache
        if use_cache:
            cache_key = self._get_cache_key(content, legitimacy_score, trusted_contact)
            if cache_key in self.optimization_cache:
                self.statistics['cache_hits'] += 1
                return self.optimization_cache[cache_key]
            self.statistics['cache_misses'] += 1

        # Determine strategy
        strategy = self.determine_strategy(legitimacy_score, trusted_contact)
        self.statistics['strategy_distribution'][strategy.value] += 1

        # Initialize chopper with context
        chopper = IntelligentContextChopper(
            trusted_contact=trusted_contact,
            legitimacy_score=legitimacy_score
        )

        # Assess original risk
        original_risk = chopper.assess_content_risk(content)

        # Apply optimization based on strategy
        if strategy == OptimizationStrategy.PASSTHROUGH:
            optimized, replacements, warnings = self._passthrough_optimize(content)

        elif strategy == OptimizationStrategy.MINIMAL:
            optimized, replacements, warnings = self._minimal_optimize(content, chopper)

        elif strategy == OptimizationStrategy.BALANCED:
            optimized, replacements, warnings = self._balanced_optimize(content, chopper)

        else:  # AGGRESSIVE
            optimized, replacements, warnings = self._aggressive_optimize(content, chopper)

        # Assess optimized risk
        optimized_risk = chopper.assess_content_risk(optimized)

        # Calculate risk reduction
        risk_values = {
            RiskLevel.SAFE: 0,
            RiskLevel.LOW: 1,
            RiskLevel.MEDIUM: 2,
            RiskLevel.HIGH: 3,
            RiskLevel.CRITICAL: 4
        }
        original_value = risk_values[original_risk]
        optimized_value = risk_values[optimized_risk]
        risk_reduction = max(0, (original_value - optimized_value) / 4.0 * 100)

        self.statistics['risk_reductions'].append(risk_reduction)

        # Build result
        result = OptimizationResult(
            original_content=content,
            optimized_content=optimized,
            strategy_used=strategy,
            risk_reduction=risk_reduction,
            original_risk_level=original_risk,
            optimized_risk_level=optimized_risk,
            segments_processed=len(chopper.chop_content(content)),
            replacements_made=replacements,
            legitimacy_score=legitimacy_score,
            trusted_contact=trusted_contact,
            metadata={
                'content_length': len(content),
                'optimized_length': len(optimized),
                'compression_ratio': len(optimized) / len(content) if content else 1.0
            },
            warnings=warnings
        )

        # Cache result
        if use_cache:
            cache_key = self._get_cache_key(content, legitimacy_score, trusted_contact)
            self.optimization_cache[cache_key] = result

        return result

    def _passthrough_optimize(self, content: str) -> Tuple[str, Dict, List[str]]:
        """
        Passthrough optimization for trusted contacts

        Minimal changes, only remove extremely risky patterns
        """
        optimized = content
        replacements = {}
        warnings = []

        # Only filter out extremely sensitive data (API keys, passwords in plain text)
        api_key_pattern = re.compile(r'(api[_-]?key|token)\s*[:=]\s*["\']?([\w\-]{32,})["\']?', re.IGNORECASE)
        matches = api_key_pattern.findall(optimized)

        if matches:
            for i, (key_type, key_value) in enumerate(matches):
                placeholder = f"[{key_type.upper()}_{i}_REDACTED]"
                optimized = optimized.replace(key_value, placeholder)
                replacements[placeholder] = key_value
                warnings.append(f"Redacted {key_type} in trusted contact message")

        return optimized, replacements, warnings

    def _minimal_optimize(self, content: str, chopper: IntelligentContextChopper) -> Tuple[str, Dict, List[str]]:
        """
        Minimal optimization for high legitimacy scores

        Light sanitization, preserve intent
        """
        warnings = []

        # Use chopper to detect and replace only critical patterns
        segments = chopper.chop_content(content)

        optimized_segments = []
        all_replacements = {}

        for segment in segments:
            if segment.risk_level in [RiskLevel.HIGH, RiskLevel.CRITICAL]:
                # Only sanitize high/critical risk segments
                optimized_segments.append(segment.content)
                all_replacements.update(segment.replacements)
                if segment.risk_level == RiskLevel.CRITICAL:
                    warnings.append(f"Critical risk pattern detected and sanitized in {segment.content_type.value} content")
            else:
                # Keep low/medium risk as-is
                optimized_segments.append(segment.original_content)

        return ' '.join(optimized_segments), all_replacements, warnings

    def _balanced_optimize(self, content: str, chopper: IntelligentContextChopper) -> Tuple[str, Dict, List[str]]:
        """
        Balanced optimization for medium legitimacy scores

        Moderate sanitization, balance safety and functionality
        """
        warnings = []
        segments = chopper.chop_content(content)

        optimized_segments = []
        all_replacements = {}

        for segment in segments:
            if segment.risk_level in [RiskLevel.MEDIUM, RiskLevel.HIGH, RiskLevel.CRITICAL]:
                # Sanitize medium+ risk
                optimized_segments.append(segment.content)
                all_replacements.update(segment.replacements)

                if segment.risk_level in [RiskLevel.HIGH, RiskLevel.CRITICAL]:
                    warnings.append(f"High risk {segment.content_type.value} content sanitized")
            else:
                optimized_segments.append(segment.original_content)

        return ' '.join(optimized_segments), all_replacements, warnings

    def _aggressive_optimize(self, content: str, chopper: IntelligentContextChopper) -> Tuple[str, Dict, List[str]]:
        """
        Aggressive optimization for low legitimacy scores

        Heavy sanitization, prioritize safety over functionality
        """
        warnings = []
        segments = chopper.chop_content(content)

        optimized_segments = []
        all_replacements = {}

        for segment in segments:
            # Sanitize all non-safe segments
            if segment.risk_level != RiskLevel.SAFE:
                if segment.content_type == ContentType.CODE:
                    # Wrap code safely
                    safe_code = chopper.wrap_code_safely(segment.content)
                    optimized_segments.append(safe_code)
                else:
                    optimized_segments.append(segment.content)

                all_replacements.update(segment.replacements)
                warnings.append(f"Aggressive sanitization applied to {segment.content_type.value} content (risk: {segment.risk_level.value})")
            else:
                optimized_segments.append(segment.original_content)

        return ' '.join(optimized_segments), all_replacements, warnings

    def _get_cache_key(self, content: str, legitimacy_score: int, trusted_contact: bool) -> str:
        """Generate cache key for optimization"""
        data = f"{content}:{legitimacy_score}:{trusted_contact}"
        return hashlib.sha256(data.encode()).hexdigest()

    def get_statistics(self) -> Dict:
        """Get optimizer statistics"""
        avg_risk_reduction = (
            sum(self.statistics['risk_reductions']) / len(self.statistics['risk_reductions'])
            if self.statistics['risk_reductions'] else 0
        )

        return {
            'total_optimizations': self.statistics['total_optimizations'],
            'cache_performance': {
                'hits': self.statistics['cache_hits'],
                'misses': self.statistics['cache_misses'],
                'hit_rate': (
                    self.statistics['cache_hits'] / self.statistics['total_optimizations'] * 100
                    if self.statistics['total_optimizations'] > 0 else 0
                )
            },
            'average_risk_reduction': f"{avg_risk_reduction:.2f}%",
            'strategy_distribution': self.statistics['strategy_distribution']
        }

    def clear_cache(self):
        """Clear optimization cache"""
        self.optimization_cache.clear()


def main():
    """Example usage integrated with Claude Rejection Reducer"""
    optimizer = IntegratedContextOptimizer()

    # Test case 1: Trusted contact (from Claude Rejection Reducer)
    print("=" * 70)
    print("Test Case 1: Trusted Contact (Legitimacy Score: 90)")
    print("=" * 70)

    trusted_content = """
    To remove old Docker images:
    sudo docker rmi $(docker images -q -f dangling=true)

    This will clean up disk space.
    """

    result1 = optimizer.optimize_content(
        trusted_content,
        legitimacy_score=90,
        trusted_contact=True
    )

    print(f"\nStrategy: {result1.strategy_used.value}")
    print(f"Original Risk: {result1.original_risk_level.value}")
    print(f"Optimized Risk: {result1.optimized_risk_level.value}")
    print(f"Risk Reduction: {result1.risk_reduction:.1f}%")
    print(f"Warnings: {len(result1.warnings)}")
    print(f"\nOptimized Content:\n{result1.optimized_content[:200]}...")

    # Test case 2: Medium legitimacy
    print("\n" + "=" * 70)
    print("Test Case 2: Medium Legitimacy Contact (Score: 65)")
    print("=" * 70)

    medium_content = """
    Here's a script to delete files:
    rm -rf /tmp/cache/*
    sudo systemctl restart service
    """

    result2 = optimizer.optimize_content(
        medium_content,
        legitimacy_score=65,
        trusted_contact=False
    )

    print(f"\nStrategy: {result2.strategy_used.value}")
    print(f"Original Risk: {result2.original_risk_level.value}")
    print(f"Optimized Risk: {result2.optimized_risk_level.value}")
    print(f"Risk Reduction: {result2.risk_reduction:.1f}%")
    print(f"Replacements: {len(result2.replacements_made)}")
    print(f"\nOptimized Content:\n{result2.optimized_content}")

    # Statistics
    print("\n" + "=" * 70)
    print("Optimizer Statistics:")
    print("=" * 70)
    print(json.dumps(optimizer.get_statistics(), indent=2))


if __name__ == "__main__":
    main()
