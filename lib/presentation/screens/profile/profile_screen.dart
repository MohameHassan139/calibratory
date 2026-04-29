import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/calibration_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final calibCtrl = Get.find<CalibrationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _ProfileHeader(auth: auth),
            const SizedBox(height: 28),
            _ProfileStats(calibCtrl: calibCtrl),
            const SizedBox(height: 24),
            _SettingsGroup(
              title: 'Account',
              items: [
                _SettingsItem(
                  icon: Icons.person_outline,
                  label: 'Edit Profile',
                  onTap: () => _showEditProfileDialog(context, auth),
                ),
                _SettingsItem(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  onTap: () {},
                  trailing: Obx(() => Text(
                        auth.appUser.value?.phone ?? '',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      )),
                ),
                _SettingsItem(
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  onTap: () => _showChangePasswordDialog(context, auth),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsGroup(
              title: 'Calibration',
              items: [
                _SettingsItem(
                  icon: Icons.download_rounded,
                  label: 'Download All Certificates',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.share_outlined,
                  label: 'Share Report',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsGroup(
              title: 'App',
              items: [
                _SettingsItem(
                  icon: Icons.info_outline,
                  label: 'About Caliborty',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  isDestructive: true,
                  onTap: () => _showLogoutConfirmation(context, auth),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Caliborty v1.0.0 · UMECC · Minia University',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthController auth) {
    final fullNameCtrl = TextEditingController(
      text: auth.appUser.value?.fullName ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: auth.appUser.value?.phone ?? '',
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fullNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: auth.isLoading.value
                    ? null
                    : () {
                        auth.updateProfile(
                          fullName: fullNameCtrl.text,
                          phone: phoneCtrl.text,
                        );
                      },
                child: auth.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              )),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthController auth) {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    final showCurrentPassword = false.obs;
    final showNewPassword = false.obs;
    final showConfirmPassword = false.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => TextField(
                    controller: currentPasswordCtrl,
                    obscureText: !showCurrentPassword.value,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(showCurrentPassword.value
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => showCurrentPassword.value =
                            !showCurrentPassword.value,
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
              Obx(() => TextField(
                    controller: newPasswordCtrl,
                    obscureText: !showNewPassword.value,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(showNewPassword.value
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            showNewPassword.value = !showNewPassword.value,
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
              Obx(() => TextField(
                    controller: confirmPasswordCtrl,
                    obscureText: !showConfirmPassword.value,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(showConfirmPassword.value
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => showConfirmPassword.value =
                            !showConfirmPassword.value,
                      ),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: auth.isLoading.value
                    ? null
                    : () {
                        if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                          Get.snackbar('Error', 'Passwords do not match',
                              snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        if (newPasswordCtrl.text.length < 6) {
                          Get.snackbar(
                              'Error', 'Password must be at least 6 characters',
                              snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        auth.changePassword(
                          currentPassword: currentPasswordCtrl.text,
                          newPassword: newPasswordCtrl.text,
                        );
                      },
                child: auth.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change'),
              )),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthController auth) {
    Get.dialog(
      AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child:
                const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final AuthController auth;
  const _ProfileHeader({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  backgroundImage: auth.appUser.value?.photoUrl != null
                      ? NetworkImage(auth.appUser.value!.photoUrl!)
                      : null,
                  child: auth.appUser.value?.photoUrl == null
                      ? Text(
                          (auth.appUser.value?.fullName.isNotEmpty ?? false)
                              ? auth.appUser.value!.fullName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded,
                      size: 14, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              auth.appUser.value?.fullName ?? 'Engineer',
              style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              auth.appUser.value?.email ?? '',
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'UMECC · Calibration Engineer',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ));
  }
}

class _ProfileStats extends StatelessWidget {
  final CalibrationController calibCtrl;
  const _ProfileStats({required this.calibCtrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
          children: [
            _StatItem(
                value: calibCtrl.history.length.toString(),
                label: 'Calibrations'),
            Container(height: 40, width: 1, color: AppColors.border),
            _StatItem(
                value: calibCtrl.history
                    .where((h) => h.overallResult == 'PASS')
                    .length
                    .toString(),
                label: 'Passed'),
            Container(height: 40, width: 1, color: AppColors.border),
            _StatItem(
                value: calibCtrl.history
                    .where((h) => h.overallResult == 'FAIL')
                    .length
                    .toString(),
                label: 'Failed'),
          ],
        ));
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Syne',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
