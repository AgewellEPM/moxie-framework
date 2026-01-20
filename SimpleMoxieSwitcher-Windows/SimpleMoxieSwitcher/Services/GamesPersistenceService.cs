using System;
using System.Text.Json;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Centralized service for all Games database operations
    /// </summary>
    public class GamesPersistenceService : IGamesPersistenceService
    {
        private readonly IDockerService _dockerService;
        private readonly string _deviceId = "moxie_001";

        public GamesPersistenceService(IDockerService dockerService)
        {
            _dockerService = dockerService;
        }

        // MARK: - Game Stats

        public async Task<PersistenceResult<GameStats>> LoadGameStatsAsync()
        {
            try
            {
                var script = $@"
import json
from hive.models import MoxieDevice, PersistentData

device = MoxieDevice.objects.filter(device_id='{_deviceId}').first()
if device:
    persist = PersistentData.objects.filter(device=device).first()
    if persist and persist.data:
        stats = persist.data.get('game_stats')
        if stats:
            print(json.dumps(stats))
        else:
            print('null')
    else:
        print('null')
else:
    print('null')
";

                var result = await _dockerService.ExecutePythonScriptAsync(script);

                if (result.Trim() == "null" || string.IsNullOrEmpty(result))
                {
                    return PersistenceResult<GameStats>.Success(new GameStats());
                }

                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                var stats = JsonSerializer.Deserialize<GameStats>(result, options);
                return PersistenceResult<GameStats>.Success(stats ?? new GameStats());
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading game stats: {ex.Message}");
                return PersistenceResult<GameStats>.Failure(PersistenceError.LoadFailed);
            }
        }

        public async Task<PersistenceResult<bool>> SaveGameStatsAsync(GameStats stats)
        {
            try
            {
                var options = new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                };
                var jsonString = JsonSerializer.Serialize(stats, options);

                var script = $@"
import json
from hive.models import MoxieDevice, PersistentData

device = MoxieDevice.objects.filter(device_id='{_deviceId}').first()
if device:
    persist, created = PersistentData.objects.get_or_create(
        device=device,
        defaults={{'data': {{}}}}
    )
    data = persist.data or {{}}
    data['game_stats'] = {jsonString}
    persist.data = data
    persist.save()
    print('success')
";

                await _dockerService.ExecutePythonScriptAsync(script);
                return PersistenceResult<bool>.Success(true);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error saving game stats: {ex.Message}");
                return PersistenceResult<bool>.Failure(PersistenceError.SaveFailed);
            }
        }

        public async Task<PersistenceResult<bool>> RecordGameSessionAsync(GameSession session)
        {
            try
            {
                var options = new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                };
                var sessionString = JsonSerializer.Serialize(session, options);

                var script = $@"
import json
from hive.models import MoxieDevice, PersistentData

device = MoxieDevice.objects.filter(device_id='{_deviceId}').first()
if device:
    persist, created = PersistentData.objects.get_or_create(
        device=device,
        defaults={{'data': {{}}}}
    )
    data = persist.data or {{}}

    # Get current stats or create new
    stats = data.get('game_stats', {{
        'gamesPlayed': 0,
        'totalScore': 0,
        'averageScore': 0,
        'lastPlayed': None
    }})

    # Update stats from session
    session_data = {sessionString}
    stats['gamesPlayed'] = stats.get('gamesPlayed', 0) + 1
    stats['totalScore'] = stats.get('totalScore', 0) + session_data.get('score', 0)
    stats['averageScore'] = stats['totalScore'] / stats['gamesPlayed']
    stats['lastPlayed'] = session_data.get('timestamp')

    data['game_stats'] = stats
    persist.data = data
    persist.save()
    print('success')
";

                await _dockerService.ExecutePythonScriptAsync(script);
                return PersistenceResult<bool>.Success(true);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error recording game session: {ex.Message}");
                return PersistenceResult<bool>.Failure(PersistenceError.SaveFailed);
            }
        }

        // MARK: - Quest Progress

        public async Task<PersistenceResult<QuestProgress>> LoadQuestProgressAsync()
        {
            try
            {
                var script = $@"
import json
from hive.models import MoxieDevice, PersistentData

device = MoxieDevice.objects.filter(device_id='{_deviceId}').first()
if device:
    persist = PersistentData.objects.filter(device=device).first()
    if persist and persist.data:
        progress = persist.data.get('quest_progress')
        if progress:
            print(json.dumps(progress))
        else:
            print('null')
    else:
        print('null')
else:
    print('null')
";

                var result = await _dockerService.ExecutePythonScriptAsync(script);

                if (result.Trim() == "null" || string.IsNullOrEmpty(result))
                {
                    return PersistenceResult<QuestProgress>.Success(new QuestProgress());
                }

                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                var progress = JsonSerializer.Deserialize<QuestProgress>(result, options);
                return PersistenceResult<QuestProgress>.Success(progress ?? new QuestProgress());
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading quest progress: {ex.Message}");
                return PersistenceResult<QuestProgress>.Failure(PersistenceError.LoadFailed);
            }
        }

        public async Task<PersistenceResult<bool>> SaveQuestProgressAsync(QuestProgress progress)
        {
            try
            {
                var options = new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                };
                var jsonString = JsonSerializer.Serialize(progress, options);

                var script = $@"
import json
from hive.models import MoxieDevice, PersistentData

device = MoxieDevice.objects.filter(device_id='{_deviceId}').first()
if device:
    persist, created = PersistentData.objects.get_or_create(
        device=device,
        defaults={{'data': {{}}}}
    )
    data = persist.data or {{}}
    data['quest_progress'] = {jsonString}
    persist.data = data
    persist.save()
    print('success')
";

                await _dockerService.ExecutePythonScriptAsync(script);
                return PersistenceResult<bool>.Success(true);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error saving quest progress: {ex.Message}");
                return PersistenceResult<bool>.Failure(PersistenceError.SaveFailed);
            }
        }
    }

    // MARK: - Persistence Result

    public class PersistenceResult<T>
    {
        public bool IsSuccess { get; }
        public T Value { get; }
        public PersistenceError Error { get; }

        private PersistenceResult(bool isSuccess, T value, PersistenceError error)
        {
            IsSuccess = isSuccess;
            Value = value;
            Error = error;
        }

        public static PersistenceResult<T> Success(T value)
        {
            return new PersistenceResult<T>(true, value, PersistenceError.None);
        }

        public static PersistenceResult<T> Failure(PersistenceError error)
        {
            return new PersistenceResult<T>(false, default, error);
        }
    }

    public enum PersistenceError
    {
        None,
        SaveFailed,
        LoadFailed,
        EncodingFailed,
        DecodingFailed,
        DeviceNotFound
    }

    // MARK: - Interface

    public interface IGamesPersistenceService
    {
        Task<PersistenceResult<GameStats>> LoadGameStatsAsync();
        Task<PersistenceResult<bool>> SaveGameStatsAsync(GameStats stats);
        Task<PersistenceResult<bool>> RecordGameSessionAsync(GameSession session);
        Task<PersistenceResult<QuestProgress>> LoadQuestProgressAsync();
        Task<PersistenceResult<bool>> SaveQuestProgressAsync(QuestProgress progress);
    }
}
