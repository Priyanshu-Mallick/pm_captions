import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_dimensions.dart';
import '../../data/models/caption_model.dart';

/// Manages the list of captions and editing operations.
///
/// Supports undo/redo, inline editing, splitting, merging,
/// and position-based caption lookup.
class CaptionProvider extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────
  List<CaptionModel> _captions = [];
  int? _selectedCaptionIndex;
  bool _isEditing = false;

  // Undo/redo stacks
  final List<List<CaptionModel>> _undoStack = [];
  final List<List<CaptionModel>> _redoStack = [];

  // ── Getters ───────────────────────────────────────────────────────
  List<CaptionModel> get captions => List.unmodifiable(_captions);
  int? get selectedCaptionIndex => _selectedCaptionIndex;
  bool get isEditing => _isEditing;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  CaptionModel? get selectedCaption {
    if (_selectedCaptionIndex == null ||
        _selectedCaptionIndex! >= _captions.length) {
      return null;
    }
    return _captions[_selectedCaptionIndex!];
  }

  /// Sets the initial list of captions.
  void setCaptions(List<CaptionModel> captions) {
    _captions = List.from(captions);
    _undoStack.clear();
    _redoStack.clear();
    _selectedCaptionIndex = null;
    notifyListeners();
  }

  /// Returns the caption visible at the given video position.
  CaptionModel? getCaptionAtPosition(Duration position) {
    for (final caption in _captions) {
      if (position >= caption.startTime && position <= caption.endTime) {
        return caption;
      }
    }
    return null;
  }

  /// Returns the index of the caption at the given position.
  int? getCaptionIndexAtPosition(Duration position) {
    for (var i = 0; i < _captions.length; i++) {
      if (position >= _captions[i].startTime &&
          position <= _captions[i].endTime) {
        return i;
      }
    }
    return null;
  }

  /// Selects a caption by index.
  void selectCaption(int? index) {
    _selectedCaptionIndex = index;
    notifyListeners();
  }

  /// Enters editing mode.
  void startEditing() {
    _isEditing = true;
    notifyListeners();
  }

  /// Exits editing mode.
  void stopEditing() {
    _isEditing = false;
    notifyListeners();
  }

  // ── Mutation Operations ───────────────────────────────────────────

  /// Updates a caption at the given index.
  void updateCaption(int index, CaptionModel updated) {
    if (index < 0 || index >= _captions.length) return;
    _pushUndo();
    _captions[index] = updated;
    notifyListeners();
  }

  /// Updates the text of a caption.
  ///
  /// Also clears the word-level timestamps because they no longer correspond
  /// to the edited text — keeping stale words would break karaoke/typewriter.
  void updateCaptionText(int index, String text) {
    if (index < 0 || index >= _captions.length) return;
    _pushUndo();
    _captions[index] = _captions[index].copyWith(
      text: text,
      words: [], // stale word timestamps invalidated after manual text edit
      isEdited: true,
    );
    notifyListeners();
  }

  /// Deletes a caption at the given index.
  void deleteCaption(int index) {
    if (index < 0 || index >= _captions.length) return;
    _pushUndo();
    _captions.removeAt(index);
    if (_selectedCaptionIndex != null) {
      if (_selectedCaptionIndex == index) {
        _selectedCaptionIndex = null;
      } else if (_selectedCaptionIndex! > index) {
        _selectedCaptionIndex = _selectedCaptionIndex! - 1;
      }
    }
    notifyListeners();
  }

  /// Adds a new caption.
  void addCaption(CaptionModel caption) {
    _pushUndo();
    _captions.add(caption);
    _sortCaptions();
    notifyListeners();
  }

  /// Splits a caption at the given word index.
  void splitCaption(int captionIndex, int wordIndex) {
    if (captionIndex < 0 || captionIndex >= _captions.length) return;

    final caption = _captions[captionIndex];
    if (wordIndex <= 0 || wordIndex >= caption.words.length) return;

    _pushUndo();

    final firstWords = caption.words.sublist(0, wordIndex);
    final secondWords = caption.words.sublist(wordIndex);

    final firstText = firstWords.map((w) => w.word).join(' ');
    final secondText = secondWords.map((w) => w.word).join(' ');

    final firstCaption = caption.copyWith(
      text: firstText,
      words: firstWords,
      endTime: Duration(milliseconds: (firstWords.last.end * 1000).round()),
      isEdited: true,
    );

    final secondCaption = CaptionModel(
      id: const Uuid().v4(),
      text: secondText,
      words: secondWords,
      startTime: Duration(
        milliseconds: (secondWords.first.start * 1000).round(),
      ),
      endTime: caption.endTime,
      style: caption.style,
      isEdited: true,
    );

    _captions[captionIndex] = firstCaption;
    _captions.insert(captionIndex + 1, secondCaption);
    notifyListeners();
  }

  /// Merges a caption with the next one.
  void mergeWithNext(int index) {
    if (index < 0 || index >= _captions.length - 1) return;

    _pushUndo();

    final current = _captions[index];
    final next = _captions[index + 1];

    final mergedWords = [...current.words, ...next.words];
    final mergedText = '${current.text} ${next.text}';

    _captions[index] = current.copyWith(
      text: mergedText,
      words: mergedWords,
      endTime: next.endTime,
      isEdited: true,
    );

    _captions.removeAt(index + 1);
    notifyListeners();
  }

  /// Updates the timing of a caption.
  void updateTimestamps(int index, Duration start, Duration end) {
    if (index < 0 || index >= _captions.length) return;
    _pushUndo();
    _captions[index] = _captions[index].copyWith(
      startTime: start,
      endTime: end,
      isEdited: true,
    );
    notifyListeners();
  }

  /// Sorts captions by start time.
  void reorderCaptions() {
    _sortCaptions();
    notifyListeners();
  }

  void _sortCaptions() {
    _captions.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // ── Undo / Redo ───────────────────────────────────────────────────

  void _pushUndo() {
    _undoStack.add(List.from(_captions.map((c) => c.copyWith())));
    _redoStack.clear();
    // Limit undo stack size
    if (_undoStack.length > AppDimensions.maxUndoSteps) {
      _undoStack.removeAt(0);
    }
  }

  /// Undoes the last operation.
  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List.from(_captions.map((c) => c.copyWith())));
    _captions = _undoStack.removeLast();
    notifyListeners();
  }

  /// Redoes the last undone operation.
  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(List.from(_captions.map((c) => c.copyWith())));
    _captions = _redoStack.removeLast();
    notifyListeners();
  }

  /// Applies a style to all captions.
  void applyStyleToAll(captionStyle) {
    _pushUndo();
    _captions = _captions.map((c) => c.copyWith(style: captionStyle)).toList();
    notifyListeners();
  }
}
