// lib/screens/owner/live_dashboard_screen.dart
class LiveDashboardScreen extends StatefulWidget {
  final String carWashId;

  @override
  _LiveDashboardScreenState createState() => _LiveDashboardScreenState();
}

class _LiveDashboardScreenState extends State<LiveDashboardScreen> {
  late WebSocketService _wsService;
  late Stream<Map<String, dynamic>> _availabilityStream;

  Map<String, dynamic> _currentStats = {
    'totalToday': 0,
    'completedToday': 0,
    'inProgress': 0,
    'upcoming': 0,
    'walkIns': 0,
    'appBookings': 0,
  };

  @override
  void initState() {
    super.initState();
    _wsService = WebSocketService();
    _wsService.connect(widget.carWashId);
    _availabilityStream = _wsService.availabilityStream;
    _loadTodayStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المراقبة المباشرة'),
        actions: [
          StreamBuilder<Map<String, dynamic>>(
            stream: _availabilityStream,
            builder: (context, snapshot) {
              return Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: snapshot.hasData ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      snapshot.hasData ? 'متصل' : 'غير متصل',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTodayStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // الإحصائيات الحية
              _buildLiveStatsGrid(),
              const SizedBox(height: 20),

              // الجدول الزمني الحي
              _buildLiveTimeline(),
              const SizedBox(height: 20),

              // آخر الأنشطة
              _buildRecentActivities(),
              const SizedBox(height: 20),

              // رسم بياني للنشاط خلال اليوم
              _buildHourlyActivityChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          'الحجوزات اليوم',
          '${_currentStats['totalToday']}',
          Icons.today,
          Colors.blue,
          subtitle:
              'التطبيق: ${_currentStats['appBookings']} | مباشر: ${_currentStats['walkIns']}',
        ),
        _buildStatCard(
          'قيد التنفيذ',
          '${_currentStats['inProgress']}',
          Icons.timelapse,
          Colors.orange,
          isLive: true,
        ),
        _buildStatCard(
          'مكتملة',
          '${_currentStats['completedToday']}',
          Icons.done_all,
          Colors.green,
        ),
        _buildStatCard(
          'قادمة',
          '${_currentStats['upcoming']}',
          Icons.schedule,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildLiveTimeline() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _availabilityStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final slots = snapshot.data!['slots'] as List;
        final currentTime = TimeOfDay.now();

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.timeline, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'الجدول الزمني اليوم',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      TimeOfDay.now().format(context),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    final time = TimeOfDay(
                      hour: int.parse(slot['time'].split(':')[0]),
                      minute: int.parse(slot['time'].split(':')[1]),
                    );
                    final isPast = _isTimePast(time, currentTime);
                    final isCurrent = _isCurrentTime(time, currentTime);

                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8, bottom: 16),
                      child: Column(
                        children: [
                          Text(
                            slot['time'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isCurrent ? FontWeight.bold : null,
                              color: isPast ? Colors.grey : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getSlotStatusColor(
                                  slot['booked_count'],
                                  slot['capacity'],
                                  isPast,
                                  isCurrent,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: isCurrent
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${slot['booked_count']}/${slot['capacity']}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isPast ? 11 : 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
    bool isLive = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            isLive ? Border.all(color: color.withOpacity(0.5), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  bool _isTimePast(TimeOfDay time, TimeOfDay current) {
    return time.hour < current.hour ||
        (time.hour == current.hour && time.minute < current.minute);
  }

  bool _isCurrentTime(TimeOfDay time, TimeOfDay current) {
    return time.hour == current.hour &&
        (time.minute <= current.minute && current.minute < time.minute + 30);
  }

  Color _getSlotStatusColor(
    int booked,
    int capacity,
    bool isPast,
    bool isCurrent,
  ) {
    if (isPast) return Colors.grey;
    if (isCurrent) return Colors.blue;

    final percentage = booked / capacity;
    if (percentage >= 1.0) return Colors.red;
    if (percentage >= 0.8) return Colors.orange;
    if (percentage >= 0.5) return Colors.yellow[700]!;
    return Colors.green;
  }
}
