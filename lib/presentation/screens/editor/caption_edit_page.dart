import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../data/models/caption_model.dart';
import '../../providers/caption_provider.dart';

class CaptionEditPage extends StatelessWidget {
  const CaptionEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Edit Captions',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Apply',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CaptionProvider>(
        builder: (context, cp, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cp.captions.length,
            itemBuilder: (context, index) {
              final c = cp.captions[index];
              return EditableCaptionTile(
                caption: c,
                onTextChanged: (text) => cp.updateCaptionText(index, text),
                onDelete: () => cp.deleteCaption(index),
              );
            },
          );
        },
      ),
    );
  }
}

class EditableCaptionTile extends StatefulWidget {
  final CaptionModel caption;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onDelete;

  const EditableCaptionTile({
    super.key,
    required this.caption,
    required this.onTextChanged,
    required this.onDelete,
  });

  @override
  State<EditableCaptionTile> createState() => _EditableCaptionTileState();
}

class _EditableCaptionTileState extends State<EditableCaptionTile> {
  late TextEditingController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TextEditingController(text: widget.caption.text);
  }

  @override
  void didUpdateWidget(covariant EditableCaptionTile old) {
    super.didUpdateWidget(old);
    if (old.caption.text != widget.caption.text &&
        _tc.text != widget.caption.text) {
      _tc.text = widget.caption.text;
    }
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${TimeFormatter.durationToDisplay(widget.caption.startTime)} - '
                  '${TimeFormatter.durationToDisplay(widget.caption.endTime)}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tc,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: null,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: 'Enter caption text',
                  ),
                  onChanged: widget.onTextChanged,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: widget.onDelete,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
