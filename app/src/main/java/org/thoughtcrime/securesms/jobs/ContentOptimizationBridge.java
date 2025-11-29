package org.thoughtcrime.securesms.jobs;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.signal.core.util.logging.Log;
import org.thoughtcrime.securesms.recipients.Recipient;
import org.thoughtcrime.securesms.recipients.RecipientId;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.util.HashMap;
import java.util.Map;

/**
 * Content Optimization Bridge for Claude Rejection Reducer
 *
 * This class bridges the Claude Rejection Reducer with external content optimization
 * tools (intelligent_context_chopper.py, integrated_context_optimizer.py, token_optimizer.py).
 *
 * It provides content preprocessing to reduce rejection risk BEFORE messages are sent,
 * working in tandem with the post-send rejection analysis.
 *
 * Integration Flow:
 * =================
 * 1. Message content is submitted for sending
 * 2. ContentOptimizationBridge assesses legitimacy (via Claude Rejection Reducer)
 * 3. Content is optimized based on legitimacy score
 * 4. Optimized content is sent
 * 5. Claude Rejection Reducer analyzes results
 * 6. False positives are detected and flagged
 *
 * This creates a comprehensive two-layer system:
 * - PREVENTION (this class): Optimize content to avoid rejections
 * - DETECTION (Claude Rejection Reducer): Identify wrongful rejections
 */
public final class ContentOptimizationBridge {

  private static final String TAG = Log.tag(ContentOptimizationBridge.class);

  // Python script paths (relative to project root)
  private static final String CONTEXT_CHOPPER_SCRIPT = "scripts/intelligent_context_chopper.py";
  private static final String CONTEXT_OPTIMIZER_SCRIPT = "scripts/integrated_context_optimizer.py";
  private static final String TOKEN_OPTIMIZER_SCRIPT = "scripts/token_optimizer.py";

  // Cache for optimization results
  private static final Map<String, OptimizationResult> optimizationCache = new HashMap<>();

  // Statistics
  private static long totalOptimizations = 0;
  private static long cacheHits = 0;
  private static long scriptExecutions = 0;
  private static long optimizationFailures = 0;

  private ContentOptimizationBridge() {
    // Static utility class
  }

  /**
   * Optimize message content based on Claude Rejection Reducer context
   *
   * @param content Original message content
   * @param recipient Target recipient
   * @return OptimizationResult with optimized content and metadata
   */
  public static @NonNull OptimizationResult optimizeContent(@NonNull String content,
                                                             @NonNull Recipient recipient) {
    totalOptimizations++;

    // Check cache first
    String cacheKey = getCacheKey(content, recipient.getId());
    if (optimizationCache.containsKey(cacheKey)) {
      cacheHits++;
      Log.d(TAG, "[Content Optimization Bridge] Cache hit for recipient " + recipient.getId());
      return optimizationCache.get(cacheKey);
    }

    // Assess recipient legitimacy using same logic as Claude Rejection Reducer
    LegitimacyAssessment legitimacy = assessLegitimacy(recipient);

    Log.i(TAG, String.format(
        "[Content Optimization Bridge] Optimizing content for %s (legitimacy: %d%%, trusted: %b)",
        recipient.getId(),
        legitimacy.score,
        legitimacy.isTrusted
    ));

    // Determine if optimization is needed
    if (!RejectionReducerConfig.ENABLE_LEGITIMACY_SCORING) {
      Log.d(TAG, "[Content Optimization Bridge] Legitimacy scoring disabled, skipping optimization");
      return new OptimizationResult(content, content, false, legitimacy);
    }

    // Skip optimization for very trusted contacts (pass through)
    if (legitimacy.isTrusted && legitimacy.score >= 90) {
      Log.d(TAG, "[Content Optimization Bridge] Very trusted contact, passing through without optimization");
      return new OptimizationResult(content, content, false, legitimacy);
    }

    // Execute optimization pipeline
    OptimizationResult result = executeOptimizationPipeline(content, legitimacy);

    // Cache result
    optimizationCache.put(cacheKey, result);

    // Log optimization statistics
    logOptimizationStats(result);

    return result;
  }

  /**
   * Assess recipient legitimacy using Claude Rejection Reducer logic
   */
  private static @NonNull LegitimacyAssessment assessLegitimacy(@NonNull Recipient recipient) {
    int score = RejectionReducerConfig.NEUTRAL_BASELINE_SCORE;

    // Mirror Claude Rejection Reducer scoring logic
    if (recipient.isSystemContact()) {
      score += RejectionReducerConfig.SYSTEM_CONTACT_POINTS;
    }

    if (recipient.isProfileSharing() || recipient.hasAUserSetDisplayName(recipient.getContext())) {
      score += RejectionReducerConfig.PROFILE_SHARING_POINTS;
    }

    if (recipient.isGroup() || recipient.getGroupId().isPresent()) {
      score += RejectionReducerConfig.GROUP_MEMBERSHIP_POINTS;
    }

    // Cap at maximum
    if (score > RejectionReducerConfig.MAX_LEGITIMACY_SCORE) {
      score = RejectionReducerConfig.MAX_LEGITIMACY_SCORE;
    }

    boolean isTrusted = score >= RejectionReducerConfig.TRUSTED_THRESHOLD;

    return new LegitimacyAssessment(score, isTrusted);
  }

  /**
   * Execute the optimization pipeline using external scripts
   */
  private static @NonNull OptimizationResult executeOptimizationPipeline(
      @NonNull String content,
      @NonNull LegitimacyAssessment legitimacy) {

    try {
      scriptExecutions++;

      // Try to execute integrated_context_optimizer.py
      String optimizedContent = executeOptimizerScript(content, legitimacy);

      if (optimizedContent != null && !optimizedContent.equals(content)) {
        Log.i(TAG, "[Content Optimization Bridge] ✓ Content successfully optimized");
        return new OptimizationResult(content, optimizedContent, true, legitimacy);
      } else {
        Log.d(TAG, "[Content Optimization Bridge] No optimization needed or script unavailable");
        return new OptimizationResult(content, content, false, legitimacy);
      }

    } catch (Exception e) {
      optimizationFailures++;
      Log.w(TAG, "[Content Optimization Bridge] Optimization failed, using original content: " + e.getMessage());
      return new OptimizationResult(content, content, false, legitimacy);
    }
  }

  /**
   * Execute Python optimizer script
   */
  private static @Nullable String executeOptimizerScript(@NonNull String content,
                                                          @NonNull LegitimacyAssessment legitimacy) {
    try {
      // Build command
      ProcessBuilder pb = new ProcessBuilder(
          "python3",
          CONTEXT_OPTIMIZER_SCRIPT,
          "--content", content,
          "--legitimacy-score", String.valueOf(legitimacy.score),
          "--trusted", String.valueOf(legitimacy.isTrusted),
          "--output-format", "text"
      );

      pb.redirectErrorStream(true);
      Process process = pb.start();

      // Read output
      StringBuilder output = new StringBuilder();
      try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
        String line;
        while ((line = reader.readLine()) != null) {
          output.append(line).append("\n");
        }
      }

      int exitCode = process.waitFor();

      if (exitCode == 0) {
        return output.toString().trim();
      } else {
        Log.w(TAG, "[Content Optimization Bridge] Script exited with code: " + exitCode);
        return null;
      }

    } catch (Exception e) {
      Log.w(TAG, "[Content Optimization Bridge] Script execution failed: " + e.getMessage());
      return null;
    }
  }

  /**
   * Generate cache key
   */
  private static @NonNull String getCacheKey(@NonNull String content, @NonNull RecipientId recipientId) {
    return content.hashCode() + ":" + recipientId.serialize();
  }

  /**
   * Log optimization statistics
   */
  private static void logOptimizationStats(@NonNull OptimizationResult result) {
    if (RejectionReducerConfig.ENABLE_DETAILED_LOGGING && result.wasOptimized) {
      int originalLength = result.originalContent.length();
      int optimizedLength = result.optimizedContent.length();
      float reduction = (1.0f - ((float) optimizedLength / originalLength)) * 100;

      Log.i(TAG, String.format(
          "[Content Optimization Bridge] Optimized: %d → %d chars (%.1f%% reduction)",
          originalLength,
          optimizedLength,
          reduction
      ));
    }
  }

  /**
   * Get optimization statistics
   */
  public static @NonNull Map<String, Object> getStatistics() {
    Map<String, Object> stats = new HashMap<>();
    stats.put("total_optimizations", totalOptimizations);
    stats.put("cache_hits", cacheHits);
    stats.put("cache_hit_rate", totalOptimizations > 0 ? (cacheHits * 100.0 / totalOptimizations) : 0);
    stats.put("script_executions", scriptExecutions);
    stats.put("optimization_failures", optimizationFailures);
    stats.put("failure_rate", scriptExecutions > 0 ? (optimizationFailures * 100.0 / scriptExecutions) : 0);
    return stats;
  }

  /**
   * Clear optimization cache
   */
  public static void clearCache() {
    optimizationCache.clear();
    Log.i(TAG, "[Content Optimization Bridge] Cache cleared");
  }

  /**
   * Legitimacy assessment result (mirrored from Claude Rejection Reducer)
   */
  public static class LegitimacyAssessment {
    public final int score;
    public final boolean isTrusted;

    public LegitimacyAssessment(int score, boolean isTrusted) {
      this.score = score;
      this.isTrusted = isTrusted;
    }
  }

  /**
   * Optimization result
   */
  public static class OptimizationResult {
    public final String originalContent;
    public final String optimizedContent;
    public final boolean wasOptimized;
    public final LegitimacyAssessment legitimacy;

    public OptimizationResult(@NonNull String originalContent,
                               @NonNull String optimizedContent,
                               boolean wasOptimized,
                               @NonNull LegitimacyAssessment legitimacy) {
      this.originalContent = originalContent;
      this.optimizedContent = optimizedContent;
      this.wasOptimized = wasOptimized;
      this.legitimacy = legitimacy;
    }

    /**
     * Get the content to use for sending (optimized if available, original otherwise)
     */
    public @NonNull String getContentForSending() {
      return wasOptimized ? optimizedContent : originalContent;
    }
  }
}
