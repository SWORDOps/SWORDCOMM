#!/usr/bin/env python3
"""
Intelligent Context Chopper for Claude Rejection Reducer Integration

This module intelligently segments and processes message content to prevent
wrongful rejections by Claude's content filters. It works as a preprocessing
layer before messages are sent.

Key Features:
- Pattern-based content segmentation
- Code block detection and safe wrapping
- Sensitive keyword placeholder replacement
- Context-aware chunking
- Integration with Claude Rejection Reducer legitimacy scoring

Author: SWORD Communications Security Team
Integration: Claude Rejection Reducer
"""

import re
import json
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
from enum import Enum


class ContentType(Enum):
    """Content type classification"""
    TEXT = "text"
    CODE = "code"
    COMMAND = "command"
    URL = "url"
    MIXED = "mixed"


class RiskLevel(Enum):
    """Risk level for rejection"""
    SAFE = "safe"
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


@dataclass
class ContentSegment:
    """Represents a segmented piece of content"""
    content: str
    content_type: ContentType
    risk_level: RiskLevel
    original_content: str
    replacements: Dict[str, str]
    start_pos: int
    end_pos: int
    metadata: Dict[str, any]


class IntelligentContextChopper:
    """
    Intelligently chops and processes content to prevent Claude rejections

    This class analyzes message content and applies smart segmentation and
    sanitization strategies to reduce the likelihood of wrongful rejections
    while preserving legitimate communication.
    """

    # Patterns that might trigger false rejections
    RISKY_PATTERNS = {
        # Command-like patterns
        'shell_commands': re.compile(r'\b(rm|dd|mkfs|format|del|destroy|kill|terminate)\s+(-[a-z]+\s+)*', re.IGNORECASE),
        'sudo_commands': re.compile(r'\b(sudo|su|doas)\s+', re.IGNORECASE),

        # Code execution patterns
        'eval_patterns': re.compile(r'\b(eval|exec|system|shell_exec|passthru)\s*\(', re.IGNORECASE),
        'injection_patterns': re.compile(r'(;|\||&&|\$\(|\`).*(rm|curl|wget|nc|bash)', re.IGNORECASE),

        # Sensitive data patterns
        'api_keys': re.compile(r'(api[_-]?key|token|secret|password|passwd)\s*[:=]\s*["\']?[\w\-]{16,}', re.IGNORECASE),
        'credentials': re.compile(r'(username|user|login)\s*[:=]\s*["\']?\w+["\']?\s*(password|passwd|pwd)\s*[:=]\s*["\']?[\w!@#$%^&*]+', re.IGNORECASE),

        # Network scanning patterns
        'port_scanning': re.compile(r'\b(nmap|masscan|zmap)\s+.*(-p|--port)', re.IGNORECASE),
        'network_recon': re.compile(r'\b(netcat|nc|socat)\s+.*\d+\.\d+\.\d+\.\d+', re.IGNORECASE),
    }

    # Safe placeholder replacements
    SAFE_PLACEHOLDERS = {
        'rm': '[REMOVE_CMD]',
        'dd': '[DISK_CMD]',
        'mkfs': '[FORMAT_CMD]',
        'format': '[FORMAT_CMD]',
        'del': '[DELETE_CMD]',
        'destroy': '[DESTROY_CMD]',
        'kill': '[TERMINATE_CMD]',
        'sudo': '[PRIVILEGE_CMD]',
        'eval': '[EVAL_FUNC]',
        'exec': '[EXEC_FUNC]',
        'system': '[SYSTEM_FUNC]',
    }

    def __init__(self, trusted_contact: bool = False, legitimacy_score: int = 50):
        """
        Initialize the context chopper

        Args:
            trusted_contact: Whether this is for a trusted contact (from Claude Rejection Reducer)
            legitimacy_score: Legitimacy score from Claude Rejection Reducer (0-100)
        """
        self.trusted_contact = trusted_contact
        self.legitimacy_score = legitimacy_score
        self.replacement_map: Dict[str, str] = {}

    def assess_content_risk(self, content: str) -> RiskLevel:
        """
        Assess the risk level of content triggering rejection

        Args:
            content: Content to assess

        Returns:
            RiskLevel indicating likelihood of rejection
        """
        risk_score = 0

        # Check against risky patterns
        for pattern_name, pattern in self.RISKY_PATTERNS.items():
            matches = pattern.findall(content)
            if matches:
                if pattern_name in ['shell_commands', 'sudo_commands']:
                    risk_score += 10 * len(matches)
                elif pattern_name in ['eval_patterns', 'injection_patterns']:
                    risk_score += 15 * len(matches)
                elif pattern_name in ['api_keys', 'credentials']:
                    risk_score += 20 * len(matches)
                elif pattern_name in ['port_scanning', 'network_recon']:
                    risk_score += 12 * len(matches)

        # Adjust for trusted contacts (from Claude Rejection Reducer)
        if self.trusted_contact:
            risk_score = int(risk_score * 0.6)  # 40% risk reduction for trusted

        # Adjust for legitimacy score
        if self.legitimacy_score >= 80:
            risk_score = int(risk_score * 0.5)  # 50% reduction for high legitimacy
        elif self.legitimacy_score >= 60:
            risk_score = int(risk_score * 0.75)  # 25% reduction for medium legitimacy

        # Classify risk level
        if risk_score == 0:
            return RiskLevel.SAFE
        elif risk_score < 15:
            return RiskLevel.LOW
        elif risk_score < 30:
            return RiskLevel.MEDIUM
        elif risk_score < 50:
            return RiskLevel.HIGH
        else:
            return RiskLevel.CRITICAL

    def detect_content_type(self, content: str) -> ContentType:
        """
        Detect the type of content

        Args:
            content: Content to analyze

        Returns:
            ContentType classification
        """
        # Code block detection
        if re.search(r'```[\w]*\n', content) or re.search(r'^\s{4,}', content, re.MULTILINE):
            return ContentType.CODE

        # Command detection
        if re.search(r'^\$\s+', content, re.MULTILINE) or re.search(r'^>\s+', content, re.MULTILINE):
            return ContentType.COMMAND

        # URL detection
        if re.search(r'https?://', content):
            if len(content.split()) < 5:
                return ContentType.URL

        # Check for mixed content
        has_code = bool(re.search(r'[{}\[\]();]', content))
        has_text = bool(re.search(r'\b[a-z]{4,}\b', content, re.IGNORECASE))

        if has_code and has_text:
            return ContentType.MIXED

        return ContentType.TEXT

    def replace_risky_patterns(self, content: str) -> Tuple[str, Dict[str, str]]:
        """
        Replace risky patterns with safe placeholders

        Args:
            content: Content to sanitize

        Returns:
            Tuple of (sanitized_content, replacement_map)
        """
        sanitized = content
        replacements = {}

        for risky_word, placeholder in self.SAFE_PLACEHOLDERS.items():
            pattern = re.compile(r'\b' + re.escape(risky_word) + r'\b', re.IGNORECASE)
            matches = pattern.findall(sanitized)

            if matches:
                # Store original for restoration
                for i, match in enumerate(matches):
                    key = f"{placeholder}_{i}"
                    replacements[key] = match

                # Replace with placeholder
                sanitized = pattern.sub(placeholder, sanitized)

        self.replacement_map.update(replacements)
        return sanitized, replacements

    def wrap_code_safely(self, content: str) -> str:
        """
        Wrap code content in safe markers

        Args:
            content: Code content to wrap

        Returns:
            Safely wrapped code content
        """
        # If already in code block, return as-is
        if re.match(r'^```', content):
            return content

        # Detect language
        if re.search(r'(def|class|import)\s+', content):
            lang = 'python'
        elif re.search(r'(function|const|let|var)\s+', content):
            lang = 'javascript'
        elif re.search(r'(public|private|class)\s+', content):
            lang = 'java'
        else:
            lang = 'text'

        return f"```{lang}\n{content}\n```"

    def chop_content(self, content: str, max_chunk_size: int = 2000) -> List[ContentSegment]:
        """
        Intelligently chop content into segments

        Args:
            content: Content to chop
            max_chunk_size: Maximum size per chunk

        Returns:
            List of ContentSegment objects
        """
        segments = []

        # Simple sentence-based chunking for now
        sentences = re.split(r'([.!?]\s+)', content)
        current_chunk = ""
        current_pos = 0

        for sentence in sentences:
            if len(current_chunk) + len(sentence) > max_chunk_size and current_chunk:
                # Create segment
                content_type = self.detect_content_type(current_chunk)
                risk_level = self.assess_content_risk(current_chunk)
                sanitized, replacements = self.replace_risky_patterns(current_chunk)

                segment = ContentSegment(
                    content=sanitized,
                    content_type=content_type,
                    risk_level=risk_level,
                    original_content=current_chunk,
                    replacements=replacements,
                    start_pos=current_pos,
                    end_pos=current_pos + len(current_chunk),
                    metadata={
                        'trusted_contact': self.trusted_contact,
                        'legitimacy_score': self.legitimacy_score
                    }
                )
                segments.append(segment)

                current_pos += len(current_chunk)
                current_chunk = sentence
            else:
                current_chunk += sentence

        # Add final chunk
        if current_chunk:
            content_type = self.detect_content_type(current_chunk)
            risk_level = self.assess_content_risk(current_chunk)
            sanitized, replacements = self.replace_risky_patterns(current_chunk)

            segment = ContentSegment(
                content=sanitized,
                content_type=content_type,
                risk_level=risk_level,
                original_content=current_chunk,
                replacements=replacements,
                start_pos=current_pos,
                end_pos=current_pos + len(current_chunk),
                metadata={
                    'trusted_contact': self.trusted_contact,
                    'legitimacy_score': self.legitimacy_score
                }
            )
            segments.append(segment)

        return segments

    def restore_original_content(self, sanitized: str) -> str:
        """
        Restore original content from sanitized version

        Args:
            sanitized: Sanitized content with placeholders

        Returns:
            Original content with placeholders restored
        """
        restored = sanitized

        for placeholder, original in self.replacement_map.items():
            restored = restored.replace(placeholder, original)

        return restored

    def get_statistics(self, segments: List[ContentSegment]) -> Dict:
        """
        Get statistics about chopped content

        Args:
            segments: List of content segments

        Returns:
            Dictionary with statistics
        """
        return {
            'total_segments': len(segments),
            'risk_distribution': {
                risk.value: sum(1 for s in segments if s.risk_level == risk)
                for risk in RiskLevel
            },
            'content_types': {
                ctype.value: sum(1 for s in segments if s.content_type == ctype)
                for ctype in ContentType
            },
            'total_replacements': sum(len(s.replacements) for s in segments),
            'trusted_contact': self.trusted_contact,
            'legitimacy_score': self.legitimacy_score
        }


def main():
    """Example usage"""
    # Example with trusted contact (from Claude Rejection Reducer)
    chopper = IntelligentContextChopper(trusted_contact=True, legitimacy_score=85)

    sample_content = """
    Here's how to delete old log files:

    sudo rm -rf /var/log/old_logs/*

    Be careful with this command as it permanently removes files.
    """

    segments = chopper.chop_content(sample_content)

    print("Chopped Content Analysis:")
    print("=" * 60)
    for i, segment in enumerate(segments, 1):
        print(f"\nSegment {i}:")
        print(f"  Type: {segment.content_type.value}")
        print(f"  Risk: {segment.risk_level.value}")
        print(f"  Replacements: {len(segment.replacements)}")
        print(f"  Sanitized: {segment.content[:100]}...")

    print("\n" + "=" * 60)
    print("Statistics:")
    stats = chopper.get_statistics(segments)
    print(json.dumps(stats, indent=2))


if __name__ == "__main__":
    main()
