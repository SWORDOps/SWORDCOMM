package org.thoughtcrime.securesms.jobs;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.signal.core.util.logging.Log;
import org.thoughtcrime.securesms.recipients.Recipient;
import org.thoughtcrime.securesms.recipients.RecipientId;
import org.thoughtcrime.securesms.util.RecipientAccessList;
import org.whispersystems.signalservice.api.messages.SendMessageResult;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Claude Rejection Reducer - Enhanced message send result aggregation and analysis
 *
 * This helper provides sophisticated rejection handling for group message sending operations.
 * It categorizes failures, tracks statistics, and provides actionable insights for retry logic.
 *
 * Key features:
 * - Comprehensive failure categorization and tracking
 * - Statistical analysis of send operations
 * - Retry recommendation logic with legitimacy verification
 * - Rate limit and network failure detection
 * - False positive detection and mitigation
 * - Recipient legitimacy scoring and trusted contact recognition
 * - Adaptive retry strategies based on recipient reputation
 * - Detailed logging with contextual information
 */
final class GroupSendJobHelper {

  private static final String TAG = Log.tag(GroupSendJobHelper.class);

  private GroupSendJobHelper() {
  }

  static {
    // Log configuration on first use
    if (RejectionReducerConfig.ENABLE_DETAILED_LOGGING) {
      Log.i(TAG, "[Claude Rejection Reducer] Configuration: " + RejectionReducerConfig.getConfigSummary());
      Log.i(TAG, "[Claude Rejection Reducer] Preset: " + RejectionReducerConfig.getPresetName());
      if (!RejectionReducerConfig.isConfigValid()) {
        Log.e(TAG, "[Claude Rejection Reducer] WARNING: Configuration validation failed! Using possibly invalid settings.");
      }
    }
  }

  /**
   * Enhanced Claude Rejection Reducer - Aggregates and analyzes message send results
   *
   * This method processes a collection of SendMessageResult objects and categorizes them
   * into actionable groups with comprehensive statistics and failure analysis.
   *
   * @param possibleRecipients List of all recipients that could have been sent to
   * @param results Collection of send results to analyze
   * @return SendResult containing categorized recipients, statistics, and failure analysis
   */
  static @NonNull SendResult getCompletedSends(@NonNull List<Recipient> possibleRecipients, @NonNull Collection<SendMessageResult> results) {
    RecipientAccessList accessList   = new RecipientAccessList(possibleRecipients);
    List<Recipient>     completions  = new ArrayList<>(results.size());
    List<RecipientId>   skipped      = new ArrayList<>();
    List<RecipientId>   unregistered = new ArrayList<>();

    // Enhanced tracking for Claude Rejection Reducer
    List<RecipientId>          networkFailures     = new ArrayList<>();
    List<RecipientId>          identityFailures    = new ArrayList<>();
    List<RecipientId>          rateLimitFailures   = new ArrayList<>();
    List<RecipientId>          proofRequiredList   = new ArrayList<>();
    List<RecipientId>          invalidPreKeyList   = new ArrayList<>();
    List<RecipientId>          retryableFailures   = new ArrayList<>();
    Map<RecipientId, String>   failureDetails      = new LinkedHashMap<>();
    Map<String, Integer>       failureTypeCounts   = new HashMap<>();

    // Legitimacy verification tracking - prevents wrongful rejections of legitimate requests
    List<RecipientId>                    legitimateRejections      = new ArrayList<>();
    List<RecipientId>                    suspectedFalsePositives   = new ArrayList<>();
    List<RecipientId>                    trustedContacts           = new ArrayList<>();
    Map<RecipientId, LegitimacyScore>    legitimacyScores          = new LinkedHashMap<>();
    Map<RecipientId, String>             overrideRecommendations   = new LinkedHashMap<>();

    int successCount = 0;
    int totalFailures = 0;
    int falsePositiveCount = 0;
    int trustedContactFailures = 0;
    long processingStartTime = System.currentTimeMillis();

    Log.i(TAG, "[Claude Rejection Reducer] Processing " + results.size() + " send results for " + possibleRecipients.size() + " possible recipients");

    for (SendMessageResult sendMessageResult : results) {
      Recipient recipient = accessList.requireByAddress(sendMessageResult.getAddress());
      RecipientId recipientId = recipient.getId();
      boolean hasFailure = false;
      StringBuilder failureContext = new StringBuilder();

      // Track successful sends
      if (sendMessageResult.getSuccess() != null) {
        successCount++;
        Log.d(TAG, "[Claude Rejection Reducer] ✓ Success for " + recipientId);
      }

      // Identity failure handling - non-retryable, security issue
      if (sendMessageResult.getIdentityFailure() != null) {
        hasFailure = true;
        totalFailures++;
        identityFailures.add(recipientId);
        failureContext.append("IDENTITY_FAILURE(key=").append(sendMessageResult.getIdentityFailure().getIdentityKey()).append(") ");
        incrementFailureCount(failureTypeCounts, "identity");
        Log.w(TAG, "[Claude Rejection Reducer] ✗ Identity failure for " + recipientId + " - Security key mismatch detected");
      }

      // Unregistered failure - permanent, non-retryable
      if (sendMessageResult.isUnregisteredFailure()) {
        hasFailure = true;
        totalFailures++;
        skipped.add(recipientId);
        unregistered.add(recipientId);
        failureContext.append("UNREGISTERED ");
        incrementFailureCount(failureTypeCounts, "unregistered");
        Log.w(TAG, "[Claude Rejection Reducer] ✗ Unregistered failure for " + recipientId + " - Recipient not on Signal network");
      }

      // Network failure - retryable
      if (sendMessageResult.isNetworkFailure() && sendMessageResult.getProofRequiredFailure() == null && sendMessageResult.getRateLimitFailure() == null) {
        hasFailure = true;
        totalFailures++;
        networkFailures.add(recipientId);
        retryableFailures.add(recipientId);
        failureContext.append("NETWORK_FAILURE ");
        incrementFailureCount(failureTypeCounts, "network");
        Log.w(TAG, "[Claude Rejection Reducer] ✗ Network failure for " + recipientId + " - RETRYABLE with backoff");
      }

      // Proof required failure - requires user intervention
      if (sendMessageResult.getProofRequiredFailure() != null) {
        hasFailure = true;
        totalFailures++;
        skipped.add(recipientId);
        proofRequiredList.add(recipientId);
        failureContext.append("PROOF_REQUIRED(token=").append(sendMessageResult.getProofRequiredFailure().getToken()).append(") ");
        incrementFailureCount(failureTypeCounts, "proof_required");
        Log.w(TAG, "[Claude Rejection Reducer] ✗ Proof required for " + recipientId + " - User verification needed");
      }

      // Rate limit failure - retryable with exponential backoff
      if (sendMessageResult.getRateLimitFailure() != null) {
        hasFailure = true;
        totalFailures++;
        rateLimitFailures.add(recipientId);
        retryableFailures.add(recipientId);
        int retryAfter = sendMessageResult.getRateLimitFailure().getRetryAfter().orElse(60);
        failureContext.append("RATE_LIMITED(retry_after=").append(retryAfter).append("s) ");
        incrementFailureCount(failureTypeCounts, "rate_limit");
        Log.w(TAG, "[Claude Rejection Reducer] ✗ Rate limit for " + recipientId + " - RETRYABLE after " + retryAfter + " seconds");
      }

      // Invalid pre-key failure - cryptographic issue, may be retryable
      if (sendMessageResult.isInvalidPreKeyFailure()) {
        hasFailure = true;
        totalFailures++;
        skipped.add(recipientId);
        invalidPreKeyList.add(recipientId);
        retryableFailures.add(recipientId);
        failureContext.append("INVALID_PREKEY ");
        incrementFailureCount(failureTypeCounts, "invalid_prekey");
        Log.w(TAG, "[Claude Rejection Reducer] ✗ Invalid pre-key for " + recipientId + " - RETRYABLE after key refresh");
      }

      // ===== LEGITIMACY ANALYSIS - Prevent wrongful rejections of legitimate requests =====

      // Assess recipient legitimacy to detect potential false positives
      LegitimacyScore legitimacyScore = assessRecipientLegitimacy(recipient, sendMessageResult, hasFailure);
      legitimacyScores.put(recipientId, legitimacyScore);

      // Check if this is a trusted contact
      if (legitimacyScore.isTrustedContact) {
        trustedContacts.add(recipientId);
        Log.d(TAG, "[Claude Rejection Reducer] ⭐ Identified trusted contact: " + recipientId + " (reputation: " + legitimacyScore.reputationScore + "%)");
      }

      // Analyze if this rejection appears to be a false positive
      if (hasFailure && legitimacyScore.isSuspectedFalsePositive) {
        suspectedFalsePositives.add(recipientId);
        falsePositiveCount++;

        String recommendation = generateOverrideRecommendation(recipientId, sendMessageResult, legitimacyScore);
        overrideRecommendations.put(recipientId, recommendation);

        Log.w(TAG, "[Claude Rejection Reducer] ⚠️  SUSPECTED FALSE POSITIVE for " + recipientId +
                   " - Legitimacy: " + legitimacyScore.legitimacyLevel +
                   " (Score: " + legitimacyScore.reputationScore + "%) - " + recommendation);

        if (legitimacyScore.isTrustedContact) {
          trustedContactFailures++;
          Log.e(TAG, "[Claude Rejection Reducer] 🚨 TRUSTED CONTACT FAILURE for " + recipientId +
                     " - This should be prioritized for retry!");
        }
      }

      // Classify rejection as legitimate or potentially wrongful
      if (hasFailure) {
        if (legitimacyScore.isSuspectedFalsePositive) {
          // Potentially wrongful rejection - needs review
          Log.i(TAG, "[Claude Rejection Reducer] 📋 Flagged for review: " + recipientId + " - " + failureContext.toString().trim());
        } else {
          // Appears to be a legitimate rejection
          legitimateRejections.add(recipientId);
          Log.d(TAG, "[Claude Rejection Reducer] ✓ Legitimate rejection: " + recipientId);
        }
      }

      // Store detailed failure context
      if (hasFailure && failureContext.length() > 0) {
        failureDetails.put(recipientId, failureContext.toString().trim());
      }

      // Mark as completed if successful or certain types of non-retryable failures
      if (sendMessageResult.getSuccess() != null ||
          sendMessageResult.getIdentityFailure() != null ||
          sendMessageResult.getProofRequiredFailure() != null ||
          sendMessageResult.isUnregisteredFailure() ||
          sendMessageResult.isInvalidPreKeyFailure())
      {
        completions.add(recipient);
      }
    }

    long processingDuration = System.currentTimeMillis() - processingStartTime;

    // Create comprehensive statistics with legitimacy metrics
    SendResultStatistics statistics = new SendResultStatistics(
        results.size(),
        successCount,
        totalFailures,
        networkFailures.size(),
        identityFailures.size(),
        unregistered.size(),
        rateLimitFailures.size(),
        proofRequiredList.size(),
        invalidPreKeyList.size(),
        retryableFailures.size(),
        processingDuration,
        failureTypeCounts,
        falsePositiveCount,
        trustedContactFailures,
        legitimateRejections.size(),
        suspectedFalsePositives.size(),
        trustedContacts.size()
    );

    // Log comprehensive summary with legitimacy analysis
    logSummary(statistics, failureDetails, overrideRecommendations);

    return new SendResult(
        completions,
        skipped,
        unregistered,
        networkFailures,
        identityFailures,
        rateLimitFailures,
        proofRequiredList,
        invalidPreKeyList,
        retryableFailures,
        failureDetails,
        statistics,
        legitimateRejections,
        suspectedFalsePositives,
        trustedContacts,
        legitimacyScores,
        overrideRecommendations
    );
  }

  /**
   * Assess recipient legitimacy to detect potential false positives
   *
   * This method evaluates whether a rejection might be wrongful by analyzing:
   * - Recipient's contact status and relationship
   * - Historical success rate and reliability
   * - Nature of the current failure
   * - System/profile indicators of legitimacy
   */
  private static @NonNull LegitimacyScore assessRecipientLegitimacy(@NonNull Recipient recipient,
                                                                     @NonNull SendMessageResult result,
                                                                     boolean hasFailure) {
    // Return neutral score if legitimacy scoring is disabled
    if (!RejectionReducerConfig.ENABLE_LEGITIMACY_SCORING) {
      return new LegitimacyScore(RejectionReducerConfig.NEUTRAL_BASELINE_SCORE, false, false, "DISABLED");
    }

    int reputationScore = RejectionReducerConfig.NEUTRAL_BASELINE_SCORE;
    boolean isTrusted = false;
    boolean isSuspectedFalsePositive = false;
    String legitimacyLevel = "UNKNOWN";

    // Factor 1: Contact relationship indicators
    if (recipient.isSystemContact()) {
      reputationScore += RejectionReducerConfig.SYSTEM_CONTACT_POINTS;
      legitimacyLevel = "SYSTEM_CONTACT";
    }

    if (recipient.isProfileSharing() || recipient.hasAUserSetDisplayName(recipient.getContext())) {
      reputationScore += RejectionReducerConfig.PROFILE_SHARING_POINTS;
      if (legitimacyLevel.equals("SYSTEM_CONTACT")) {
        legitimacyLevel = "TRUSTED_SYSTEM_CONTACT";
      } else {
        legitimacyLevel = "PROFILE_SHARED";
      }
    }

    // Factor 2: Group membership (shared context)
    if (recipient.isGroup() || recipient.getGroupId().isPresent()) {
      reputationScore += RejectionReducerConfig.GROUP_MEMBERSHIP_POINTS;
    }

    // Cap score at maximum
    if (reputationScore > RejectionReducerConfig.MAX_LEGITIMACY_SCORE) {
      reputationScore = RejectionReducerConfig.MAX_LEGITIMACY_SCORE;
    }

    // Factor 3: Determine if this is a trusted contact (high reputation)
    if (reputationScore >= RejectionReducerConfig.TRUSTED_THRESHOLD) {
      isTrusted = true;
      legitimacyLevel = "TRUSTED";
    }

    // Factor 4: Analyze if failure appears to be a false positive
    if (!RejectionReducerConfig.ENABLE_FALSE_POSITIVE_DETECTION || !hasFailure) {
      return new LegitimacyScore(reputationScore, isTrusted, false, legitimacyLevel);
    }

    // Check for false positive indicators based on config
    if (isTrusted && RejectionReducerConfig.FLAG_TRUSTED_CONTACT_FAILURES) {
      // Trusted contacts failing are likely false positives
      isSuspectedFalsePositive = true;
    } else if (reputationScore >= RejectionReducerConfig.HIGH_REPUTATION_THRESHOLD &&
               RejectionReducerConfig.FLAG_HIGH_REP_TRANSIENT_FAILURES) {
      // High-reputation recipients with transient failures
      if (result.isNetworkFailure() || result.getRateLimitFailure() != null) {
        // Network/rate limit failures for good recipients are suspicious
        isSuspectedFalsePositive = true;
      }
    } else if (result.isNetworkFailure() && recipient.isSystemContact() &&
               RejectionReducerConfig.FLAG_SYSTEM_CONTACT_NETWORK_FAILURES) {
      // System contacts with network failures deserve benefit of doubt
      isSuspectedFalsePositive = true;
    }

    // Advanced false positive checks
    if (result.getProofRequiredFailure() != null &&
        RejectionReducerConfig.FLAG_PROOF_REQUIRED_AS_FALSE_POSITIVE &&
        reputationScore >= RejectionReducerConfig.HIGH_REPUTATION_THRESHOLD) {
      isSuspectedFalsePositive = true;
    }

    if (result.getIdentityFailure() != null &&
        RejectionReducerConfig.FLAG_IDENTITY_FAILURES_AS_FALSE_POSITIVE &&
        isTrusted) {
      Log.w(TAG, "[Claude Rejection Reducer] ⚠️  WARNING: Identity failure flagged as false positive for trusted contact - review security settings!");
      isSuspectedFalsePositive = true;
    }

    // Log all legitimacy scores if configured
    if (RejectionReducerConfig.LOG_ALL_LEGITIMACY_SCORES) {
      Log.d(TAG, String.format("[Claude Rejection Reducer] Legitimacy: %s (score=%d, trusted=%b, fp=%b)",
                               legitimacyLevel, reputationScore, isTrusted, isSuspectedFalsePositive));
    }

    return new LegitimacyScore(reputationScore, isTrusted, isSuspectedFalsePositive, legitimacyLevel);
  }

  /**
   * Generate override recommendation for potentially wrongful rejections
   */
  private static @NonNull String generateOverrideRecommendation(@NonNull RecipientId recipientId,
                                                                 @NonNull SendMessageResult result,
                                                                 @NonNull LegitimacyScore legitimacy) {
    if (!RejectionReducerConfig.ENABLE_OVERRIDE_RECOMMENDATIONS) {
      return "RETRY [Recommendations disabled]";
    }

    StringBuilder recommendation = new StringBuilder();

    // Determine priority based on config
    if (legitimacy.isTrustedContact && RejectionReducerConfig.PRIORITIZE_TRUSTED_RETRIES) {
      recommendation.append("HIGH_PRIORITY_RETRY");
    } else if (RejectionReducerConfig.ENABLE_AGGRESSIVE_RETRY && legitimacy.isSuspectedFalsePositive) {
      recommendation.append("IMMEDIATE_RETRY");
    } else {
      recommendation.append("STANDARD_RETRY");
    }

    // Add context-specific guidance
    if (result.isNetworkFailure()) {
      recommendation.append(" with network backoff");
    } else if (result.getRateLimitFailure() != null) {
      int retryAfter = result.getRateLimitFailure().getRetryAfter().orElse(60);
      recommendation.append(" after ").append(retryAfter).append("s rate limit");
    } else if (result.isInvalidPreKeyFailure()) {
      recommendation.append(" after key refresh");
    } else if (result.getProofRequiredFailure() != null) {
      recommendation.append(" after user completes proof");
    }

    recommendation.append(" [Legitimacy: ").append(legitimacy.reputationScore).append("%]");

    return recommendation.toString();
  }

  /**
   * Increment failure type counter
   */
  private static void incrementFailureCount(@NonNull Map<String, Integer> counts, @NonNull String failureType) {
    counts.put(failureType, counts.getOrDefault(failureType, 0) + 1);
  }

  /**
   * Log comprehensive summary of send results with legitimacy analysis
   */
  private static void logSummary(@NonNull SendResultStatistics stats,
                                  @NonNull Map<RecipientId, String> failureDetails,
                                  @NonNull Map<RecipientId, String> overrideRecommendations) {
    // Skip detailed logging if disabled
    if (!RejectionReducerConfig.ENABLE_DETAILED_LOGGING) {
      Log.i(TAG, "[Claude Rejection Reducer] Processed " + stats.totalResults + " results: " +
                 stats.successCount + " success, " + stats.totalFailures + " failed, " +
                 stats.suspectedFalsePositiveCount + " false positives");
      return;
    }

    // Visual summary box (if enabled)
    if (RejectionReducerConfig.ENABLE_VISUAL_SUMMARY) {
      Log.i(TAG, "┌─────────────────────────────────────────────────────────");
      Log.i(TAG, "│ [Claude Rejection Reducer] Send Results Summary");
      Log.i(TAG, "├─────────────────────────────────────────────────────────");
      Log.i(TAG, "│ Total Results:      " + stats.totalResults);
      Log.i(TAG, "│ ✓ Successful:       " + stats.successCount + " (" + stats.getSuccessPercentage() + "%)");
      Log.i(TAG, "│ ✗ Failed:           " + stats.totalFailures + " (" + stats.getFailurePercentage() + "%)");
      Log.i(TAG, "├─────────────────────────────────────────────────────────");
      Log.i(TAG, "│ Failure Breakdown:");
      Log.i(TAG, "│   • Network:        " + stats.networkFailureCount + (stats.networkFailureCount > 0 ? " [RETRYABLE]" : ""));
      Log.i(TAG, "│   • Identity:       " + stats.identityFailureCount + (stats.identityFailureCount > 0 ? " [SECURITY]" : ""));
      Log.i(TAG, "│   • Unregistered:   " + stats.unregisteredCount + (stats.unregisteredCount > 0 ? " [PERMANENT]" : ""));
      Log.i(TAG, "│   • Rate Limited:   " + stats.rateLimitFailureCount + (stats.rateLimitFailureCount > 0 ? " [RETRYABLE]" : ""));
      Log.i(TAG, "│   • Proof Required: " + stats.proofRequiredCount + (stats.proofRequiredCount > 0 ? " [USER_ACTION]" : ""));
      Log.i(TAG, "│   • Invalid PreKey: " + stats.invalidPreKeyCount + (stats.invalidPreKeyCount > 0 ? " [RETRYABLE]" : ""));
      Log.i(TAG, "├─────────────────────────────────────────────────────────");
      Log.i(TAG, "│ Legitimacy Analysis (Wrongful Rejection Prevention):");
      Log.i(TAG, "│   ⚠️  False Positives:  " + stats.suspectedFalsePositiveCount + (stats.suspectedFalsePositiveCount > 0 ? " [NEEDS_REVIEW]" : ""));
      Log.i(TAG, "│   ⭐ Trusted Contacts: " + stats.trustedContactCount);
      Log.i(TAG, "│   🚨 Trusted Failed:   " + stats.trustedContactFailureCount + (stats.trustedContactFailureCount > 0 ? " [CRITICAL]" : ""));
      Log.i(TAG, "│   ✓ Legit Rejections: " + stats.legitimateRejectionCount);
      Log.i(TAG, "├─────────────────────────────────────────────────────────");
      Log.i(TAG, "│ Retry Analysis:");
      Log.i(TAG, "│   Retryable:        " + stats.retryableCount + " failures can be retried");
      Log.i(TAG, "│   Processing Time:  " + stats.processingDurationMs + "ms");
      Log.i(TAG, "└─────────────────────────────────────────────────────────");
    } else {
      // Plain text summary
      Log.i(TAG, "[Claude Rejection Reducer] Results: " + stats.totalResults + " total, " +
                 stats.successCount + " success (" + stats.getSuccessPercentage() + "%), " +
                 stats.totalFailures + " failed (" + stats.getFailurePercentage() + "%)");
      Log.i(TAG, "[Claude Rejection Reducer] False Positives: " + stats.suspectedFalsePositiveCount +
                 ", Trusted Contacts: " + stats.trustedContactCount +
                 ", Trusted Failed: " + stats.trustedContactFailureCount);
    }

    // Log false positive alerts (if enabled)
    if (stats.suspectedFalsePositiveCount > 0 && RejectionReducerConfig.ALERT_ON_ALL_FALSE_POSITIVES) {
      Log.w(TAG, "[Claude Rejection Reducer] ⚠️  ALERT: " + stats.suspectedFalsePositiveCount + " suspected false positive(s) detected!");
    }

    // Log override recommendations (if enabled and available)
    if (!overrideRecommendations.isEmpty() &&
        RejectionReducerConfig.LOG_OVERRIDE_RECOMMENDATIONS &&
        Log.isLoggable(TAG, Log.INFO)) {
      Log.i(TAG, "[Claude Rejection Reducer] Override recommendations:");
      for (Map.Entry<RecipientId, String> entry : overrideRecommendations.entrySet()) {
        Log.i(TAG, "  • " + entry.getKey() + ": " + entry.getValue());
      }
    }

    // Log trusted contact failures - these are high priority
    if (stats.trustedContactFailureCount > 0 && RejectionReducerConfig.ENABLE_TRUSTED_CONTACT_TRACKING) {
      Log.e(TAG, "[Claude Rejection Reducer] 🚨 CRITICAL: " + stats.trustedContactFailureCount +
                 " trusted contact(s) failed - these should be prioritized for immediate retry!");
    }

    // Check for high false positive rate
    if (stats.hasHighFalsePositiveRate()) {
      Log.w(TAG, "[Claude Rejection Reducer] ⚠️  WARNING: High false positive rate detected (" +
                 stats.getFalsePositiveRate() + "%) - review configuration or investigate system issues");
    }

    if (!failureDetails.isEmpty() && Log.isLoggable(TAG, Log.DEBUG)) {
      Log.d(TAG, "[Claude Rejection Reducer] Detailed failure context:");
      for (Map.Entry<RecipientId, String> entry : failureDetails.entrySet()) {
        Log.d(TAG, "  • " + entry.getKey() + ": " + entry.getValue());
      }
    }
  }

  /**
   * Enhanced SendResult - Comprehensive send operation results with detailed failure categorization
   *
   * This class provides a complete view of message sending outcomes, including:
   * - Success and completion tracking
   * - Categorized failure lists for different error types
   * - Detailed failure context and metadata
   * - Comprehensive statistics for analysis and monitoring
   * - Retry recommendations based on failure types
   */
  public static class SendResult {
    // ===== Legacy fields (maintained for backward compatibility) =====

    /** Recipients that do not need to be sent to again. Includes certain types of non-retryable failures. Important: items in this list can overlap with other lists in the result. */
    public final List<Recipient>   completed;

    /** Recipients that were not sent to and can be shown as "skipped" in the UI. Important: items in this list can overlap with other lists in the result. */
    public final List<RecipientId> skipped;

    /** Recipients that were discovered to be unregistered. Important: items in this list can overlap with other lists in the result. */
    public final List<RecipientId> unregistered;

    // ===== Enhanced Claude Rejection Reducer fields =====

    /** Recipients that experienced network failures - these are retryable */
    public final List<RecipientId> networkFailures;

    /** Recipients that had identity key mismatches - requires security review */
    public final List<RecipientId> identityFailures;

    /** Recipients that hit rate limits - retryable after backoff period */
    public final List<RecipientId> rateLimitFailures;

    /** Recipients that require proof/captcha - requires user action */
    public final List<RecipientId> proofRequired;

    /** Recipients with invalid pre-keys - retryable after key refresh */
    public final List<RecipientId> invalidPreKeys;

    /** All recipients that can be retried (aggregated from various retryable failure types) */
    public final List<RecipientId> retryable;

    /** Detailed failure context for each failed recipient, keyed by RecipientId */
    public final Map<RecipientId, String> failureDetails;

    /** Comprehensive statistics about the send operation */
    public final SendResultStatistics statistics;

    // ===== Legitimacy Analysis Fields (Wrongful Rejection Prevention) =====

    /** Recipients whose rejections appear legitimate (not false positives) */
    public final List<RecipientId> legitimateRejections;

    /** Recipients suspected to be wrongfully rejected (false positives) */
    public final List<RecipientId> suspectedFalsePositives;

    /** Recipients identified as trusted contacts based on legitimacy scoring */
    public final List<RecipientId> trustedContacts;

    /** Legitimacy scores for all recipients, keyed by RecipientId */
    public final Map<RecipientId, LegitimacyScore> legitimacyScores;

    /** Override recommendations for suspected false positives, keyed by RecipientId */
    public final Map<RecipientId, String> overrideRecommendations;

    /**
     * Legacy constructor - maintained for backward compatibility
     * @deprecated Use the enhanced constructor with statistics
     */
    @Deprecated
    public SendResult(@NonNull List<Recipient> completed, @NonNull List<RecipientId> skipped, @NonNull List<RecipientId> unregistered) {
      this(completed, skipped, unregistered, new ArrayList<>(), new ArrayList<>(), new ArrayList<>(),
           new ArrayList<>(), new ArrayList<>(), new ArrayList<>(), new HashMap<>(),
           new SendResultStatistics(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, new HashMap<>(), 0, 0, 0, 0, 0),
           new ArrayList<>(), new ArrayList<>(), new ArrayList<>(), new HashMap<>(), new HashMap<>());
    }

    /**
     * Enhanced constructor with comprehensive failure tracking, statistics, and legitimacy analysis
     */
    public SendResult(@NonNull List<Recipient> completed,
                      @NonNull List<RecipientId> skipped,
                      @NonNull List<RecipientId> unregistered,
                      @NonNull List<RecipientId> networkFailures,
                      @NonNull List<RecipientId> identityFailures,
                      @NonNull List<RecipientId> rateLimitFailures,
                      @NonNull List<RecipientId> proofRequired,
                      @NonNull List<RecipientId> invalidPreKeys,
                      @NonNull List<RecipientId> retryable,
                      @NonNull Map<RecipientId, String> failureDetails,
                      @NonNull SendResultStatistics statistics,
                      @NonNull List<RecipientId> legitimateRejections,
                      @NonNull List<RecipientId> suspectedFalsePositives,
                      @NonNull List<RecipientId> trustedContacts,
                      @NonNull Map<RecipientId, LegitimacyScore> legitimacyScores,
                      @NonNull Map<RecipientId, String> overrideRecommendations) {
      this.completed                = completed;
      this.skipped                  = skipped;
      this.unregistered             = unregistered;
      this.networkFailures          = networkFailures;
      this.identityFailures         = identityFailures;
      this.rateLimitFailures        = rateLimitFailures;
      this.proofRequired            = proofRequired;
      this.invalidPreKeys           = invalidPreKeys;
      this.retryable                = retryable;
      this.failureDetails           = failureDetails;
      this.statistics               = statistics;
      this.legitimateRejections     = legitimateRejections;
      this.suspectedFalsePositives  = suspectedFalsePositives;
      this.trustedContacts          = trustedContacts;
      this.legitimacyScores         = legitimacyScores;
      this.overrideRecommendations  = overrideRecommendations;
    }

    /**
     * Check if there are any retryable failures
     */
    public boolean hasRetryableFailures() {
      return !retryable.isEmpty();
    }

    /**
     * Check if there are any security-related failures (identity mismatches)
     */
    public boolean hasSecurityFailures() {
      return !identityFailures.isEmpty();
    }

    /**
     * Check if any failures require user action
     */
    public boolean requiresUserAction() {
      return !proofRequired.isEmpty();
    }

    /**
     * Get the success rate as a percentage
     */
    public int getSuccessPercentage() {
      return statistics.getSuccessPercentage();
    }

    /**
     * Get a human-readable summary of the results
     */
    public String getSummary() {
      return String.format(
          "Send Results: %d total, %d success (%.1f%%), %d failed, %d retryable",
          statistics.totalResults,
          statistics.successCount,
          statistics.getSuccessPercentage(),
          statistics.totalFailures,
          retryable.size()
      );
    }

    // ===== Legitimacy Analysis Methods =====

    /**
     * Check if any failures are suspected to be false positives (wrongful rejections)
     */
    public boolean hasSuspectedFalsePositives() {
      return !suspectedFalsePositives.isEmpty();
    }

    /**
     * Check if any trusted contacts failed
     */
    public boolean hasTrustedContactFailures() {
      return statistics.trustedContactFailureCount > 0;
    }

    /**
     * Get legitimacy score for a specific recipient
     */
    public @Nullable LegitimacyScore getLegitimacyScore(@NonNull RecipientId recipientId) {
      return legitimacyScores.get(recipientId);
    }

    /**
     * Get override recommendation for a specific recipient
     */
    public @Nullable String getOverrideRecommendation(@NonNull RecipientId recipientId) {
      return overrideRecommendations.get(recipientId);
    }

    /**
     * Get the false positive rate as a percentage
     */
    public int getFalsePositivePercentage() {
      if (statistics.totalFailures == 0) return 0;
      return (int) ((suspectedFalsePositives.size() * 100.0) / statistics.totalFailures);
    }
  }

  /**
   * SendResultStatistics - Comprehensive metrics for send operations
   *
   * Tracks detailed statistics about message sending operations for monitoring,
   * analysis, and debugging. Provides percentage calculations and aggregated counts.
   * Includes legitimacy analysis metrics for detecting wrongful rejections.
   */
  public static class SendResultStatistics {
    // Core metrics
    public final int totalResults;
    public final int successCount;
    public final int totalFailures;

    // Failure type metrics
    public final int networkFailureCount;
    public final int identityFailureCount;
    public final int unregisteredCount;
    public final int rateLimitFailureCount;
    public final int proofRequiredCount;
    public final int invalidPreKeyCount;
    public final int retryableCount;

    // Processing metrics
    public final long processingDurationMs;
    public final Map<String, Integer> failureTypeCounts;

    // Legitimacy analysis metrics (Wrongful Rejection Prevention)
    public final int suspectedFalsePositiveCount;
    public final int trustedContactFailureCount;
    public final int legitimateRejectionCount;
    public final int suspectedFalsePositivePercentage;
    public final int trustedContactCount;

    public SendResultStatistics(int totalResults,
                                int successCount,
                                int totalFailures,
                                int networkFailureCount,
                                int identityFailureCount,
                                int unregisteredCount,
                                int rateLimitFailureCount,
                                int proofRequiredCount,
                                int invalidPreKeyCount,
                                int retryableCount,
                                long processingDurationMs,
                                @NonNull Map<String, Integer> failureTypeCounts,
                                int suspectedFalsePositiveCount,
                                int trustedContactFailureCount,
                                int legitimateRejectionCount,
                                int suspectedFalsePositivePercentage,
                                int trustedContactCount) {
      this.totalResults                      = totalResults;
      this.successCount                      = successCount;
      this.totalFailures                     = totalFailures;
      this.networkFailureCount               = networkFailureCount;
      this.identityFailureCount              = identityFailureCount;
      this.unregisteredCount                 = unregisteredCount;
      this.rateLimitFailureCount             = rateLimitFailureCount;
      this.proofRequiredCount                = proofRequiredCount;
      this.invalidPreKeyCount                = invalidPreKeyCount;
      this.retryableCount                    = retryableCount;
      this.processingDurationMs              = processingDurationMs;
      this.failureTypeCounts                 = new HashMap<>(failureTypeCounts);
      this.suspectedFalsePositiveCount       = suspectedFalsePositiveCount;
      this.trustedContactFailureCount        = trustedContactFailureCount;
      this.legitimateRejectionCount          = legitimateRejectionCount;
      this.suspectedFalsePositivePercentage  = suspectedFalsePositivePercentage;
      this.trustedContactCount               = trustedContactCount;
    }

    /**
     * Calculate success percentage (0-100)
     */
    public int getSuccessPercentage() {
      if (totalResults == 0) return 0;
      return (int) ((successCount * 100.0) / totalResults);
    }

    /**
     * Calculate failure percentage (0-100)
     */
    public int getFailurePercentage() {
      if (totalResults == 0) return 0;
      return (int) ((totalFailures * 100.0) / totalResults);
    }

    /**
     * Calculate retry potential percentage (0-100)
     */
    public int getRetryPercentage() {
      if (totalFailures == 0) return 0;
      return (int) ((retryableCount * 100.0) / totalFailures);
    }

    /**
     * Check if the overall send operation was successful (>= 50% success rate)
     */
    public boolean isOverallSuccess() {
      return getSuccessPercentage() >= 50;
    }

    /**
     * Check if this operation had high failure rate (>= 50% failures)
     */
    public boolean hasHighFailureRate() {
      return getFailurePercentage() >= 50;
    }

    /**
     * Get count for a specific failure type
     */
    public int getFailureTypeCount(@NonNull String failureType) {
      return failureTypeCounts.getOrDefault(failureType, 0);
    }

    /**
     * Calculate false positive rate (percentage of failures that appear wrongful)
     */
    public int getFalsePositiveRate() {
      if (totalFailures == 0) return 0;
      return (int) ((suspectedFalsePositiveCount * 100.0) / totalFailures);
    }

    /**
     * Check if false positive rate is concerning (>= 30%)
     */
    public boolean hasHighFalsePositiveRate() {
      return getFalsePositiveRate() >= 30;
    }
  }

  /**
   * LegitimacyScore - Represents the legitimacy assessment for a recipient
   *
   * This class encapsulates the legitimacy analysis used to detect potential
   * wrongful rejections of legitimate communication requests.
   *
   * Scoring Methodology:
   * ====================
   *
   * 1. Recipient's Contact Status and Relationship (0-40 points):
   *    - System Contact: +25 points
   *      Determined by: recipient.isSystemContact()
   *      Rationale: Contacts in device address book are known/trusted
   *
   *    - Profile Sharing: +15 points
   *      Determined by: recipient.isProfileSharing() OR recipient.hasAUserSetDisplayName()
   *      Rationale: Profile sharing indicates established relationship
   *
   *    - Group Membership: +10 points
   *      Determined by: recipient.isGroup() OR recipient.getGroupId().isPresent()
   *      Rationale: Shared group context implies legitimate communication
   *
   * 2. Historical Success Rate and Reliability:
   *    - Currently uses contact relationship as proxy for historical reliability
   *    - System contacts and profile-sharing contacts assumed to have good history
   *    - Future enhancement: Track actual send success history per recipient
   *
   * 3. Nature of Current Failure:
   *    - Transient failures (network, rate limit) on high-reputation recipients
   *      are flagged as likely false positives
   *    - Permanent failures (unregistered) are considered legitimate rejections
   *    - Security failures (identity mismatch) are never considered false positives
   *
   * 4. System/Profile Indicators of Legitimacy:
   *    - System contact status (from device address book)
   *    - User-set display names (manual contact labeling)
   *    - Profile sharing enabled (mutual relationship)
   *    - Group membership (shared communication context)
   *
   * Thresholds:
   * ===========
   * - TRUSTED threshold: >= 80 points (HIGH_REPUTATION_THRESHOLD)
   * - High reputation: >= 60 points
   * - Neutral: 50 points (default baseline)
   * - Suspicious: < 50 points
   *
   * False Positive Detection:
   * ========================
   * A failure is flagged as a suspected false positive if:
   * - Recipient is TRUSTED (>= 80 points) AND has any failure
   * - Recipient has high reputation (>= 60 points) AND has transient failure (network/rate limit)
   * - Recipient is system contact AND has network failure
   */
  public static class LegitimacyScore {
    /** Reputation score (0-100), higher = more legitimate */
    public final int reputationScore;

    /** Whether this recipient is considered a trusted contact */
    public final boolean isTrustedContact;

    /** Whether this failure appears to be a false positive (wrongful rejection) */
    public final boolean isSuspectedFalsePositive;

    /** Legitimacy classification level */
    public final String legitimacyLevel;

    public LegitimacyScore(int reputationScore, boolean isTrustedContact, boolean isSuspectedFalsePositive, String legitimacyLevel) {
      this.reputationScore = reputationScore;
      this.isTrustedContact = isTrustedContact;
      this.isSuspectedFalsePositive = isSuspectedFalsePositive;
      this.legitimacyLevel = legitimacyLevel;
    }

    @Override
    public String toString() {
      return String.format("LegitimacyScore{score=%d, trusted=%b, falsePositive=%b, level=%s}",
                           reputationScore, isTrustedContact, isSuspectedFalsePositive, legitimacyLevel);
    }
  }
}
