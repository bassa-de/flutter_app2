import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
    // サンプルイベントを追加
    _events = {
      DateTime.now(): [
        Event('Event 1', Colors.red),
        Event('Event 2', Colors.blue),
      ],
      DateTime.now().add(Duration(days: 1)): [
        Event('Event 3', Colors.green),
      ],
    };
  }

  void _showBudgetDialog(DateTime selectedDay) {
    final TextEditingController _budgetController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Budget for ${selectedDay.toLocal()}'),
          content: TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter amount',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('SAVE'),
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

  void _addEventDialog(DateTime selectedDay) {
    final TextEditingController _eventController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Event for ${selectedDay.toLocal()}'),
          content: TextField(
            controller: _eventController,
            decoration: InputDecoration(
              hintText: 'Enter event',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('ADD'),
              onPressed: () {
                setState(() {
                  if (_events[selectedDay] != null) {
                    _events[selectedDay]!
                        .add(Event(_eventController.text, Colors.purple));
                  } else {
                    _events[selectedDay] = [
                      Event(_eventController.text, Colors.purple)
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

  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Table Calendar')),
      body: TableCalendar(
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
          _addEventDialog(selectedDay);
          _showBudgetDialog(selectedDay);
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return Column(
              children: [
                Text(
                  day.day.toString(),
                  style: TextStyle(color: Colors.black),
                ),
                if (_budget[day] != null)
                  Text(
                    '\$${_budget[day]!.toStringAsFixed(2)}',
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
    );
  }
}

class Event {
  final String title;
  final Color color;

  Event(this.title, this.color);
}
