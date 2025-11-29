package org.thoughtcrime.securesms.jobs;

import androidx.annotation.NonNull;

/**
 * Claude Rejection Reducer Configuration
 *
 * This class centralizes all configuration parameters for the rejection reducer,
 * making it easy to tune behavior without modifying core logic.
 *
 * ============================================================================
 * QUICK START GUIDE
 * ============================================================================
 *
 * Common Configuration Scenarios:
 *
 * 1. STRICT MODE (Fewer false positives, more rejections accepted as legitimate)
 *    - Increase TRUSTED_THRESHOLD to 90
 *    - Increase HIGH_REPUTATION_THRESHOLD to 70
 *    - Set ENABLE_FALSE_POSITIVE_DETECTION to false
 *
 * 2. LENIENT MODE (More false positive detection, aggressive retry)
 *    - Decrease TRUSTED_THRESHOLD to 70
 *    - Decrease HIGH_REPUTATION_THRESHOLD to 55
 *    - Set ENABLE_AGGRESSIVE_RETRY to true
 *
 * 3. BALANCED MODE (Default - recommended for most users)
 *    - Use default values as configured below
 *
 * 4. TESTING/DEBUG MODE
 *    - Set ENABLE_DETAILED_LOGGING to true
 *    - Set LOG_ALL_LEGITIMACY_SCORES to true
 *    - Set ALERT_ON_ALL_FALSE_POSITIVES to true
 *
 * ============================================================================
 */
public final class RejectionReducerConfig {

  // ========== CORE LEGITIMACY SCORING ==========

  /**
   * Minimum reputation score to be considered a TRUSTED contact (0-100)
   *
   * Default: 80
   * Range: 60-100
   * Impact: Higher = fewer trusted contacts, stricter false positive detection
   *
   * Recommendation:
   * - 90+ : Very strict, only highest confidence contacts
   * - 80  : Balanced (default)
   * - 70  : More lenient, catches more potential false positives
   */
  public static final int TRUSTED_THRESHOLD = 80;

  /**
   * Reputation score threshold for high-reputation recipients (0-100)
   *
   * Default: 60
   * Range: 50-80
   * Impact: Determines which recipients get benefit of doubt on transient failures
   *
   * Recommendation:
   * - 70+ : Conservative, only very reliable contacts
   * - 60  : Balanced (default)
   * - 50  : Liberal, give most contacts benefit of doubt
   */
  public static final int HIGH_REPUTATION_THRESHOLD = 60;

  /**
   * Baseline neutral reputation score for unknown recipients
   *
   * Default: 50
   * Range: 30-70
   * Impact: Starting point for legitimacy calculations
   *
   * Recommendation: Keep at 50 unless you have specific needs
   */
  public static final int NEUTRAL_BASELINE_SCORE = 50;

  // ========== SCORING WEIGHTS ==========

  /**
   * Points awarded for being a system contact (in device address book)
   *
   * Default: 25
   * Range: 15-35
   * Impact: How much we trust system contacts
   *
   * Recommendation:
   * - 30+ : System contacts are highly trusted
   * - 25  : Balanced (default)
   * - 20  : System contact status is less important
   */
  public static final int SYSTEM_CONTACT_POINTS = 25;

  /**
   * Points awarded for profile sharing or user-set display name
   *
   * Default: 15
   * Range: 10-25
   * Impact: Value of established relationship indicators
   *
   * Recommendation:
   * - 20+ : Profile sharing is very important
   * - 15  : Balanced (default)
   * - 10  : Profile sharing is nice but not critical
   */
  public static final int PROFILE_SHARING_POINTS = 15;

  /**
   * Points awarded for group membership
   *
   * Default: 10
   * Range: 5-20
   * Impact: Trust based on shared group context
   *
   * Recommendation:
   * - 15+ : Group context is very important
   * - 10  : Balanced (default)
   * - 5   : Group membership is minor factor
   */
  public static final int GROUP_MEMBERSHIP_POINTS = 10;

  // ========== FALSE POSITIVE DETECTION ==========

  /**
   * Enable false positive detection system
   *
   * Default: true
   * Impact: When disabled, no false positive analysis is performed
   *
   * Recommendation: Keep enabled unless you want to disable all
   * wrongful rejection prevention features
   */
  public static final boolean ENABLE_FALSE_POSITIVE_DETECTION = true;

  /**
   * Detect false positives for trusted contacts (>= TRUSTED_THRESHOLD)
   *
   * Default: true
   * Impact: Any failure for trusted contacts flagged as suspicious
   *
   * Recommendation:
   * - true  : Trusted contacts should rarely fail (recommended)
   * - false : Even trusted contacts can have legitimate failures
   */
  public static final boolean FLAG_TRUSTED_CONTACT_FAILURES = true;

  /**
   * Detect false positives for high-reputation recipients with transient failures
   *
   * Default: true
   * Impact: Network/rate-limit failures on good recipients are suspicious
   *
   * Recommendation: Keep enabled for best false positive detection
   */
  public static final boolean FLAG_HIGH_REP_TRANSIENT_FAILURES = true;

  /**
   * Detect false positives for system contacts with network failures
   *
   * Default: true
   * Impact: System contacts with network issues get benefit of doubt
   *
   * Recommendation:
   * - true  : System contacts are trusted (recommended)
   * - false : System contacts treated same as others
   */
  public static final boolean FLAG_SYSTEM_CONTACT_NETWORK_FAILURES = true;

  /**
   * Percentage threshold for high false positive rate warning (0-100)
   *
   * Default: 30
   * Range: 20-50
   * Impact: When to warn about concerning false positive rates
   *
   * Recommendation:
   * - 40+ : Only warn on very high rates
   * - 30  : Balanced warning threshold (default)
   * - 20  : Warn early on elevated rates
   */
  public static final int HIGH_FALSE_POSITIVE_RATE_THRESHOLD = 30;

  // ========== RETRY BEHAVIOR ==========

  /**
   * Enable aggressive retry for suspected false positives
   *
   * Default: false
   * Impact: Suspected false positives get immediate retry recommendations
   *
   * Recommendation:
   * - true  : Maximize delivery for trusted contacts
   * - false : Use standard retry logic (default)
   */
  public static final boolean ENABLE_AGGRESSIVE_RETRY = false;

  /**
   * Prioritize trusted contact retries over other failures
   *
   * Default: true
   * Impact: Trusted contacts marked as HIGH_PRIORITY_RETRY
   *
   * Recommendation: Keep enabled to prioritize important contacts
   */
  public static final boolean PRIORITIZE_TRUSTED_RETRIES = true;

  /**
   * Minimum consecutive failures before marking recipient as suspicious
   *
   * Default: 3
   * Range: 2-5
   * Impact: How many failures before losing trust
   *
   * Note: This is currently defined but not yet implemented in the logic.
   * Future enhancement will track failure history.
   */
  public static final int SUSPICIOUS_FAILURE_THRESHOLD = 3;

  /**
   * Minimum successful sends to maintain trusted status
   *
   * Default: 3
   * Range: 2-10
   * Impact: How many successes build trust
   *
   * Note: This is currently defined but not yet implemented in the logic.
   * Future enhancement will track success history.
   */
  public static final int TRUSTED_RECIPIENT_MIN_SUCCESS_COUNT = 3;

  // ========== LOGGING & MONITORING ==========

  /**
   * Enable detailed legitimacy analysis logging
   *
   * Default: true
   * Impact: Show full legitimacy analysis section in logs
   *
   * Recommendation:
   * - true  : Full visibility into false positive detection (default)
   * - false : Minimal logging, only critical alerts
   */
  public static final boolean ENABLE_DETAILED_LOGGING = true;

  /**
   * Log legitimacy scores for all recipients (including successful sends)
   *
   * Default: false
   * Impact: Verbose logging of every legitimacy assessment
   *
   * Recommendation:
   * - true  : Debug/testing only - very verbose
   * - false : Only log failures and notable events (default)
   */
  public static final boolean LOG_ALL_LEGITIMACY_SCORES = false;

  /**
   * Alert (WARN level) on every suspected false positive
   *
   * Default: true
   * Impact: Individual alert for each false positive detection
   *
   * Recommendation:
   * - true  : Maximum visibility (default)
   * - false : Only summary alerts
   */
  public static final boolean ALERT_ON_ALL_FALSE_POSITIVES = true;

  /**
   * Log override recommendations even at INFO level
   *
   * Default: true
   * Impact: Show retry recommendations without DEBUG logging
   *
   * Recommendation: Keep enabled for actionable insights
   */
  public static final boolean LOG_OVERRIDE_RECOMMENDATIONS = true;

  /**
   * Show visual summary box in logs
   *
   * Default: true
   * Impact: Display formatted box-drawing summary table
   *
   * Recommendation:
   * - true  : Better readability (default)
   * - false : Plain text logging
   */
  public static final boolean ENABLE_VISUAL_SUMMARY = true;

  // ========== FEATURE FLAGS ==========

  /**
   * Enable legitimacy scoring system
   *
   * Default: true
   * Impact: Master switch for entire legitimacy analysis
   *
   * Recommendation: Only disable for testing/comparison purposes
   */
  public static final boolean ENABLE_LEGITIMACY_SCORING = true;

  /**
   * Enable reputation-based override recommendations
   *
   * Default: true
   * Impact: Generate specific retry guidance for failures
   *
   * Recommendation: Keep enabled for actionable insights
   */
  public static final boolean ENABLE_OVERRIDE_RECOMMENDATIONS = true;

  /**
   * Enable trusted contact identification and tracking
   *
   * Default: true
   * Impact: Track and prioritize trusted contacts
   *
   * Recommendation: Keep enabled for optimal delivery
   */
  public static final boolean ENABLE_TRUSTED_CONTACT_TRACKING = true;

  // ========== ADVANCED TUNING ==========

  /**
   * Consider proof-required failures as potential false positives
   *
   * Default: false
   * Impact: Proof/captcha requirements might be overly aggressive
   *
   * Recommendation:
   * - true  : If you think proof challenges are too aggressive
   * - false : Proof challenges are legitimate security measures (default)
   */
  public static final boolean FLAG_PROOF_REQUIRED_AS_FALSE_POSITIVE = false;

  /**
   * Consider identity failures as potential false positives for trusted contacts
   *
   * Default: false
   * Impact: Even trusted contacts can have identity key changes
   *
   * WARNING: Identity failures are security-sensitive. Only enable if you
   * understand the implications.
   *
   * Recommendation: Keep disabled (false) for security
   */
  public static final boolean FLAG_IDENTITY_FAILURES_AS_FALSE_POSITIVE = false;

  /**
   * Maximum legitimacy score possible (ceiling)
   *
   * Default: 100
   * Range: 100-100 (fixed)
   * Impact: Maximum reputation score
   *
   * Recommendation: Do not change unless you know what you're doing
   */
  public static final int MAX_LEGITIMACY_SCORE = 100;

  /**
   * Minimum legitimacy score possible (floor)
   *
   * Default: 0
   * Range: 0-0 (fixed)
   * Impact: Minimum reputation score
   *
   * Recommendation: Do not change unless you know what you're doing
   */
  public static final int MIN_LEGITIMACY_SCORE = 0;

  // ========== UTILITY METHODS ==========

  /**
   * Get configuration summary for logging
   */
  public static @NonNull String getConfigSummary() {
    return String.format(
        "RejectionReducerConfig{trusted=%d, highRep=%d, sysContact=%d, profile=%d, group=%d, " +
        "fpDetection=%b, aggressiveRetry=%b, detailedLog=%b}",
        TRUSTED_THRESHOLD,
        HIGH_REPUTATION_THRESHOLD,
        SYSTEM_CONTACT_POINTS,
        PROFILE_SHARING_POINTS,
        GROUP_MEMBERSHIP_POINTS,
        ENABLE_FALSE_POSITIVE_DETECTION,
        ENABLE_AGGRESSIVE_RETRY,
        ENABLE_DETAILED_LOGGING
    );
  }

  /**
   * Validate configuration values
   */
  public static boolean isConfigValid() {
    if (TRUSTED_THRESHOLD < 60 || TRUSTED_THRESHOLD > 100) return false;
    if (HIGH_REPUTATION_THRESHOLD < 50 || HIGH_REPUTATION_THRESHOLD > 80) return false;
    if (NEUTRAL_BASELINE_SCORE < 30 || NEUTRAL_BASELINE_SCORE > 70) return false;
    if (SYSTEM_CONTACT_POINTS < 0 || SYSTEM_CONTACT_POINTS > 50) return false;
    if (PROFILE_SHARING_POINTS < 0 || PROFILE_SHARING_POINTS > 50) return false;
    if (GROUP_MEMBERSHIP_POINTS < 0 || GROUP_MEMBERSHIP_POINTS > 50) return false;
    if (HIGH_FALSE_POSITIVE_RATE_THRESHOLD < 0 || HIGH_FALSE_POSITIVE_RATE_THRESHOLD > 100) return false;
    return true;
  }

  /**
   * Get preset configuration name
   */
  public static @NonNull String getPresetName() {
    if (TRUSTED_THRESHOLD >= 90 && !ENABLE_FALSE_POSITIVE_DETECTION) {
      return "STRICT";
    } else if (TRUSTED_THRESHOLD <= 70 && ENABLE_AGGRESSIVE_RETRY) {
      return "LENIENT";
    } else if (ENABLE_DETAILED_LOGGING && LOG_ALL_LEGITIMACY_SCORES) {
      return "DEBUG";
    } else {
      return "BALANCED";
    }
  }

  private RejectionReducerConfig() {
    // Static configuration class, no instantiation
  }
}
