import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/project.dart';

class BatchConfigResult {
  final int startIndex;
  final int count;
  BatchConfigResult(this.startIndex, this.count);
}

class BatchConfigDialog extends StatefulWidget {
  final Project project;

  const BatchConfigDialog({super.key, required this.project});

  @override
  State<BatchConfigDialog> createState() => _BatchConfigDialogState();
}

class _BatchConfigDialogState extends State<BatchConfigDialog> {
  int _startIndex = 0;
  final TextEditingController _countController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Default to the first pending chapter
    _startIndex = widget.project.chapters.indexWhere((c) => c.status != ChapterStatus.done);
    if (_startIndex == -1) _startIndex = 0;

    // Default count to remaining chapters
    int initialCount = widget.project.chapters.length - _startIndex;
    if (initialCount < 1) initialCount = 1;
    _countController.text = initialCount.toString();
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int maxCount = widget.project.chapters.length - _startIndex;
    if (maxCount < 1) maxCount = 1;

    int currentCount = int.tryParse(_countController.text) ?? 0;
    int estimatedTokens = currentCount * 2000;
    int estimatedSeconds = currentCount * 15;
    Duration estimatedTime = Duration(seconds: estimatedSeconds);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.batch_prediction,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'BATCH TRANSLATION',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Start Chapter',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _startIndex,
                    items: List.generate(widget.project.chapters.length, (
                      index,
                    ) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text(
                          '${index + 1}. ${widget.project.chapters[index].title}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _startIndex = val;
                          // Update max count if start index changes
                          int newMax =
                              widget.project.chapters.length - _startIndex;
                          if (newMax < 1) newMax = 1;
                          int currentInput =
                              int.tryParse(_countController.text) ?? 1;
                          if (currentInput > newMax) {
                            _countController.text = newMax.toString();
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chapters to Translate',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _countController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixText: 'Max: $maxCount',
                ),
                onChanged: (_) {
                  setState(() {}); // trigger rebuild to update estimates
                },
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter a number';
                  int? num = int.tryParse(val);
                  if (num == null || num < 1) return 'Must be at least 1';
                  if (num > maxCount)
                    return 'Cannot exceed max chapters ($maxCount)';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Tokens:',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        Text(
                          '~${estimatedTokens.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Time:',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        Text(
                          '~${estimatedTime.inMinutes}m ${estimatedTime.inSeconds % 60}s',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Note: Translations are throttled to 4 RPM (15s per chapter) to avoid rate limits.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      foregroundColor: Colors.grey.shade700,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        int finalCount = int.parse(_countController.text);
                        Navigator.of(context)
                            .pop(BatchConfigResult(_startIndex, finalCount));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Start Translation'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
