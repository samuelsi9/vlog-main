import 'package:flutter/material.dart';

// Color scheme
const Color primaryColor = Color(0xFFE53E3E);
const Color primaryColorLight = Color(0xFFFC8181);
const Color uberBlack = Color(0xFF000000);

class DeliverySchedulePage extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialTimeSlot;

  const DeliverySchedulePage({
    super.key,
    this.initialDate,
    this.initialTimeSlot,
  });

  @override
  State<DeliverySchedulePage> createState() => _DeliverySchedulePageState();
}

class _DeliverySchedulePageState extends State<DeliverySchedulePage> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final List<String> _allTimeSlots = [
    '9:00 AM - 11:00 AM',
    '11:00 AM - 1:00 PM',
    '1:00 PM - 3:00 PM',
    '3:00 PM - 5:00 PM',
    '5:00 PM - 7:00 PM',
    '7:00 PM - 9:00 PM',
  ];

  // Get available time slots based on selected date and current time
  List<String> get _availableTimeSlots {
    if (_selectedDate == null) return _allTimeSlots;
    
    final now = DateTime.now();
    final isToday = _isToday(_selectedDate!);
    
    // If selected date is in the future, show all time slots
    if (!isToday) {
      return _allTimeSlots;
    }
    
    // If today, filter out past time slots
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    return _allTimeSlots.where((slot) {
      // Extract start hour from time slot (e.g., "9:00 AM" from "9:00 AM - 11:00 AM")
      final startTimeStr = slot.split(' - ')[0];
      final slotHour = _parseTimeTo24Hour(startTimeStr);
      
      // If slot hour is greater than current hour, it's available
      if (slotHour > currentHour) {
        return true;
      }
      
      // If slot hour equals current hour, check minutes
      if (slotHour == currentHour) {
        // Extract minutes from time string (default to 0 if not specified)
        final minutesMatch = RegExp(r':(\d+)').firstMatch(startTimeStr);
        final slotMinutes = minutesMatch != null ? int.parse(minutesMatch.group(1)!) : 0;
        
        // Only show if slot minutes are in the future
        return slotMinutes > currentMinute;
      }
      
      return false;
    }).toList();
  }

  // Convert time string (e.g., "9:00 AM") to 24-hour format hour
  int _parseTimeTo24Hour(String timeStr) {
    final isPM = timeStr.contains('PM');
    final timeMatch = RegExp(r'(\d+):(\d+)').firstMatch(timeStr);
    
    if (timeMatch == null) return 0;
    
    int hour = int.parse(timeMatch.group(1)!);
    
    // Convert to 24-hour format
    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }
    
    return hour;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedTimeSlot = widget.initialTimeSlot;
    
    // If initial time slot is not available (past time), clear it
    if (_selectedTimeSlot != null && _selectedDate != null) {
      final availableSlots = _getAvailableTimeSlotsForDate(_selectedDate!);
      if (!availableSlots.contains(_selectedTimeSlot)) {
        _selectedTimeSlot = null;
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Clear selected time slot if it becomes unavailable for the new date
        if (_selectedTimeSlot != null) {
          final availableSlots = _getAvailableTimeSlotsForDate(picked);
          if (!availableSlots.contains(_selectedTimeSlot)) {
            _selectedTimeSlot = null;
          }
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final day = date.day;
    return '$weekday, $month $day';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Get available time slots for a specific date
  List<String> _getAvailableTimeSlotsForDate(DateTime date) {
    final now = DateTime.now();
    final isToday = _isToday(date);
    
    // If selected date is in the future, show all time slots
    if (!isToday) {
      return _allTimeSlots;
    }
    
    // If today, filter out past time slots
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    return _allTimeSlots.where((slot) {
      // Extract start hour from time slot
      final startTimeStr = slot.split(' - ')[0];
      final slotHour = _parseTimeTo24Hour(startTimeStr);
      
      // If slot hour is greater than current hour, it's available
      if (slotHour > currentHour) {
        return true;
      }
      
      // If slot hour equals current hour, check minutes
      if (slotHour == currentHour) {
        final minutesMatch = RegExp(r':(\d+)').firstMatch(startTimeStr);
        final slotMinutes = minutesMatch != null ? int.parse(minutesMatch.group(1)!) : 0;
        return slotMinutes > currentMinute;
      }
      
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: uberBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Delivery Schedule",
          style: TextStyle(
            color: uberBlack,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              "Choose your delivery date and time",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: uberBlack,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Select when you'd like to receive your order",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 32),

            // Date Selection Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: primaryColor, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        "Select Date",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Quick date options
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final date = DateTime.now().add(Duration(days: index));
                        final isSelected = _selectedDate != null &&
                            _selectedDate!.year == date.year &&
                            _selectedDate!.month == date.month &&
                            _selectedDate!.day == date.day;
                        final isToday = _isToday(date);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                              // Clear selected time slot if it becomes unavailable
                              if (_selectedTimeSlot != null) {
                                final availableSlots = _getAvailableTimeSlotsForDate(date);
                                if (!availableSlots.contains(_selectedTimeSlot)) {
                                  _selectedTimeSlot = null;
                                }
                              }
                            });
                          },
                          child: Container(
                            width: 80,
                            margin: EdgeInsets.only(
                              right: index < 6 ? 12 : 0,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor
                                  : (isToday ? Colors.amber[50] : Colors.grey[50]),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : (isToday ? Colors.amber[200]! : Colors.grey[300]!),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _formatDate(date).split(',')[0],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(date).split(',')[1].trim(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                                if (isToday)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.3)
                                            : Colors.amber[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "Today",
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.amber[900],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Custom date picker button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_month),
                      label: const Text("Choose another date"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Time Slot Selection Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: primaryColor, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        "Select Time Slot",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Show message if no time slots available for today
                  if (_isToday(_selectedDate ?? DateTime.now()) && _availableTimeSlots.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "No more delivery slots available for today. Please select tomorrow or later.",
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ..._availableTimeSlots.map((slot) {
                    final isSelected = _selectedTimeSlot == slot;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTimeSlot = slot;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withOpacity(0.1)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.schedule,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  slot,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: primaryColor,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColorLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedDate != null && _selectedTimeSlot != null) {
                        // Double check that selected time slot is still available
                        final availableSlots = _getAvailableTimeSlotsForDate(_selectedDate!);
                        if (!availableSlots.contains(_selectedTimeSlot)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Selected time slot is no longer available. Please select another time."),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                        
                        Navigator.pop(context, {
                          'date': _selectedDate,
                          'timeSlot': _selectedTimeSlot,
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_availableTimeSlots.isEmpty && _isToday(_selectedDate ?? DateTime.now())
                                ? "No delivery slots available for today. Please select another date."
                                : "Please select both date and time"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const Center(
                      child: Text(
                        "Confirm Schedule",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



