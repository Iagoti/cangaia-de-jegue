import 'package:cangaia_de_jegue/database/app_database.dart';
import 'package:cangaia_de_jegue/models/user_model.dart';

class AuthController {
  Future<UserModel?> login({
    required String username,
    required String password,
  }) {
    return AppDatabase.instance.authenticate(username, password);
  }
}
