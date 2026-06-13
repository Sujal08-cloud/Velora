import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static String userIdKey="USERIDKEY";
  static String userNameKey="USERNAMEKEY";
  static String userEmailKey="USEREMAILKEY";
  static String userWalletKey="USERWALLETKEY";

  Future<bool> saveUserId(String getUserId)async{
    SharedPreferences prefs= await SharedPreferences.getInstance();
    return prefs.setString(userIdKey, getUserId);
  }
  Future<String?> getUserName() async {
  SharedPreferences prefs =
      await SharedPreferences.getInstance();

  return prefs.getString(userNameKey);
}

Future<String?> getUserEmail() async {
  SharedPreferences prefs =
      await SharedPreferences.getInstance();

  return prefs.getString(userEmailKey);
}

  Future<bool> saveUserWallet(String getUserWallet)async{
    SharedPreferences prefs= await SharedPreferences.getInstance();
    return prefs.setString(userWalletKey, getUserWallet);
  }

  Future<bool> saveUserName(String getUserName)async{
    SharedPreferences prefs= await SharedPreferences.getInstance();
    return prefs.setString(userNameKey, getUserName);
  }

  Future<bool> saveUserEmail(String getUserEmail)async{
    SharedPreferences prefs= await SharedPreferences.getInstance();
    return prefs.setString(userEmailKey, getUserEmail);
  }

  Future<String?> getUserWallet() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(userWalletKey);
}
    Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

}