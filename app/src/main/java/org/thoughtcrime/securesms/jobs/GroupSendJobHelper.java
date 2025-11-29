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
 * - Retry recommendation logic
 * - Rate limit and network failure detection
 * - Detailed logging with contextual information
 */
final class GroupSendJobHelper {

  private static final String TAG = Log.tag(GroupSendJobHelper.class);

  private GroupSendJobHelper() {
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

    int successCount = 0;
    int totalFailures = 0;
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

    // Create comprehensive statistics
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
        failureTypeCounts
    );

    // Log comprehensive summary
    logSummary(statistics, failureDetails);

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
        statistics
    );
  }

  /**
   * Increment failure type counter
   */
  private static void incrementFailureCount(@NonNull Map<String, Integer> counts, @NonNull String failureType) {
    counts.put(failureType, counts.getOrDefault(failureType, 0) + 1);
  }

  /**
   * Log comprehensive summary of send results
   */
  private static void logSummary(@NonNull SendResultStatistics stats, @NonNull Map<RecipientId, String> failureDetails) {
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
    Log.i(TAG, "│ Retry Analysis:");
    Log.i(TAG, "│   Retryable:        " + stats.retryableCount + " failures can be retried");
    Log.i(TAG, "│   Processing Time:  " + stats.processingDurationMs + "ms");
    Log.i(TAG, "└─────────────────────────────────────────────────────────");

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

    /**
     * Legacy constructor - maintained for backward compatibility
     * @deprecated Use the enhanced constructor with statistics
     */
    @Deprecated
    public SendResult(@NonNull List<Recipient> completed, @NonNull List<RecipientId> skipped, @NonNull List<RecipientId> unregistered) {
      this(completed, skipped, unregistered, new ArrayList<>(), new ArrayList<>(), new ArrayList<>(),
           new ArrayList<>(), new ArrayList<>(), new ArrayList<>(), new HashMap<>(),
           new SendResultStatistics(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, new HashMap<>()));
    }

    /**
     * Enhanced constructor with comprehensive failure tracking and statistics
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
                      @NonNull SendResultStatistics statistics) {
      this.completed         = completed;
      this.skipped           = skipped;
      this.unregistered      = unregistered;
      this.networkFailures   = networkFailures;
      this.identityFailures  = identityFailures;
      this.rateLimitFailures = rateLimitFailures;
      this.proofRequired     = proofRequired;
      this.invalidPreKeys    = invalidPreKeys;
      this.retryable         = retryable;
      this.failureDetails    = failureDetails;
      this.statistics        = statistics;
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
  }

  /**
   * SendResultStatistics - Comprehensive metrics for send operations
   *
   * Tracks detailed statistics about message sending operations for monitoring,
   * analysis, and debugging. Provides percentage calculations and aggregated counts.
   */
  public static class SendResultStatistics {
    public final int totalResults;
    public final int successCount;
    public final int totalFailures;
    public final int networkFailureCount;
    public final int identityFailureCount;
    public final int unregisteredCount;
    public final int rateLimitFailureCount;
    public final int proofRequiredCount;
    public final int invalidPreKeyCount;
    public final int retryableCount;
    public final long processingDurationMs;
    public final Map<String, Integer> failureTypeCounts;

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
                                @NonNull Map<String, Integer> failureTypeCounts) {
      this.totalResults          = totalResults;
      this.successCount          = successCount;
      this.totalFailures         = totalFailures;
      this.networkFailureCount   = networkFailureCount;
      this.identityFailureCount  = identityFailureCount;
      this.unregisteredCount     = unregisteredCount;
      this.rateLimitFailureCount = rateLimitFailureCount;
      this.proofRequiredCount    = proofRequiredCount;
      this.invalidPreKeyCount    = invalidPreKeyCount;
      this.retryableCount        = retryableCount;
      this.processingDurationMs  = processingDurationMs;
      this.failureTypeCounts     = new HashMap<>(failureTypeCounts);
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
  }
}
