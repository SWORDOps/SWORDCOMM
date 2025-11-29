# Claude Rejection Reducer - Configuration Knobs Reference

Quick reference guide for all tunable configuration parameters.

---

## 🎛️ Quick Configuration Templates

### Copy-Paste Ready Configurations

#### 1. Production (Balanced) - RECOMMENDED
```java
// Core Legitimacy Scoring
TRUSTED_THRESHOLD = 80
HIGH_REPUTATION_THRESHOLD = 60
NEUTRAL_BASELINE_SCORE = 50

// Scoring Weights
SYSTEM_CONTACT_POINTS = 25
PROFILE_SHARING_POINTS = 15
GROUP_MEMBERSHIP_POINTS = 10

// False Positive Detection
ENABLE_FALSE_POSITIVE_DETECTION = true
FLAG_TRUSTED_CONTACT_FAILURES = true
FLAG_HIGH_REP_TRANSIENT_FAILURES = true
FLAG_SYSTEM_CONTACT_NETWORK_FAILURES = true
FLAG_PROOF_REQUIRED_AS_FALSE_POSITIVE = false
FLAG_IDENTITY_FAILURES_AS_FALSE_POSITIVE = false

// Retry Behavior
ENABLE_AGGRESSIVE_RETRY = false
PRIORITIZE_TRUSTED_RETRIES = true

// Logging
ENABLE_DETAILED_LOGGING = true
LOG_ALL_LEGITIMACY_SCORES = false
ALERT_ON_ALL_FALSE_POSITIVES = true
LOG_OVERRIDE_RECOMMENDATIONS = true
ENABLE_VISUAL_SUMMARY = true

// Feature Flags
ENABLE_LEGITIMACY_SCORING = true
ENABLE_OVERRIDE_RECOMMENDATIONS = true
ENABLE_TRUSTED_CONTACT_TRACKING = true
```

#### 2. Strict Mode (Conservative)
```java
// Core Legitimacy Scoring
TRUSTED_THRESHOLD = 90              // ← Increased
HIGH_REPUTATION_THRESHOLD = 70      // ← Increased
NEUTRAL_BASELINE_SCORE = 50

// Scoring Weights
SYSTEM_CONTACT_POINTS = 20          // ← Reduced
PROFILE_SHARING_POINTS = 10         // ← Reduced
GROUP_MEMBERSHIP_POINTS = 5         // ← Reduced

// False Positive Detection
ENABLE_FALSE_POSITIVE_DETECTION = false  // ← DISABLED
FLAG_TRUSTED_CONTACT_FAILURES = false
FLAG_HIGH_REP_TRANSIENT_FAILURES = false
FLAG_SYSTEM_CONTACT_NETWORK_FAILURES = false
FLAG_PROOF_REQUIRED_AS_FALSE_POSITIVE = false
FLAG_IDENTITY_FAILURES_AS_FALSE_POSITIVE = false

// Retry Behavior
ENABLE_AGGRESSIVE_RETRY = false
PRIORITIZE_TRUSTED_RETRIES = false

// Logging
ENABLE_DETAILED_LOGGING = true
LOG_ALL_LEGITIMACY_SCORES = false
ALERT_ON_ALL_FALSE_POSITIVES = false
LOG_OVERRIDE_RECOMMENDATIONS = false
ENABLE_VISUAL_SUMMARY = true

// Feature Flags
ENABLE_LEGITIMACY_SCORING = true
ENABLE_OVERRIDE_RECOMMENDATIONS = false
ENABLE_TRUSTED_CONTACT_TRACKING = false
```

#### 3. Lenient Mode (Aggressive Retry)
```java
// Core Legitimacy Scoring
TRUSTED_THRESHOLD = 70              // ← Decreased
HIGH_REPUTATION_THRESHOLD = 55      // ← Decreased
NEUTRAL_BASELINE_SCORE = 50

// Scoring Weights
SYSTEM_CONTACT_POINTS = 30          // ← Increased
PROFILE_SHARING_POINTS = 20         // ← Increased
GROUP_MEMBERSHIP_POINTS = 15        // ← Increased

// False Positive Detection
ENABLE_FALSE_POSITIVE_DETECTION = true
FLAG_TRUSTED_CONTACT_FAILURES = true
FLAG_HIGH_REP_TRANSIENT_FAILURES = true
FLAG_SYSTEM_CONTACT_NETWORK_FAILURES = true
FLAG_PROOF_REQUIRED_AS_FALSE_POSITIVE = true   // ← ENABLED
FLAG_IDENTITY_FAILURES_AS_FALSE_POSITIVE = false

// Retry Behavior
ENABLE_AGGRESSIVE_RETRY = true      // ← ENABLED
PRIORITIZE_TRUSTED_RETRIES = true

// Logging
ENABLE_DETAILED_LOGGING = true
LOG_ALL_LEGITIMACY_SCORES = true
ALERT_ON_ALL_FALSE_POSITIVES = true
LOG_OVERRIDE_RECOMMENDATIONS = true
ENABLE_VISUAL_SUMMARY = true

// Feature Flags
ENABLE_LEGITIMACY_SCORING = true
ENABLE_OVERRIDE_RECOMMENDATIONS = true
ENABLE_TRUSTED_CONTACT_TRACKING = true
```

#### 4. Debug Mode (Maximum Visibility)
```java
// Core Legitimacy Scoring
TRUSTED_THRESHOLD = 80
HIGH_REPUTATION_THRESHOLD = 60
NEUTRAL_BASELINE_SCORE = 50

// Scoring Weights
SYSTEM_CONTACT_POINTS = 25
PROFILE_SHARING_POINTS = 15
GROUP_MEMBERSHIP_POINTS = 10

// False Positive Detection
ENABLE_FALSE_POSITIVE_DETECTION = true
FLAG_TRUSTED_CONTACT_FAILURES = true
FLAG_HIGH_REP_TRANSIENT_FAILURES = true
FLAG_SYSTEM_CONTACT_NETWORK_FAILURES = true
FLAG_PROOF_REQUIRED_AS_FALSE_POSITIVE = false
FLAG_IDENTITY_FAILURES_AS_FALSE_POSITIVE = false

// Retry Behavior
ENABLE_AGGRESSIVE_RETRY = false
PRIORITIZE_TRUSTED_RETRIES = true

// Logging - ALL ENABLED
ENABLE_DETAILED_LOGGING = true      // ← ENABLED
LOG_ALL_LEGITIMACY_SCORES = true    // ← ENABLED (VERBOSE!)
ALERT_ON_ALL_FALSE_POSITIVES = true // ← ENABLED
LOG_OVERRIDE_RECOMMENDATIONS = true  // ← ENABLED
ENABLE_VISUAL_SUMMARY = true         // ← ENABLED

// Feature Flags
ENABLE_LEGITIMACY_SCORING = true
ENABLE_OVERRIDE_RECOMMENDATIONS = true
ENABLE_TRUSTED_CONTACT_TRACKING = true
```

#### 5. Minimal Interference (Trust Everyone)
```java
// Core Legitimacy Scoring
TRUSTED_THRESHOLD = 60              // ← Very low
HIGH_REPUTATION_THRESHOLD = 50      // ← Very low
NEUTRAL_BASELINE_SCORE = 60         // ← Higher baseline

// Scoring Weights
SYSTEM_CONTACT_POINTS = 30          // ← Increased
PROFILE_SHARING_POINTS = 20         // ← Increased
GROUP_MEMBERSHIP_POINTS = 15        // ← Increased

// False Positive Detection
ENABLE_FALSE_POSITIVE_DETECTION = true
FLAG_TRUSTED_CONTACT_FAILURES = true
FLAG_HIGH_REP_TRANSIENT_FAILURES = true
FLAG_SYSTEM_CONTACT_NETWORK_FAILURES = true
FLAG_PROOF_REQUIRED_AS_FALSE_POSITIVE = true
FLAG_IDENTITY_FAILURES_AS_FALSE_POSITIVE = false  // NEVER enable this!

// Retry Behavior
ENABLE_AGGRESSIVE_RETRY = true
PRIORITIZE_TRUSTED_RETRIES = true

// Logging
ENABLE_DETAILED_LOGGING = true
LOG_ALL_LEGITIMACY_SCORES = false
ALERT_ON_ALL_FALSE_POSITIVES = true
LOG_OVERRIDE_RECOMMENDATIONS = true
ENABLE_VISUAL_SUMMARY = true

// Feature Flags
ENABLE_LEGITIMACY_SCORING = true
ENABLE_OVERRIDE_RECOMMENDATIONS = true
ENABLE_TRUSTED_CONTACT_TRACKING = true
```

#### 6. Disabled (Turn Everything Off)
```java
// Core Legitimacy Scoring
TRUSTED_THRESHOLD = 80
HIGH_REPUTATION_THRESHOLD = 60
NEUTRAL_BASELINE_SCORE = 50

// Scoring Weights
SYSTEM_CONTACT_POINTS = 25
PROFILE_SHARING_POINTS = 15
GROUP_MEMBERSHIP_POINTS = 10

// False Positive Detection
ENABLE_FALSE_POSITIVE_DETECTION = false  // ← DISABLED
FLAG_TRUSTED_CONTACT_FAILURES = false
FLAG_HIGH_REP_TRANSIENT_FAILURES = false
FLAG_SYSTEM_CONTACT_NETWORK_FAILURES = false
FLAG_PROOF_REQUIRED_AS_FALSE_POSITIVE = false
FLAG_IDENTITY_FAILURES_AS_FALSE_POSITIVE = false

// Retry Behavior
ENABLE_AGGRESSIVE_RETRY = false
PRIORITIZE_TRUSTED_RETRIES = false

// Logging
ENABLE_DETAILED_LOGGING = false      // ← DISABLED
LOG_ALL_LEGITIMACY_SCORES = false
ALERT_ON_ALL_FALSE_POSITIVES = false
LOG_OVERRIDE_RECOMMENDATIONS = false
ENABLE_VISUAL_SUMMARY = false

// Feature Flags
ENABLE_LEGITIMACY_SCORING = false    // ← DISABLED (Master switch)
ENABLE_OVERRIDE_RECOMMENDATIONS = false
ENABLE_TRUSTED_CONTACT_TRACKING = false
```

---

## 📊 All Configuration Knobs (Alphabetical)

### A-E

#### `ALERT_ON_ALL_FALSE_POSITIVES`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Alert (WARN level) on every suspected false positive
- **Impact**: Individual alert for each false positive detection
- **Recommendation**:
  - `true`: Maximum visibility (default)
  - `false`: Only summary alerts

---

#### `ENABLE_AGGRESSIVE_RETRY`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Enable aggressive retry for suspected false positives
- **Impact**: Suspected false positives get immediate retry recommendations
- **Recommendation**:
  - `true`: Maximize delivery for trusted contacts
  - `false`: Use standard retry logic (default)

---

#### `ENABLE_DETAILED_LOGGING`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Enable detailed legitimacy analysis logging
- **Impact**: Show full legitimacy analysis section in logs
- **Recommendation**:
  - `true`: Full visibility into false positive detection (default)
  - `false`: Minimal logging, only critical alerts

---

#### `ENABLE_FALSE_POSITIVE_DETECTION`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Master switch for false positive detection system
- **Impact**: When disabled, no false positive analysis is performed
- **Recommendation**: Keep enabled unless you want to disable all wrongful rejection prevention features

---

#### `ENABLE_LEGITIMACY_SCORING`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Master switch for entire legitimacy analysis
- **Impact**: Controls entire legitimacy scoring system
- **Recommendation**: Only disable for testing/comparison purposes

---

#### `ENABLE_OVERRIDE_RECOMMENDATIONS`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Enable reputation-based override recommendations
- **Impact**: Generate specific retry guidance for failures
- **Recommendation**: Keep enabled for actionable insights

---

#### `ENABLE_TRUSTED_CONTACT_TRACKING`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Enable trusted contact identification and tracking
- **Impact**: Track and prioritize trusted contacts
- **Recommendation**: Keep enabled for optimal delivery

---

#### `ENABLE_VISUAL_SUMMARY`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Show visual summary box in logs
- **Impact**: Display formatted box-drawing summary table
- **Recommendation**:
  - `true`: Better readability (default)
  - `false`: Plain text logging

---

### F-L

#### `FLAG_HIGH_REP_TRANSIENT_FAILURES`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Detect false positives for high-reputation recipients with transient failures
- **Impact**: Network/rate-limit failures on good recipients are suspicious
- **Recommendation**: Keep enabled for best false positive detection

---

#### `FLAG_IDENTITY_FAILURES_AS_FALSE_POSITIVE`
- **Type**: `boolean`
- **Default**: `false` ⚠️ **SECURITY SENSITIVE**
- **Description**: Consider identity failures as potential false positives for trusted contacts
- **Impact**: Even trusted contacts can have identity key changes
- **WARNING**: Identity failures are security-sensitive!
- **Recommendation**: Keep disabled (false) for security

---

#### `FLAG_PROOF_REQUIRED_AS_FALSE_POSITIVE`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Consider proof-required failures as potential false positives
- **Impact**: Proof/captcha requirements might be overly aggressive
- **Recommendation**:
  - `true`: If you think proof challenges are too aggressive
  - `false`: Proof challenges are legitimate security measures (default)

---

#### `FLAG_SYSTEM_CONTACT_NETWORK_FAILURES`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Detect false positives for system contacts with network failures
- **Impact**: System contacts with network issues get benefit of doubt
- **Recommendation**:
  - `true`: System contacts are trusted (default)
  - `false`: System contacts treated same as others

---

#### `FLAG_TRUSTED_CONTACT_FAILURES`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Detect false positives for trusted contacts (>= TRUSTED_THRESHOLD)
- **Impact**: Any failure for trusted contacts flagged as suspicious
- **Recommendation**:
  - `true`: Trusted contacts should rarely fail (default)
  - `false`: Even trusted contacts can have legitimate failures

---

#### `GROUP_MEMBERSHIP_POINTS`
- **Type**: `int`
- **Default**: `10`
- **Range**: `5-20`
- **Description**: Points awarded for group membership
- **Impact**: Trust based on shared group context
- **Recommendation**:
  - `15+`: Group context is very important
  - `10`: Balanced (default)
  - `5`: Group membership is minor factor

---

#### `HIGH_FALSE_POSITIVE_RATE_THRESHOLD`
- **Type**: `int`
- **Default**: `30`
- **Range**: `20-50`
- **Description**: Percentage threshold for high false positive rate warning (0-100)
- **Impact**: When to warn about concerning false positive rates
- **Recommendation**:
  - `40+`: Only warn on very high rates
  - `30`: Balanced warning threshold (default)
  - `20`: Warn early on elevated rates

---

#### `HIGH_REPUTATION_THRESHOLD`
- **Type**: `int`
- **Default**: `60`
- **Range**: `50-80`
- **Description**: Reputation score threshold for high-reputation recipients
- **Impact**: Determines which recipients get benefit of doubt on transient failures
- **Recommendation**:
  - `70+`: Conservative, only very reliable contacts
  - `60`: Balanced (default)
  - `50`: Liberal, give most contacts benefit of doubt

---

#### `LOG_ALL_LEGITIMACY_SCORES`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Log legitimacy scores for all recipients (including successful sends)
- **Impact**: Verbose logging of every legitimacy assessment
- **Recommendation**:
  - `true`: Debug/testing only - VERY VERBOSE
  - `false`: Only log failures and notable events (default)

---

#### `LOG_OVERRIDE_RECOMMENDATIONS`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Log override recommendations even at INFO level
- **Impact**: Show retry recommendations without DEBUG logging
- **Recommendation**: Keep enabled for actionable insights

---

### M-S

#### `MAX_LEGITIMACY_SCORE`
- **Type**: `int`
- **Default**: `100`
- **Range**: `100` (fixed)
- **Description**: Maximum legitimacy score possible (ceiling)
- **Impact**: Maximum reputation score
- **Recommendation**: DO NOT CHANGE

---

#### `MIN_LEGITIMACY_SCORE`
- **Type**: `int`
- **Default**: `0`
- **Range**: `0` (fixed)
- **Description**: Minimum legitimacy score possible (floor)
- **Impact**: Minimum reputation score
- **Recommendation**: DO NOT CHANGE

---

#### `NEUTRAL_BASELINE_SCORE`
- **Type**: `int`
- **Default**: `50`
- **Range**: `30-70`
- **Description**: Baseline neutral reputation score for unknown recipients
- **Impact**: Starting point for legitimacy calculations
- **Recommendation**: Keep at 50 unless you have specific needs

---

#### `PRIORITIZE_TRUSTED_RETRIES`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Prioritize trusted contact retries over other failures
- **Impact**: Trusted contacts marked as HIGH_PRIORITY_RETRY
- **Recommendation**: Keep enabled to prioritize important contacts

---

#### `PROFILE_SHARING_POINTS`
- **Type**: `int`
- **Default**: `15`
- **Range**: `10-25`
- **Description**: Points awarded for profile sharing or user-set display name
- **Impact**: Value of established relationship indicators
- **Recommendation**:
  - `20+`: Profile sharing is very important
  - `15`: Balanced (default)
  - `10`: Profile sharing is nice but not critical

---

#### `SUSPICIOUS_FAILURE_THRESHOLD`
- **Type**: `int`
- **Default**: `3`
- **Range**: `2-5`
- **Description**: Minimum consecutive failures before marking recipient as suspicious
- **Impact**: How many failures before losing trust
- **Note**: Currently defined but not yet implemented in the logic (future enhancement)

---

#### `SYSTEM_CONTACT_POINTS`
- **Type**: `int`
- **Default**: `25`
- **Range**: `15-35`
- **Description**: Points awarded for being a system contact (in device address book)
- **Impact**: How much we trust system contacts
- **Recommendation**:
  - `30+`: System contacts are highly trusted
  - `25`: Balanced (default)
  - `20`: System contact status is less important

---

### T-Z

#### `TRUSTED_RECIPIENT_MIN_SUCCESS_COUNT`
- **Type**: `int`
- **Default**: `3`
- **Range**: `2-10`
- **Description**: Minimum successful sends to maintain trusted status
- **Impact**: How many successes build trust
- **Note**: Currently defined but not yet implemented in the logic (future enhancement)

---

#### `TRUSTED_THRESHOLD`
- **Type**: `int`
- **Default**: `80`
- **Range**: `60-100`
- **Description**: Minimum reputation score to be considered a TRUSTED contact
- **Impact**: Higher = fewer trusted contacts, stricter false positive detection
- **Recommendation**:
  - `90+`: Very strict, only highest confidence contacts
  - `80`: Balanced (default)
  - `70`: More lenient, catches more potential false positives

---

## 🎯 Configuration Decision Tree

```
START: What do you want to optimize for?

├─ SECURITY & SAFETY
│  └─ Use: STRICT MODE
│     - Fewer false positives, more rigorous filtering
│     - Higher thresholds, disabled FP detection
│
├─ DELIVERY & AVAILABILITY
│  └─ Use: LENIENT MODE
│     - Aggressive false positive detection
│     - Lower thresholds, more retry attempts
│
├─ BALANCED APPROACH
│  └─ Use: PRODUCTION (BALANCED)
│     - Default recommended settings
│     - Good mix of safety and availability
│
├─ DEBUGGING & TESTING
│  └─ Use: DEBUG MODE
│     - Maximum logging visibility
│     - All analysis features enabled
│
└─ LEGACY COMPATIBILITY
   └─ Use: DISABLED MODE
      - Turn off all enhancements
      - Behave like original code
```

---

## 🔥 Hot Knobs (Most Commonly Adjusted)

These are the knobs you'll most likely want to tune based on your needs:

### 1. **TRUSTED_THRESHOLD** (Default: 80)
- **Increase** if you're getting too many false positive alerts
- **Decrease** if legitimate requests are being wrongfully rejected

### 2. **ENABLE_AGGRESSIVE_RETRY** (Default: false)
- **Enable** to maximize delivery for trusted contacts
- **Disable** for more conservative retry behavior

### 3. **FLAG_TRUSTED_CONTACT_FAILURES** (Default: true)
- **Disable** if trusted contacts failing is normal in your environment
- **Enable** to catch potential false positives early

### 4. **ENABLE_DETAILED_LOGGING** (Default: true)
- **Disable** in production if logs are too verbose
- **Enable** for full visibility during troubleshooting

### 5. **SYSTEM_CONTACT_POINTS** (Default: 25)
- **Increase** if system contacts are highly trustworthy
- **Decrease** if system contacts aren't reliable indicators

---

## 📈 Monitoring Recommendations

After changing configuration, monitor these metrics:

1. **False Positive Rate**: `stats.getFalsePositiveRate()`
   - Target: < 10% for production
   - Alert: >= 30% (HIGH_FALSE_POSITIVE_RATE_THRESHOLD)

2. **Trusted Contact Failures**: `stats.trustedContactFailureCount`
   - Target: 0
   - Alert: Any non-zero value

3. **Success Rate**: `stats.getSuccessPercentage()`
   - Target: >= 90%
   - Alert: < 70%

4. **Legitimate Rejection Count**: `stats.legitimateRejectionCount`
   - Trend: Should be stable or decreasing

---

## ⚠️ Security Warnings

**NEVER ENABLE THESE IN PRODUCTION:**

❌ `FLAG_IDENTITY_FAILURES_AS_FALSE_POSITIVE = true`
- Identity failures are serious security issues
- Never treat as false positives

**USE WITH CAUTION:**

⚠️ `FLAG_PROOF_REQUIRED_AS_FALSE_POSITIVE = true`
- Only if proof challenges are genuinely problematic
- May bypass legitimate security measures

⚠️ `ENABLE_LEGITIMACY_SCORING = false`
- Disables entire system
- Only for testing/comparison

---

## 📝 Configuration File Location

Edit these values in:
```
app/src/main/java/org/thoughtcrime/securesms/jobs/RejectionReducerConfig.java
```

After editing, rebuild the app for changes to take effect.

---

## 🚀 Quick Start

**For most users, start with PRODUCTION (BALANCED) mode.**

1. Copy the "Production (Balanced)" configuration above
2. Paste into `RejectionReducerConfig.java`
3. Rebuild app
4. Monitor false positive rate
5. Adjust if needed

**If false positive rate > 30%**: Switch to LENIENT mode
**If too many false alerts**: Switch to STRICT mode
**If debugging issues**: Switch to DEBUG mode

---

## 📞 Need Help?

Refer to `CLAUDE_REJECTION_REDUCER_README.md` for complete documentation.
