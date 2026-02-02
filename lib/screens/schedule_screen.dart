import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/app_user.dart';
import '../services/schedule_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/mechanic_design.dart';

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
    // Determine shopId
    final shopId = widget.appUser.serviceCenterId;
    if (shopId == null) {
      return const Center(child: Text('소속된 정비소가 없습니다.'));
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Consistent with WrenchBackground
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _schedulesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: MechanicColor.primary500),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }

          final schedules = snapshot.data ?? [];

          // Process Events
          _events = {};
          for (var schedule in schedules) {
            final date = schedule['date'] as DateTime;
            final normalizedDate = DateTime(date.year, date.month, date.day);

            int duration = 1;
            final durationVal = schedule['duration'];
            if (durationVal is int) {
              duration = durationVal;
            } else if (durationVal is String) {
              final match = RegExp(r'\d+').firstMatch(durationVal);
              if (match != null) duration = int.parse(match.group(0)!);
            }

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
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Calendar Card (Highly Rounded)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32), // Highly rounded
                    boxShadow: [
                      BoxShadow(
                        color: MechanicColor.primary600.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: TableCalendar(
                    rowHeight: 52,
                    daysOfWeekHeight: 44,
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
                      titleTextStyle: MechanicTypography.subheader.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      leftChevronIcon: const Icon(
                        LucideIcons.chevronLeft,
                        color: Color(0xFFD1D5DB), // lighter grey
                        size: 28,
                      ),
                      rightChevronIcon: const Icon(
                        LucideIcons.chevronRight,
                        color: Color(0xFFD1D5DB),
                        size: 28,
                      ),
                      headerMargin: const EdgeInsets.only(bottom: 24),
                    ),
                    calendarBuilders: CalendarBuilders(
                      selectedBuilder: (context, day, focusedDay) {
                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: MechanicColor.primary500,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: MechanicColor.primary300,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        return Container(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: MechanicColor.primary500,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: MechanicColor.primary400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;

                        final sortedEvents = List<Map<String, dynamic>>.from(
                          events as List<Map<String, dynamic>>,
                        );

                        // Sort by Start Date then ID for consistent ordering
                        sortedEvents.sort((a, b) {
                          final dA = a['date'] as DateTime;
                          final dB = b['date'] as DateTime;
                          int cmp = dA.compareTo(dB);
                          if (cmp != 0) return cmp;
                          return (a['id'] ?? '').toString().compareTo(
                            (b['id'] ?? '').toString(),
                          );
                        });

                        return Container(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 2),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: sortedEvents.take(3).map((eventData) {
                                final startDate = eventData['date'] as DateTime;
                                final normalizedStart = DateTime(
                                  startDate.year,
                                  startDate.month,
                                  startDate.day,
                                );

                                // Determine Duration
                                int duration = 1;
                                final durationVal = eventData['duration'];
                                if (durationVal is int) {
                                  duration = durationVal;
                                } else if (durationVal is String) {
                                  final match = RegExp(
                                    r'\d+',
                                  ).firstMatch(durationVal);
                                  if (match != null) {
                                    duration = int.parse(match.group(0)!);
                                  }
                                }

                                final normalizedEnd = normalizedStart.add(
                                  Duration(days: duration - 1),
                                );
                                final normalizedDay = DateTime(
                                  day.year,
                                  day.month,
                                  day.day,
                                );

                                final isStart = normalizedDay.isAtSameMomentAs(
                                  normalizedStart,
                                );
                                final isEnd = normalizedDay.isAtSameMomentAs(
                                  normalizedEnd,
                                );

                                // Mechanic Color Palette
                                final colors = [
                                  MechanicColor.primary200,
                                  MechanicColor.primary300,
                                  MechanicColor.primary400,
                                  MechanicColor.primary500,
                                ];

                                final colorIndex =
                                    (eventData['id'] ?? '')
                                        .toString()
                                        .hashCode
                                        .abs() %
                                    colors.length;
                                final eventColor = colors[colorIndex];

                                return Container(
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 1,
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        top: 0,
                                        bottom: 0,
                                        left: isStart ? 2.0 : -1.0,
                                        right: isEnd ? 2.0 : -1.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: eventColor,
                                            borderRadius:
                                                BorderRadius.horizontal(
                                                  left: isStart
                                                      ? const Radius.circular(2)
                                                      : Radius.zero,
                                                  right: isEnd
                                                      ? const Radius.circular(2)
                                                      : Radius.zero,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                      defaultBuilder: (context, day, focusedDay) {
                        return Container(
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
                    calendarStyle: const CalendarStyle(
                      outsideDaysVisible: false,
                      markersMaxCount: 0,
                      cellMargin: EdgeInsets.zero,
                      cellPadding: EdgeInsets.zero,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Selected Date Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('상세 일정', style: MechanicTypography.subheader),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: MechanicColor.primary100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${selectedEvents.length}건',
                        style: const TextStyle(
                          color: MechanicColor.primary700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Event List
                Expanded(
                  child: selectedEvents.isEmpty
                      ? _buildEmptyEventsState()
                      : ListView.builder(
                          itemCount: selectedEvents.length,
                          itemBuilder: (context, index) {
                            final event = selectedEvents[index];
                            return _EventCard(event: event);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyEventsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.calendarX,
            size: 48,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '해당 날짜에 잡힌 일정이 없습니다.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return MechanicCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _showEventDetails(context, event),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: MechanicColor.primary100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.wrench,
                color: MechanicColor.primary600,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'] ?? '제목 없음',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.user, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event['customerEmail'] ?? '정보 없음',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Colors.grey),
        ],
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
                      color: MechanicColor.primary100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.fileText,
                      color: MechanicColor.primary600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '일정 상세 내역',
                    style: MechanicTypography.headline.copyWith(fontSize: 20),
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
