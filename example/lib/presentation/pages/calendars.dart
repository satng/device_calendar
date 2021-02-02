import 'dart:convert';

import 'package:device_calendar/device_calendar.dart';
import 'package:device_calendar_example/presentation/pages/calendar_add.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'calendar_events.dart';

class CalendarsPage extends StatefulWidget {
  CalendarsPage({Key key}) : super(key: key);

  @override
  _CalendarsPageState createState() {
    return _CalendarsPageState();
  }
}

class _CalendarsPageState extends State<CalendarsPage> {
  DeviceCalendarPlugin _deviceCalendarPlugin;
  List<Calendar> _calendars;

  List<Calendar> get _writableCalendars => _calendars?.where((c) => !c.isReadOnly)?.toList() ?? <Calendar>[];

  List<Calendar> get _readOnlyCalendars => _calendars?.where((c) => c.isReadOnly)?.toList() ?? <Calendar>[];

  _CalendarsPageState() {
    _deviceCalendarPlugin = DeviceCalendarPlugin();
  }

  @override
  void initState() {
    super.initState();
    _retrieveCalendars();
    // var event = Event.fromJson({
    //   "calendarId": "7917ACDB-5DD5-44BA-A9D6-EEF745535926",
    //   "title": "New重复123",
    //   "start": 1612170000000,
    //   "end": 1612173600000,
    //   "startTimeZone": "Asia/Shanghai",
    //   "allDay": false,
    //   "location": "",
    //   "availability": "BUSY",
    //   //"attendees": [],
    //   "recurrenceRule": {"interval": 1, "endDate": 1612778400000, "recurrenceFrequency": 0},
    //   // "reminders": []
    // });
    // _deviceCalendarPlugin.createOrUpdateEvent(event, 0).then((value) => print(value.data));

//1FB220D2-4F8B-4314-9E19-1EC7407BCA3A:2E410D22-67A0-4B9F-8FC9-F8328473A248

    // var event = Event.fromJson({
    //   "calendarId": "7917ACDB-5DD5-44BA-A9D6-EEF745535926",
    //   //"eventId": "1FB220D2-4F8B-4314-9E19-1EC7407BCA3A:96AE854D-B3A9-4B83-B415-062754D38B2C/RID=634035600",
    //   "eventId": "1FB220D2-4F8B-4314-9E19-1EC7407BCA3A:2E410D22-67A0-4B9F-8FC9-F8328473A248",
    //   "title": "重复123-修改111111222",
    //   "start": 1612177200000,
    //   "end": 1612260000000,
    //   "startTimeZone": "Asia/Shanghai",
    //   "allDay": false,
    //   "availability": "BUSY",
    // });
    // _deviceCalendarPlugin.createOrUpdateEvent(event, 0).then((value) {
    //   print(value.data);
    //
    //   if (value.hasErrors) {
    //     print(value.errors.length);
    //     print(value.errors[0].errorMessage);
    //     print(value.errors[1].errorMessage);
    //   }
    //
    //   final startDate = DateTime.now().add(Duration(days: -30));
    //   final endDate = DateTime.now().add(Duration(days: 30));
    //   _deviceCalendarPlugin.retrieveEvents("7917ACDB-5DD5-44BA-A9D6-EEF745535926", RetrieveEventsParams(startDate: startDate, endDate: endDate)).then((value) {
    //     print(jsonEncode(value.data));
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendars'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              'WARNING: some aspects of saving events are hardcoded in this example app. As such we recommend you do not modify existing events as this may result in loss of information',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: _calendars?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  key: Key(_calendars[index].isReadOnly ? 'readOnlyCalendar${_readOnlyCalendars.indexWhere((c) => c.id == _calendars[index].id)}' : 'writableCalendar${_writableCalendars.indexWhere((c) => c.id == _calendars[index].id)}'),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
                      return CalendarEventsPage(_calendars[index], key: Key('calendarEventsPage'));
                    }));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            _calendars[index].name,
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                        Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Color(_calendars[index].color)),
                        ),
                        SizedBox(width: 10),
                        Container(
                          margin: const EdgeInsets.fromLTRB(0, 0, 5.0, 0),
                          padding: const EdgeInsets.all(3.0),
                          decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent)),
                          child: Text('Default'),
                        ),
                        Icon(_calendars[index].isReadOnly ? Icons.lock : Icons.lock_open)
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final createCalendar = await Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
            return CalendarAddPage();
          }));

          if (createCalendar == true) {
            _retrieveCalendars();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _retrieveCalendars() async {
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data) {
          return;
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      setState(() {
        _calendars = calendarsResult?.data;
      });

      print(jsonEncode(_calendars));
    } on PlatformException catch (e) {
      print(e);
    }
  }
}
