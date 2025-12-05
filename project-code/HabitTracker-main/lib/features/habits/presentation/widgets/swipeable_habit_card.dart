import 'package:flutter/material.dart';
import '../../domain/entities/habit.dart';

class SwipeableHabitCard extends StatefulWidget {
  final Habit habit;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SwipeableHabitCard({
    super.key,
    required this.habit,
    this.onTap,
    this.onComplete,
    this.onSkip,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<SwipeableHabitCard> createState() => _SwipeableHabitCardState();
}

class _SwipeableHabitCardState extends State<SwipeableHabitCard> {
  double _dragExtent = 0;
  static const double _completeThreshold = 80;
  static const double _skipThreshold = -80;

  Color _getColor() {
    try {
      return Color(int.parse('FF${widget.habit.colorHex}', radix: 16));
    } catch (e) {
      return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (widget.habit.isCompleted) return;
        setState(() {
          _dragExtent += details.delta.dx;
          _dragExtent = _dragExtent.clamp(-150.0, 150.0);
        });
      },
      onHorizontalDragEnd: (details) {
        if (widget.habit.isCompleted) return;
        if (_dragExtent >= _completeThreshold) {
          widget.onComplete?.call();
        } else if (_dragExtent <= _skipThreshold) {
          widget.onSkip?.call();
        }
        setState(() {
          _dragExtent = 0;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Stack(
          children: [
            // Background actions
            if (!widget.habit.isCompleted) ...[
              // Complete action (swipe right)
              if (_dragExtent > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: _dragExtent,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: _dragExtent > 40
                        ? const Icon(Icons.check, color: Colors.white, size: 28)
                        : null,
                  ),
                ),

              // Skip action (swipe left)
              if (_dragExtent < 0)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: -_dragExtent,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: _dragExtent < -40
                        ? ClipRect(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
            ],

            // Main card
            Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Emoji icon
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.habit.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Habit name - tappable area
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onTap,
                          child: Text(
                            widget.habit.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      // Action buttons - wrapped to prevent parent tap
                      GestureDetector(
                        onTap: () {}, // Absorb tap, don't propagate
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit button
                            GestureDetector(
                              onTap: () {
                                widget.onEdit?.call();
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.black54,
                                  size: 16,
                                ),
                              ),
                            ),
                            // Delete button
                            GestureDetector(
                              onTap: () {
                                widget.onDelete?.call();
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 16,
                                ),
                              ),
                            ),
                            // Complete button (only show if not completed)
                            if (!widget.habit.isCompleted)
                              GestureDetector(
                                onTap: () {
                                  widget.onComplete?.call();
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6366F1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            // Completion indicator
                            if (widget.habit.isCompleted)
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
