// player_repository.dart
import '../constants/api_constants.dart';
import '../core/api_client.dart';
import '../models/player.dart';

class PlayerRepository {
  final ApiClient _client = const ApiClient();

  Future<List<PlayerModel>> getPlayers() async {
    final response =
    await _client.get(ApiConstants.players);

    //final List players = response['players'];
    final List players = response['data']['players'];

    return players
        .map((e) => PlayerModel.fromJson(e))
        .toList();
  }
}
