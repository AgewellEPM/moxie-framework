import Foundation

/// Centralized database scripts for Games system - eliminates duplication
enum GamesDatabaseScripts {
    /// Generate script to load data from persistent storage
    static func loadData(key: String) -> String {
        """
        import json
        from hive.models import MoxieDevice, PersistentData

        device = MoxieDevice.objects.filter(device_id='\(GamesPersistenceConfig.deviceID)').first()
        if device:
            persist = PersistentData.objects.filter(device=device).first()
            if persist and persist.data:
                data = persist.data.get('\(key)', None)
                print(json.dumps(data) if data else 'null')
            else:
                print('null')
        else:
            print('null')
        """
    }

    /// Generate script to save data to persistent storage
    static func saveData(key: String, jsonString: String) -> String {
        """
        import json
        from hive.models import MoxieDevice, PersistentData

        device = MoxieDevice.objects.filter(device_id='\(GamesPersistenceConfig.deviceID)').first()
        if device:
            persist, created = PersistentData.objects.get_or_create(device=device, defaults={'data': {}})
            data = persist.data or {}
            data['\(key)'] = json.loads('''\(jsonString)''')
            persist.data = data
            persist.save()
            print('success')
        else:
            print('error: device not found')
        """
    }

    /// Generate script to update game stats atomically
    static func updateGameStats(sessionJSON: String) -> String {
        """
        import json
        from hive.models import MoxieDevice, PersistentData

        device = MoxieDevice.objects.filter(device_id='\(GamesPersistenceConfig.deviceID)').first()
        if device:
            persist, created = PersistentData.objects.get_or_create(device=device, defaults={'data': {}})
            data = persist.data or {}

            # Get or create game stats
            game_stats = data.get('\(GamesPersistenceConfig.statsKey)', {
                'totalGamesPlayed': 0,
                'totalPoints': 0,
                'bestScore': 0,
                'averageAccuracy': 0.0,
                'gamesByType': {},
                'achievements': []
            })

            # Update stats
            session = json.loads('''\(sessionJSON)''')
            game_stats['totalGamesPlayed'] += 1
            game_stats['totalPoints'] += session['score']
            game_stats['bestScore'] = max(game_stats['bestScore'], session['score'])

            game_type = session['gameType']
            game_stats['gamesByType'][game_type] = game_stats['gamesByType'].get(game_type, 0) + 1

            # Update average accuracy
            accuracy = session['correctAnswers'] / session['questionsAnswered'] if session['questionsAnswered'] > 0 else 0
            total = game_stats['totalGamesPlayed']
            game_stats['averageAccuracy'] = (game_stats['averageAccuracy'] * (total - 1) + accuracy) / total

            # Save updated stats
            data['\(GamesPersistenceConfig.statsKey)'] = game_stats

            # Save session history
            game_sessions = data.get('game_sessions', [])
            game_sessions.append(session)
            data['game_sessions'] = game_sessions

            persist.data = data
            persist.save()
            print('success')
        else:
            print('error: device not found')
        """
    }
}
