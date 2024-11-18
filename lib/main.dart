import 'package:flutter/material.dart'; // Flutter의 기본 Material 디자인 패키지
import 'package:table_calendar/table_calendar.dart'; // 테이블 캘린더 패키지
import 'package:intl/intl.dart'; // 국제화 패키지
import 'package:flutter_localizations/flutter_localizations.dart'; // 로컬라이제이션 지원 패키지
import 'package:webview_flutter/webview_flutter.dart'; // 웹뷰 패키지

void main() {
  runApp(MyApp());
}

// 앱의 루트 위젯
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Calendar',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: '투두리스트'), // 홈 화면 설정
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('ko', 'KR'), // 한국어 지원
      ],
    );
  }
}

// 홈 페이지 StatefulWidget
class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title; // 페이지 제목

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

// 홈 페이지의 상태 클래스
class _MyHomePageState extends State<MyHomePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month; // 캘린더 형식 (월간 보기)
  DateTime _focusedDay = DateTime.now(); // 포커스된 날짜 (현재 날짜)
  DateTime? _selectedDay; // 선택된 날짜
  Map<DateTime, Map<String, List<Map<String, dynamic>>>> dailyListEvents = {}; // 이벤트 저장 맵

  // 이벤트 추가 함수
  void _addEvent(String category, String eventTitle) {
    if (_selectedDay != null) {
      if (dailyListEvents[_selectedDay!] == null) {
        dailyListEvents[_selectedDay!] = {
          '과제': [],
          '공부': [],
          '기타': [],
        };
      }
      dailyListEvents[_selectedDay!]![category]!.add({
        'title': eventTitle,
        'isDone': false,
      });
      setState(() {});
    }
  }

  // 이벤트 제거 함수
  void _removeEvent(String category, int index) {
    if (_selectedDay != null && dailyListEvents[_selectedDay!] != null) {
      dailyListEvents[_selectedDay!]![category]!.removeAt(index);
      setState(() {});
    }
  }

  // 이벤트 완료 상태 토글 함수
  void _toggleEvent(String category, int index) {
    if (_selectedDay != null && dailyListEvents[_selectedDay!] != null) {
      dailyListEvents[_selectedDay!]![category]![index]['isDone'] = !dailyListEvents[_selectedDay!]![category]![index]['isDone'];
      setState(() {});
    }
  }

  // 완료율 계산 함수
  double _calculateCompletionRate() {
    if (_selectedDay != null && dailyListEvents[_selectedDay!] != null) {
      final allEvents = dailyListEvents[_selectedDay!]!.values.expand((events) => events).toList();
      final total = allEvents.length;
      final done = allEvents.where((event) => event['isDone']).length;
      return total > 0 ? done / total : 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan[100],
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.school),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SecondPage()), // 학사일정 페이지로 이동
                );
              },
            ),
            SizedBox(width: 8.0),
            Text(widget.title),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                '달성률: ${(100 * _calculateCompletionRate()).toStringAsFixed(1)}%', // 완료율 표시
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1), // 첫 번째 날짜
            lastDay: DateTime.utc(2030, 12, 12), // 마지막 날짜
            focusedDay: _focusedDay, // 포커스된 날짜
            calendarFormat: _calendarFormat, // 캘린더 형식
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day); // 선택된 날짜와 동일한지 확인
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay; // 포커스된 날짜 업데이트
                if (dailyListEvents[_selectedDay!] == null) {
                  dailyListEvents[_selectedDay!] = {
                    '과제': [],
                    '공부': [],
                    '기타': [],
                  };
                }
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format; // 캘린더 형식 변경
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay; // 포커스된 날짜 변경
            },
            locale: 'ko_KR',
            headerStyle: HeaderStyle(
              titleTextFormatter: (date, locale) => DateFormat('yyyy년 M월', locale).format(date), // 헤더 날짜 형식
            ),
            eventLoader: (day) => dailyListEvents[day]?.values.expand((events) => events.map((event) => event['title'])).toList() ?? [], // 이벤트 로더
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _selectedDay == null
                ? Center(child: Text('날짜를 선택하세요')) // 날짜가 선택되지 않은 경우
                : Column(
              children: ['과제', '공부', '기타'].map((category) {
                return Expanded(
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventListPage(
                              selectedDay: _selectedDay!,
                              category: category,
                              events: dailyListEvents[_selectedDay!]![category]!,
                              addEvent: (title) => _addEvent(category, title),
                              toggleEvent: (index) => _toggleEvent(category, index),
                              removeEvent: (index) => _removeEvent(category, index),
                            ),
                          ),
                        ),
                        child: Text(category, style: TextStyle(color: Colors.black)), // 카테고리 텍스트
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue[100],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: dailyListEvents[_selectedDay!]![category]!.length, // 이벤트 개수
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(dailyListEvents[_selectedDay!]![category]![index]['title']), // 이벤트 제목
                              leading: Checkbox(
                                value: dailyListEvents[_selectedDay!]![category]![index]['isDone'], // 완료 여부
                                onChanged: (value) => _toggleEvent(category, index), // 완료 상태 토글
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _removeEvent(category, index), // 이벤트 제거
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// 이벤트 리스트 페이지
class EventListPage extends StatelessWidget {
  final DateTime selectedDay; // 선택된 날짜
  final String category; // 이벤트의 카테고리
  final List<Map<String, dynamic>> events; // 선택된 날짜의 이벤트 리스트
  final Function(String) addEvent; // 이벤트 추가 함수
  final Function(int) toggleEvent; // 이벤트 완료 상태 토글 함수
  final Function(int) removeEvent; // 이벤트 제거 함수

  EventListPage({
    required this.selectedDay,
    required this.category,
    required this.events,
    required this.addEvent,
    required this.toggleEvent,
    required this.removeEvent,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController _eventController = TextEditingController(); // 이벤트 입력 컨트롤러
    return Scaffold(
      appBar: AppBar(
        title: Text('$category - ${DateFormat('yyyy년 M월 d일').format(selectedDay)}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: events.length, // 이벤트 개수
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(events[index]['title']), // 이벤트 제목
                  leading: Checkbox(
                    value: events[index]['isDone'], // 완료 여부
                    onChanged: (value) => toggleEvent(index), // 완료 상태 토글
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => removeEvent(index), // 이벤트 제거
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _eventController, // 이벤트 입력 컨트롤러
              decoration: InputDecoration(
                labelText: '할 일 추가', // 입력 필드 레이블
                suffixIcon: IconButton(
                  icon: Icon(Icons.add), // 추가 아이콘
                  onPressed: () {
                    if (_eventController.text.isNotEmpty) {
                      addEvent(_eventController.text); // 이벤트 추가
                      _eventController.clear(); // 입력 필드 초기화
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 학사일정 페이지
class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('학사일정'),
      ),
      body: WebView(
        initialUrl: 'http://www.hoseo.ac.kr/Home/Contents.mbz?action=MAPP_2405312496',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
