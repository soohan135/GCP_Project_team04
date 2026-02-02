import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/app_user.dart';
import '../services/schedule_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ScheduleScreen extends StatefulWidget {
  final AppUser appUser;

  const ScheduleScreen({super.key, required this.appUser});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ScheduleService _scheduleService = ScheduleService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Events grouped by DateTime
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  late Stream<List<Map<String, dynamic>>> _schedulesStream;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Initialize stream once to prevent reloading on setState
    if (widget.appUser.serviceCenterId != null) {
      _schedulesStream = _scheduleService.getSchedules(
        widget.appUser.serviceCenterId!,
      );
    } else {
      _schedulesStream = const Stream.empty();
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shopId = widget.appUser.serviceCenterId;

    if (shopId == null) {
      return const Scaffold(body: Center(child: Text('소속된 정비소가 없습니다.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F0), // Cream background
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _schedulesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }

          final schedules = snapshot.data ?? [];

          _events = {};
          for (var schedule in schedules) {
            final date = schedule['date'] as DateTime;
            final normalizedDate = DateTime(date.year, date.month, date.day);

            // Determine duration (default 1 day)
            int duration = 1;
            final durationVal = schedule['duration'];
            if (durationVal is int) {
              duration = durationVal;
            } else if (durationVal is String) {
              // Fallback if saved as string
              final match = RegExp(r'\d+').firstMatch(durationVal);
              if (match != null) duration = int.parse(match.group(0)!);
            }

            // Add event to all dates in range
            for (int i = 0; i < duration; i++) {
              final eventDate = normalizedDate.add(Duration(days: i));

              if (_events[eventDate] == null) {
                _events[eventDate] = [];
              }
              _events[eventDate]!.add(schedule);
            }
          }

          final selectedEvents = _getEventsForDay(
            _selectedDay ?? DateTime.now(),
          );

          return Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              16,
              24,
              0,
            ), // Decreased top padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header for Schedule Section (Compact)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8), // Reduced padding
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.calendar,
                        color: Color(0xFFFF6F00),
                        size: 20, // Reduced icon size
                      ),
                    ),
                    const SizedBox(width: 12), // Reduced horizontal space
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '일정 관리',
                          style: theme.textTheme.titleMedium?.copyWith(
                            // Reduced text style
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          '수리 일정을 확인하고 관리하세요.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            // Smaller body text
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Reduced vertical spacing
                // Calendar Card (Fixed)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: TableCalendar(
                    rowHeight: 64, // Reduced height as requested
                    daysOfWeekHeight: 40,
                    locale: 'ko_KR',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    eventLoader: _getEventsForDay,
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Color(0xFF1F2937),
                      ),
                      leftChevronIcon: const Icon(
                        Icons.chevron_left,
                        color: Color(0xFF9CA3AF),
                        size: 28,
                      ),
                      rightChevronIcon: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF9CA3AF),
                        size: 28,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        return Container(
                          margin: const EdgeInsets.only(top: 8),
                          alignment: Alignment.topCenter,
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        return Container(
                          margin: const EdgeInsets.only(top: 8),
                          alignment: Alignment.topCenter,
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Color(0xFFFF6F00),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                      selectedBuilder: (context, day, focusedDay) {
                        return Container(
                          margin: const EdgeInsets.only(top: 2),
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6F00),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;

                        final sortedEvents = List<Map<String, dynamic>>.from(
                          events as List<Map<String, dynamic>>,
                        );
                        sortedEvents.sort(
                          (a, b) => (a['id'] ?? '').compareTo(b['id'] ?? ''),
                        );

                        return Positioned(
                          bottom: 4,
                          left: 0,
                          right: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: sortedEvents.take(3).map((eventData) {
                              final startDate = eventData['date'] as DateTime;
                              final normalizedStart = DateTime(
                                startDate.year,
                                startDate.month,
                                startDate.day,
                              );

                              int duration = 1;
                              final durationVal = eventData['duration'];
                              if (durationVal is int) {
                                duration = durationVal;
                              } else if (durationVal is String) {
                                final match = RegExp(
                                  r'\d+',
                                ).firstMatch(durationVal);
                                if (match != null)
                                  duration = int.parse(match.group(0)!);
                              }

                              final normalizedDay = DateTime(
                                day.year,
                                day.month,
                                day.day,
                              );
                              final normalizedEnd = normalizedStart.add(
                                Duration(days: duration - 1),
                              );

                              bool isStart = isSameDay(
                                normalizedDay,
                                normalizedStart,
                              );
                              bool isEnd = isSameDay(
                                normalizedDay,
                                normalizedEnd,
                              );
                              // Orange/Amber Shades for Bars
                              final colors = [
                                const Color(0xFFFFE0B2), // Orange 100
                                const Color(0xFFFFCC80), // Orange 200
                                const Color(0xFFFFD180), // Orange Accent 100
                                const Color(0xFFFFECB3), // Amber 100
                                const Color(0xFFFFE082), // Amber 200
                              ];
                              final colorIndex =
                                  (eventData['id'] ?? '').hashCode.abs() %
                                  colors.length;
                              final eventColor = colors[colorIndex];

                              return Container(
                                height:
                                    10, // Thinner bars to fit reduced height
                                margin: const EdgeInsets.symmetric(vertical: 1),
                                child: Container(
                                  margin: EdgeInsets.only(
                                    left: isStart ? 2 : 0,
                                    right: isEnd ? 2 : 0,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: eventColor,
                                    borderRadius: BorderRadius.horizontal(
                                      left: isStart
                                          ? const Radius.circular(2)
                                          : Radius.zero,
                                      right: isEnd
                                          ? const Radius.circular(2)
                                          : Radius.zero,
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft,
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      markersMaxCount: 0,
                      cellMargin: const EdgeInsets.all(0),
                      cellPadding: const EdgeInsets.all(0),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Scrollable Details Section
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '상세 일정',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${selectedEvents.length}건',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (selectedEvents.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.dividerColor.withOpacity(0.5),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.calendarX,
                                  size: 48,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '해당 날짜에 잡힌 일정이 없습니다.',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        else
                          ...selectedEvents
                              .map(
                                (event) => Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFF6F00,
                                      ).withOpacity(0.5), // Orange border
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFF6F00,
                                        ).withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () =>
                                          _showEventDetails(context, event),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFFF6F00,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  LucideIcons.wrench,
                                                  color: Color(0xFFFF6F00),
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    event['title'] ?? '제목 없음',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        LucideIcons.user,
                                                        size: 14,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          event['customerEmail'] ??
                                                              '정보 없음',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontSize: 13,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              LucideIcons.chevronRight,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEventDetails(BuildContext context, Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.fileText,
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '일정 상세 내역',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildDetailItem(LucideIcons.tag, '제목', event['title'] ?? ''),
              _buildDetailItem(
                LucideIcons.mail,
                '고객 이메일',
                event['customerEmail'] ?? '-',
              ),
              _buildDetailItem(
                LucideIcons.alignLeft,
                '설명',
                event['description'] ?? '-',
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
