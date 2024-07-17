import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'カレンダーアプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: CalendarScreen(),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, double> _budget = {};
  Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _events = {
      DateTime.now(): [
        Event('イベント1', Colors.red, TimeOfDay(hour: 10, minute: 0)),
        Event('イベント2', Colors.blue, TimeOfDay(hour: 12, minute: 0)),
      ],
      DateTime.now().add(Duration(days: 1)): [
        Event('イベント3', Colors.green, TimeOfDay(hour: 14, minute: 0)),
      ],
    };
  }

  void _showEventDialog(DateTime selectedDay) {
    final TextEditingController _eventController = TextEditingController();
    TimeOfDay _selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${DateFormat.yMMMd('ja').format(selectedDay)}のイベントを追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _eventController,
                decoration: InputDecoration(
                  hintText: 'イベントを入力',
                ),
              ),
              SizedBox(height: 8.0),
              TextButton(
                child: Text('時間を選択'),
                onPressed: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _selectedTime = pickedTime;
                    });
                  }
                },
              ),
              Text('選択した時間: ${_selectedTime.format(context)}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('追加'),
              onPressed: () {
                setState(() {
                  if (_events[selectedDay] != null) {
                    _events[selectedDay]!.add(Event(
                        _eventController.text, Colors.purple, _selectedTime));
                  } else {
                    _events[selectedDay] = [
                      Event(_eventController.text, Colors.purple, _selectedTime)
                    ];
                  }
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showBudgetDialog(DateTime selectedDay) {
    final TextEditingController _budgetController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${DateFormat.yMMMd('ja').format(selectedDay)}の予算を入力'),
          content: TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '金額を入力',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('保存'),
              onPressed: () {
                setState(() {
                  _budget[selectedDay] =
                      double.tryParse(_budgetController.text) ?? 0.0;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showOptionsDialog(DateTime selectedDay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${DateFormat.yMMMd('ja').format(selectedDay)}のアクションを選択'),
          actions: <Widget>[
            TextButton(
              child: Text('イベントを追加'),
              onPressed: () {
                Navigator.of(context).pop();
                _showEventDialog(selectedDay);
              },
            ),
            TextButton(
              child: Text('予算を入力'),
              onPressed: () {
                Navigator.of(context).pop();
                _showBudgetDialog(selectedDay);
              },
            ),
          ],
        );
      },
    );
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('カレンダー')),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ja_JP',
            firstDay: DateTime.utc(1900, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showOptionsDialog(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final text = DateFormat.E('ja').format(day);
                return Center(
                  child: Text(
                    text,
                    style: TextStyle(color: Colors.blue),
                  ),
                );
              },
              defaultBuilder: (context, day, focusedDay) {
                return Column(
                  children: [
                    Text(
                      day.day.toString(),
                      style: TextStyle(color: Colors.black),
                    ),
                    if (_budget[day] != null)
                      Text(
                        '¥${_budget[day]!.toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.green),
                      ),
                  ],
                );
              },
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events.map((event) {
                      if (event is Event) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: event.color,
                          ),
                        );
                      }
                      return Container();
                    }).toList(),
                  );
                }
                return SizedBox();
              },
            ),
            eventLoader: _getEventsForDay,
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay);

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return ListTile(
          title: Text(event.title),
          subtitle: Text('時間: ${event.time.format(context)}'),
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: event.color,
            ),
          ),
        );
      },
    );
  }
}

class Event {
  final String title;
  final Color color;
  final TimeOfDay time;

  Event(this.title, this.color, this.time);
}//7.17
