# Claude Rejection Reducer - Comprehensive Documentation

## Table of Contents
1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Component Details](#component-details)
4. [Configuration](#configuration)
5. [Integration Guide](#integration-guide)
6. [Usage Examples](#usage-examples)
7. [Statistics & Monitoring](#statistics--monitoring)
8. [Best Practices](#best-practices)

---

## Overview

The **Claude Rejection Reducer** is a sophisticated two-layer system designed to prevent and detect wrongful rejections of legitimate communication requests in the SWORDCOMM messaging platform.

### Dual-Layer Protection

```
┌─────────────────────────────────────────────────────────────────┐
│                    LAYER 1: PREVENTION                          │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Content Optimization Bridge                              │  │
│  │  ↓                                                        │  │
│  │ Intelligent Context Chopper                              │  │
│  │  ↓                                                        │  │
│  │ Integrated Context Optimizer                             │  │
│  │  ↓                                                        │  │
│  │ Token Optimizer                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                           ↓                                     │
│                   Optimized Content                             │
│                           ↓                                     │
│                      Send Message                               │
│                           ↓                                     │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    LAYER 2: DETECTION                           │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Claude Rejection Reducer                                 │  │
│  │  - Analyzes send results                                 │  │
│  │  - Detects false positives                               │  │
│  │  - Tracks legitimacy scores                              │  │
│  │  - Generates retry recommendations                       │  │
│  │  - Comprehensive statistics                              │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Features

✅ **Proactive Prevention**: Optimizes content BEFORE sending to avoid rejections
✅ **Reactive Detection**: Identifies wrongful rejections AFTER sending
✅ **Legitimacy Scoring**: Multi-factor reputation assessment (0-100)
✅ **Trusted Contact Recognition**: Priority treatment for known contacts
✅ **False Positive Detection**: Automatic identification of wrongful rejections
✅ **Adaptive Optimization**: Strategy based on legitimacy score
✅ **Comprehensive Statistics**: Full visibility into all operations
✅ **Easy Configuration**: Single config file for all settings

---

## System Architecture

### Core Components

#### 1. **RejectionReducerConfig.java**
- Centralized configuration for entire system
- 30+ tunable parameters
- 4 preset modes (STRICT, LENIENT, BALANCED, DEBUG)
- Validation and utilities

**Location**: `app/src/main/java/org/thoughtcrime/securesms/jobs/RejectionReducerConfig.java`

#### 2. **GroupSendJobHelper.java (Claude Rejection Reducer)**
- Post-send result analysis
- Legitimacy scoring
- False positive detection
- Retry recommendations
- Comprehensive statistics

**Location**: `app/src/main/java/org/thoughtcrime/securesms/jobs/GroupSendJobHelper.java`

#### 3. **ContentOptimizationBridge.java**
- Java integration layer
- Bridges Android app with Python scripts
- Legitimacy assessment
- Optimization pipeline orchestration
- Caching and statistics

**Location**: `app/src/main/java/org/thoughtcrime/securesms/jobs/ContentOptimizationBridge.java`

#### 4. **intelligent_context_chopper.py**
- Content segmentation
- Risk assessment
- Pattern detection
- Safe placeholder replacement
- Code block detection

**Location**: `scripts/intelligent_context_chopper.py`

#### 5. **integrated_context_optimizer.py**
- Multi-strategy optimization
- Risk reduction
- Legitimacy preservation
- Comprehensive analytics

**Location**: `scripts/integrated_context_optimizer.py`

#### 6. **token_optimizer.py**
- Token usage reduction
- Quality preservation
- Compression level management
- Legitimacy-aware optimization

**Location**: `scripts/token_optimizer.py`

---

## Component Details

### Legitimacy Scoring System

The same scoring methodology is used across ALL components:

```
Base Score: 50 (neutral)

+25 points: System Contact (in device address book)
+15 points: Profile Sharing OR User-Set Display Name
+10 points: Group Membership

Maximum Score: 100
Trusted Threshold: >= 80 (configurable)
High Reputation: >= 60 (configurable)
```

**Classification Levels**:
- **TRUSTED** (>= 80): Minimal interference, pass-through optimization
- **HIGH_REPUTATION** (>= 60): Light optimization
- **MEDIUM** (>= 50): Balanced optimization
- **LOW** (< 50): Aggressive optimization

### Optimization Strategies

#### 1. **PASSTHROUGH** (Trusted >= 90)
- Minimal changes
- Only remove extremely sensitive data (API keys)
- Preserve original intent completely
- Used for: Very trusted contacts

#### 2. **MINIMAL** (Legitimacy >= 80)
- Light sanitization
- Only sanitize HIGH/CRITICAL risk patterns
- Preserve most content as-is
- Used for: Trusted contacts

#### 3. **BALANCED** (Legitimacy >= 60)
- Moderate sanitization
- Sanitize MEDIUM+ risk patterns
- Balance safety and functionality
- Used for: Known contacts

#### 4. **AGGRESSIVE** (Legitimacy < 60)
- Heavy sanitization
- Sanitize all non-safe patterns
- Wrap code in safe blocks
- Prioritize safety over functionality
- Used for: Unknown or low-reputation contacts

### Risk Levels

```
SAFE (0 points):
- No risky patterns detected
- Safe to send as-is

LOW (< 15 points):
- Minor concerns
- Light optimization recommended

MEDIUM (15-30 points):
- Moderate concerns
- Standard optimization recommended

HIGH (30-50 points):
- Significant concerns
- Aggressive optimization recommended

CRITICAL (>= 50 points):
- Severe concerns
- Maximum sanitization required
```

### Pattern Detection

**Risky Patterns**:
- Shell commands: `rm`, `dd`, `mkfs`, `format`, `del`, `destroy`, `kill`
- Privilege escalation: `sudo`, `su`, `doas`
- Code execution: `eval`, `exec`, `system`, `shell_exec`
- Injection: `;`, `|`, `&&`, command chaining
- Credentials: API keys, passwords, tokens
- Network scanning: `nmap`, `netcat`, `masscan`

**Safe Placeholders**:
```
rm       → [REMOVE_CMD]
dd       → [DISK_CMD]
sudo     → [PRIVILEGE_CMD]
eval     → [EVAL_FUNC]
exec     → [EXEC_FUNC]
system   → [SYSTEM_FUNC]
```

---

## Configuration

### Quick Configuration Guide

Edit `RejectionReducerConfig.java`:

#### Production (Balanced)
```java
TRUSTED_THRESHOLD = 80
HIGH_REPUTATION_THRESHOLD = 60
ENABLE_FALSE_POSITIVE_DETECTION = true
ENABLE_DETAILED_LOGGING = true
ENABLE_AGGRESSIVE_RETRY = false
```

#### Strict Mode
```java
TRUSTED_THRESHOLD = 90
HIGH_REPUTATION_THRESHOLD = 70
ENABLE_FALSE_POSITIVE_DETECTION = false
ENABLE_AGGRESSIVE_RETRY = false
```

#### Lenient Mode
```java
TRUSTED_THRESHOLD = 70
HIGH_REPUTATION_THRESHOLD = 55
ENABLE_FALSE_POSITIVE_DETECTION = true
ENABLE_AGGRESSIVE_RETRY = true
```

#### Debug Mode
```java
ENABLE_DETAILED_LOGGING = true
LOG_ALL_LEGITIMACY_SCORES = true
ALERT_ON_ALL_FALSE_POSITIVES = true
LOG_OVERRIDE_RECOMMENDATIONS = true
ENABLE_VISUAL_SUMMARY = true
```

### Key Configuration Parameters

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `TRUSTED_THRESHOLD` | 80 | 60-100 | Score needed for trusted status |
| `HIGH_REPUTATION_THRESHOLD` | 60 | 50-80 | Score for high reputation |
| `SYSTEM_CONTACT_POINTS` | 25 | 15-35 | Points for system contacts |
| `PROFILE_SHARING_POINTS` | 15 | 10-25 | Points for profile sharing |
| `GROUP_MEMBERSHIP_POINTS` | 10 | 5-20 | Points for group members |
| `ENABLE_FALSE_POSITIVE_DETECTION` | true | bool | Master switch for FP detection |
| `FLAG_TRUSTED_CONTACT_FAILURES` | true | bool | Flag trusted failures as FP |
| `PRIORITIZE_TRUSTED_RETRIES` | true | bool | High priority for trusted |
| `ENABLE_DETAILED_LOGGING` | true | bool | Detailed log output |
| `ENABLE_VISUAL_SUMMARY` | true | bool | Box-drawing summary tables |

---

## Integration Guide

### Basic Integration

#### 1. Before Sending (Prevention Layer)

```java
import org.thoughtcrime.securesms.jobs.ContentOptimizationBridge;
import org.thoughtcrime.securesms.jobs.ContentOptimizationBridge.OptimizationResult;

// In your message sending code
String originalMessage = "sudo rm -rf /tmp/cache/*";
Recipient recipient = getRecipient();

// Optimize content based on legitimacy
OptimizationResult result = ContentOptimizationBridge.optimizeContent(
    originalMessage,
    recipient
);

// Use optimized content
String messageToSend = result.getContentForSending();

// Send the message
sendMessage(messageToSend, recipient);
```

#### 2. After Sending (Detection Layer)

```java
import org.thoughtcrime.securesms.jobs.GroupSendJobHelper;
import org.thoughtcrime.securesms.jobs.GroupSendJobHelper.SendResult;

// After message sending
List<Recipient> recipients = getRecipients();
Collection<SendMessageResult> results = getSendResults();

// Analyze results
SendResult analysisResult = GroupSendJobHelper.getCompletedSends(
    recipients,
    results
);

// Check for false positives
if (analysisResult.hasSuspectedFalsePositives()) {
    Log.w(TAG, "Suspected false positives detected!");

    for (RecipientId recipientId : analysisResult.suspectedFalsePositives) {
        String recommendation = analysisResult.getOverrideRecommendation(recipientId);
        Log.i(TAG, "Retry recommendation for " + recipientId + ": " + recommendation);
    }
}

// Check for trusted contact failures (critical)
if (analysisResult.hasTrustedContactFailures()) {
    Log.e(TAG, "CRITICAL: Trusted contacts failed!");
    // Take immediate action
}
```

### Python Script Usage (Standalone)

#### Intelligent Context Chopper

```python
from intelligent_context_chopper import IntelligentContextChopper

# Initialize with context from Claude Rejection Reducer
chopper = IntelligentContextChopper(
    trusted_contact=True,
    legitimacy_score=85
)

content = "sudo rm -rf /tmp/old_logs/*"

# Chop content into segments
segments = chopper.chop_content(content)

for segment in segments:
    print(f"Type: {segment.content_type.value}")
    print(f"Risk: {segment.risk_level.value}")
    print(f"Content: {segment.content}")
```

#### Integrated Context Optimizer

```python
from integrated_context_optimizer import IntegratedContextOptimizer

optimizer = IntegratedContextOptimizer()

# Optimize content
result = optimizer.optimize_content(
    content="rm -rf /tmp/cache",
    legitimacy_score=75,
    trusted_contact=False
)

print(f"Strategy: {result.strategy_used.value}")
print(f"Risk Reduction: {result.risk_reduction:.1f}%")
print(f"Optimized: {result.optimized_content}")
```

#### Token Optimizer

```python
from token_optimizer import TokenOptimizer

optimizer = TokenOptimizer()

# Optimize tokens
result = optimizer.optimize_tokens(
    content="long text here...",
    legitimacy_score=80,
    trusted_contact=True
)

print(f"Tokens Saved: {result.tokens_saved}")
print(f"Compression: {(1-result.compression_ratio)*100:.1f}%")
```

---

## Usage Examples

### Example 1: Trusted Contact with Legitimate Technical Content

```java
// Scenario: System admin discussing server maintenance
Recipient admin = getSystemAdminContact();  // legitimacy_score = 90

String message = """
    To clean up disk space:
    sudo rm -rf /var/log/old/*
    sudo apt-get clean
    sudo systemctl restart service
    """;

// Optimize (will use PASSTHROUGH strategy)
OptimizationResult opt = ContentOptimizationBridge.optimizeContent(message, admin);
// Output: Minimal changes, API keys redacted if any

// Send and analyze
sendMessage(opt.getContentForSending(), admin);
SendResult result = GroupSendJobHelper.getCompletedSends(...);

// Expected: Success, no false positives
// If rejection occurs: Flagged as CRITICAL trusted contact failure
```

### Example 2: Unknown Contact with Suspicious Patterns

```java
// Scenario: Unknown contact sending potentially risky content
Recipient unknown = getUnknownContact();  // legitimacy_score = 45

String message = "Execute: sudo rm -rf / --no-preserve-root";

// Optimize (will use AGGRESSIVE strategy)
OptimizationResult opt = ContentOptimizationBridge.optimizeContent(message, unknown);
// Output: Heavy sanitization, wrapped in safe code blocks
// "Execute: [PRIVILEGE_CMD] [REMOVE_CMD] -rf / --no-preserve-root"

// Send and analyze
sendMessage(opt.getContentForSending(), unknown);
SendResult result = GroupSendJobHelper.getCompletedSends(...);

// Expected: If rejected, classified as legitimate rejection
```

### Example 3: Medium Legitimacy Contact

```java
// Scenario: Known contact, not fully trusted
Recipient contact = getKnownContact();  // legitimacy_score = 65

String message = "Run: nmap -p 1-65535 192.168.1.0/24";

// Optimize (will use BALANCED strategy)
OptimizationResult opt = ContentOptimizationBridge.optimizeContent(message, contact);
// Output: Moderate sanitization
// "Run: [SCAN_TOOL] -p 1-65535 192.168.1.0/24"

// Send and analyze
SendResult result = GroupSendJobHelper.getCompletedSends(...);

// Check for false positives
if (result.hasSuspectedFalsePositives()) {
    // May be flagged depending on actual rejection
}
```

---

## Statistics & Monitoring

### Viewing Statistics

#### Claude Rejection Reducer Statistics

```java
SendResult result = GroupSendJobHelper.getCompletedSends(...);
SendResultStatistics stats = result.statistics;

Log.i(TAG, "Total Results: " + stats.totalResults);
Log.i(TAG, "Success Rate: " + stats.getSuccessPercentage() + "%");
Log.i(TAG, "False Positive Rate: " + stats.getFalsePositiveRate() + "%");
Log.i(TAG, "Trusted Contact Failures: " + stats.trustedContactFailureCount);
```

#### Content Optimization Statistics

```java
Map<String, Object> stats = ContentOptimizationBridge.getStatistics();

Log.i(TAG, "Total Optimizations: " + stats.get("total_optimizations"));
Log.i(TAG, "Cache Hit Rate: " + stats.get("cache_hit_rate") + "%");
Log.i(TAG, "Script Executions: " + stats.get("script_executions"));
Log.i(TAG, "Failure Rate: " + stats.get("failure_rate") + "%");
```

### Log Output Example

```
┌─────────────────────────────────────────────────────────
│ [Claude Rejection Reducer] Send Results Summary
├─────────────────────────────────────────────────────────
│ Total Results:      10
│ ✓ Successful:       7 (70%)
│ ✗ Failed:           3 (30%)
├─────────────────────────────────────────────────────────
│ Failure Breakdown:
│   • Network:        2 [RETRYABLE]
│   • Identity:       0
│   • Unregistered:   1 [PERMANENT]
│   • Rate Limited:   0
│   • Proof Required: 0
│   • Invalid PreKey: 0
├─────────────────────────────────────────────────────────
│ Legitimacy Analysis (Wrongful Rejection Prevention):
│   ⚠️  False Positives:  1 [NEEDS_REVIEW]
│   ⭐ Trusted Contacts: 5
│   🚨 Trusted Failed:   1 [CRITICAL]
│   ✓ Legit Rejections: 2
├─────────────────────────────────────────────────────────
│ Retry Analysis:
│   Retryable:        2 failures can be retried
│   Processing Time:  15ms
└─────────────────────────────────────────────────────────
```

---

## Best Practices

### 1. Configuration
- Start with BALANCED preset
- Monitor false positive rates
- Adjust thresholds based on your user base
- Enable detailed logging in production initially

### 2. Trusted Contacts
- Ensure system contacts are properly identified
- Enable profile sharing with trusted contacts
- Review trusted contact failures immediately

### 3. Content Optimization
- Don't disable optimization for trusted contacts entirely
- Use PASSTHROUGH for very trusted (>= 90 legitimacy)
- Cache frequently used optimizations
- Monitor token savings

### 4. False Positive Handling
- Review all suspected false positives
- Track false positive rate trends
- Implement automatic retry for trusted contacts
- Alert on high false positive rates (>= 30%)

### 5. Monitoring
- Log all CRITICAL events (trusted contact failures)
- Track legitimacy score distribution
- Monitor optimization cache performance
- Review statistics regularly

### 6. Security
- Never disable legitimacy scoring in production
- Keep `FLAG_IDENTITY_FAILURES_AS_FALSE_POSITIVE = false`
- Review security-sensitive configurations
- Audit pattern replacement rules regularly

---

## File Locations

```
SWORDCOMM/
├── app/src/main/java/org/thoughtcrime/securesms/jobs/
│   ├── RejectionReducerConfig.java          (550 lines)
│   ├── GroupSendJobHelper.java              (800+ lines)
│   └── ContentOptimizationBridge.java       (280 lines)
│
└── scripts/
    ├── intelligent_context_chopper.py       (440 lines)
    ├── integrated_context_optimizer.py      (380 lines)
    └── token_optimizer.py                   (420 lines)
```

**Total System**: ~2,870 lines of code

---

## Version History

**v1.0** - Initial Claude Rejection Reducer
**v2.0** - Wrongful Rejection Prevention
**v3.0** - Easy Configuration File
**v4.0** - Intelligent Content Optimization System (Current)

---

## Support & Contribution

For issues, questions, or contributions related to the Claude Rejection Reducer:

1. Review this documentation
2. Check configuration settings
3. Review logs for detailed error information
4. Consult statistics for system health

---

## License

Part of SWORDCOMM Secure Messaging Platform
