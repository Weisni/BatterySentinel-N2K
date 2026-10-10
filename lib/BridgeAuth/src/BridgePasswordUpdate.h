#pragma once

namespace bs::auth {

// Generated once for the documented physical recovery procedure. This is a
// public recovery default, never an authentication factor for requesting reset.
inline constexpr char kRecoveryPassword[] = "X8T6W4BDABQMZCYH6V";

enum class PasswordUpdateResult {
    Saved, Forbidden, InvalidPassword, IncorrectCurrentPassword, StorageFailure
};

template <typename Settings, typename Text>
PasswordUpdateResult changeOwnPassword(Settings& settings, bool authorized,
                                      const Text& current, const Text& password,
                                      const Text& confirmation) {
    if (!authorized || !settings.hasAdmin()) return PasswordUpdateResult::Forbidden;
    if (password.length() < 12 || password.length() > 128 || password != confirmation)
        return PasswordUpdateResult::InvalidPassword;
    if (!settings.checkAdmin(settings.username(), current))
        return PasswordUpdateResult::IncorrectCurrentPassword;
    return settings.changePassword(password) ? PasswordUpdateResult::Saved
                                             : PasswordUpdateResult::StorageFailure;
}

template <typename Settings>
PasswordUpdateResult recoverPassword(Settings& settings, bool validRequest,
                                    bool bootHeld, bool confirmed) {
    if (!settings.hasAdmin() || !validRequest || !bootHeld || !confirmed)
        return PasswordUpdateResult::Forbidden;
    return settings.changePassword(kRecoveryPassword) ? PasswordUpdateResult::Saved
                                                      : PasswordUpdateResult::StorageFailure;
}

} // namespace bs::auth
