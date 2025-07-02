using System.Diagnostics;
using Microsoft.Extensions.Logging;

namespace Forge.Core.Resilience;

// NOTE: Simplistic version of System.Threading.RateLimiting.FixedWindowRateLimiter
public class FixedRateLimiter
{
  readonly int _maxRequestsPerSecond;
  readonly SemaphoreSlim _semaphoreBucket;
  readonly SemaphoreSlim _semaphoreConcurrent;
  protected readonly Timer _timer;
  readonly int[] retryPoliciesMs;
  readonly TimeSpan interval = TimeSpan.FromSeconds(1);

  public FixedRateLimiter(int maxRequestsPerSecond, int[]? retryPolicies = null)
  {
    _maxRequestsPerSecond = maxRequestsPerSecond;
    retryPoliciesMs = retryPolicies ?? [0]; // NOTE: usually flat retry: [1000, 1000, 1000] or exponential: [500, 1500, 3000]
    _semaphoreBucket = new SemaphoreSlim(_maxRequestsPerSecond);
    _semaphoreConcurrent = new SemaphoreSlim(_maxRequestsPerSecond);
    _timer = new Timer(ResetBucket, null, interval, interval);
  }

  void ResetConcurrent()
  {
    _semaphoreConcurrent.Release();
  }

  async Task WaitConcurrent(CancellationToken ct)
  {
    await _semaphoreConcurrent.WaitAsync(ct);
  }

  void ResetBucket(object? state)
  {
    _semaphoreBucket.Release(_maxRequestsPerSecond);
  }

  async Task WaitBucketAsync(CancellationToken ct)
  {
    await _semaphoreBucket.WaitAsync(ct);
  }

  public async Task ProcessDataAsync<T, R>(ILogger<R> logger, IEnumerable<T> data, Func<T, Task<RateLimiterStatus>> makeRequestAsync, CancellationToken ct)
  {
    var requestCount = 0;
    var totalTime = Stopwatch.StartNew();

    foreach (var item in data)
    {
      try
      {
        await WaitBucketAsync(ct);
        await WaitConcurrent(ct);
        var retryIndex = 0;
        foreach (var retryBackoff in retryPoliciesMs)
        {
          var status = await makeRequestAsync(item);

          if (status != RateLimiterStatus.RETRY)
          {
            break;
          }

          if (retryBackoff > 0)
          {
            logger.LogWarning("makeRequestAsync is retrying index: {retryIndex} with backoff {backoff}Ms", retryIndex, retryBackoff);
            retryIndex++;
            await Task.Delay(retryBackoff, ct);
          }
        }
        requestCount++;
      }
      finally
      {
        ResetConcurrent();
      }
    }

    totalTime.Stop();
    logger.LogInformation("ProcessData handled {requestsCount} requests in {durationMs}Ms with avg of {avgMs}Ms per request", requestCount, totalTime.ElapsedMilliseconds, requestCount == 0 ? 0 : totalTime.ElapsedMilliseconds / requestCount);
  }

  public enum RateLimiterStatus
  {
    SUCCESS = 0,
    ERROR = 1,
    RETRY = 2,
    EXCEPT = 99,
  }
}
