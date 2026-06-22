import '../../core/constants/db_constants.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    super.id,
    required super.name,
    super.avatar,
    super.createdAt,
    super.currentStreak,
    super.maxStreak,
    super.totalAnswered,
    super.totalCorrect,
    super.studyGoalMinutes,
    super.notificationsEnabled,
    super.notificationHour,
    super.notificationMinute,
  });

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      avatar: user.avatar,
      createdAt: user.createdAt,
      currentStreak: user.currentStreak,
      maxStreak: user.maxStreak,
      totalAnswered: user.totalAnswered,
      totalCorrect: user.totalCorrect,
      studyGoalMinutes: user.studyGoalMinutes,
      notificationsEnabled: user.notificationsEnabled,
      notificationHour: user.notificationHour,
      notificationMinute: user.notificationMinute,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: _asInt(map[DbConstants.colUserId]),
      name: (map[DbConstants.colUserName] as String?) ?? '',
      avatar: map[DbConstants.colUserAvatar] as String?,
      createdAt: _asDateTime(map[DbConstants.colUserCreatedAt]),
      currentStreak: _asInt(map[DbConstants.colUserCurrentStreak]) ?? 0,
      maxStreak: _asInt(map[DbConstants.colUserMaxStreak]) ?? 0,
      totalAnswered: _asInt(map[DbConstants.colUserTotalAnswered]) ?? 0,
      totalCorrect: _asInt(map[DbConstants.colUserTotalCorrect]) ?? 0,
      studyGoalMinutes:
          _asInt(map[DbConstants.colUserStudyGoalMinutes]) ?? 30,
      notificationsEnabled: _asBool(
        map[DbConstants.colUserNotificationsEnabled],
        defaultValue: true,
      ),
      notificationHour: _asInt(map[DbConstants.colUserNotificationHour]) ?? 19,
      notificationMinute:
          _asInt(map[DbConstants.colUserNotificationMinute]) ?? 0,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) DbConstants.colUserId: id,
      DbConstants.colUserName: name,
      DbConstants.colUserAvatar: avatar,
      DbConstants.colUserCreatedAt: createdAt.toIso8601String(),
      DbConstants.colUserCurrentStreak: currentStreak,
      DbConstants.colUserMaxStreak: maxStreak,
      DbConstants.colUserTotalAnswered: totalAnswered,
      DbConstants.colUserTotalCorrect: totalCorrect,
      DbConstants.colUserStudyGoalMinutes: studyGoalMinutes,
      DbConstants.colUserNotificationsEnabled: notificationsEnabled ? 1 : 0,
      DbConstants.colUserNotificationHour: notificationHour,
      DbConstants.colUserNotificationMinute: notificationMinute,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}

int? _asInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _asBool(Object? value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

DateTime _asDateTime(Object? value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
