import 'dart:async';
import 'dart:convert';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

import '../event_item.dart';
import '../recurring_event_dialog.dart';
import 'calendar_event.dart';

class CalendarEventsPage extends StatefulWidget {
  final Calendar _calendar;

  CalendarEventsPage(this._calendar, {Key key}) : super(key: key);

  @override
  _CalendarEventsPageState createState() {
    return _CalendarEventsPageState(_calendar);
  }
}

class _CalendarEventsPageState extends State<CalendarEventsPage> {
  final Calendar _calendar;
  final GlobalKey<ScaffoldState> _scaffoldstate = GlobalKey<ScaffoldState>();

  DeviceCalendarPlugin _deviceCalendarPlugin;
  List<Event> _calendarEvents;
  bool _isLoading = true;

  _CalendarEventsPageState(this._calendar) {
    _deviceCalendarPlugin = DeviceCalendarPlugin();
  }

  @override
  void initState() {
    super.initState();
    _retrieveCalendarEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldstate,
        appBar: AppBar(title: Text('${_calendar.name} events')),
        body: ((_calendarEvents?.isNotEmpty ?? false) || _isLoading)
            ? Stack(
                children: [
                  ListView.builder(
                    itemCount: _calendarEvents?.length ?? 0,
                    itemBuilder: (BuildContext context, int index) {
                      return EventItem(_calendarEvents[index], _deviceCalendarPlugin, _onLoading, _onDeletedFinished, _onTapped, _calendar.isReadOnly);
                    },
                  ),
                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(),
                    )
                ],
              )
            : Center(child: Text('No events found')),
        floatingActionButton: _getAddEventButton(context));
  }

  Widget _getAddEventButton(BuildContext context) {
    if (!_calendar.isReadOnly) {
      return FloatingActionButton(
        key: Key('addEventButton'),
        onPressed: () async {
          final refreshEvents = await Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
            return CalendarEventPage(_calendar);
          }));
          if (refreshEvents == true) {
            await _retrieveCalendarEvents();
          }
        },
        child: Icon(Icons.add),
      );
    } else {
      return null;
    }
  }

  void _onLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  Future _onDeletedFinished(bool deleteSucceeded) async {
    if (deleteSucceeded) {
      await _retrieveCalendarEvents();
    } else {
      _scaffoldstate.currentState.showSnackBar(SnackBar(
        content: Text('Oops, we ran into an issue deleting the event'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future _onTapped(Event event) async {
    final refreshEvents = await Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return CalendarEventPage(
        _calendar,
        event,
        RecurringEventDialog(
          _deviceCalendarPlugin,
          event,
          _onLoading,
          _onDeletedFinished,
        ),
      );
    }));
    if (refreshEvents != null && refreshEvents) {
      await _retrieveCalendarEvents();
    }
  }

  Future _retrieveCalendarEvents() async {
    final startDate = DateTime.now().add(Duration(days: -30));
    final endDate = DateTime.now().add(Duration(days: 30));
    var calendarEventsResult = await _deviceCalendarPlugin.retrieveEvents(_calendar.id, RetrieveEventsParams(startDate: startDate, endDate: endDate, eventIds: ["1FB220D2-4F8B-4314-9E19-1EC7407BCA3A:93B495CB-3FD0-4650-9CA9-8CF8725F3377"]));
    setState(() {
      _calendarEvents = calendarEventsResult?.data;
      _isLoading = false;
    });
    if (_calendar.name == "Miya") {
      var event = Event.fromJson({
        "calendarId": _calendar.id,
        "eventId": "1FB220D2-4F8B-4314-9E19-1EC7407BCA3A:93B495CB-3FD0-4650-9CA9-8CF8725F3377",
        "title": "New重复123-倒数2个",
        "start": 1612688400000,
        "end": 1612692000000,
        "startTimeZone": "Asia/Shanghai",
        "allDay": false,
        "location": "",
        "availability": "BUSY",
        //"attendees": [],
        //"recurrenceRule": {"interval": 1, "endDate": 1612778400000, "recurrenceFrequency": 0},
        // "reminders": []
      });
      await _deviceCalendarPlugin.createOrUpdateEvent(event, 3).then((value) => print(value.data));
    }

    print(jsonEncode(_calendarEvents));
  }
}
