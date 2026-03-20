import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/repositories/project_repository.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/error_dialog.dart';
import 'settings_section_widget.dart';

class DataManagementWidget extends StatelessWidget {
  const DataManagementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWidget(
      title: 'Data Management',
      icon: Icons.storage_rounded,
      children: [
        CustomButton(
          text: AppStrings.clearAllProjects,
          isOutlined: true,
          height: 40,
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder:
                  (_) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Clear All Projects?'),
                    content: const Text(
                      'This will delete all saved projects and cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Delete All',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
            );
            if (confirm == true) {
              await ProjectRepository().clearAll();
              if (context.mounted) {
                ErrorDialog.showSuccess(context, 'All projects cleared');
              }
            }
          },
        ),
      ],
    );
  }
}
