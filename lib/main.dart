import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Model for summary data
class SummaryData {
  final int suhumax;
  final int suhumin;
  final double suhurata;
  final List<Measurement> nilaiSuhuMaxHumidMax;
  final List<MonthYearMax> monthYearMax;

  SummaryData({
    required this.suhumax,
    required this.suhumin,
    required this.suhurata,
    required this.nilaiSuhuMaxHumidMax,
    required this.monthYearMax,
  });

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    var measurementsJson = json['nilai_suhu_max_humid_max'] as List;
    var monthYearJson = json['month_year_max'] as List;

    List<Measurement> measurements = measurementsJson.map((i) => Measurement.fromJson(i)).toList();
    List<MonthYearMax> months = monthYearJson.map((i) => MonthYearMax.fromJson(i)).toList();

    // Periksa tipe data suhurata dan konversi jika perlu
    double parsedSuhurata;
    if (json['suhurata'] is String) {
      parsedSuhurata = double.parse(json['suhurata']);
    } else if (json['suhurata'] is num) {
      parsedSuhurata = json['suhurata'].toDouble();
    } else {
      parsedSuhurata = 0.0; // Default jika tipe data tidak sesuai (hanya untuk keamanan)
    }

    return SummaryData(
      suhumax: json['suhumax'],
      suhumin: json['suhumin'],
      suhurata: parsedSuhurata,
      nilaiSuhuMaxHumidMax: measurements,
      monthYearMax: months,
    );
  }
}

// Model for individual measurements
class Measurement {
  final int idx;
  final int suhu;
  final int humid;
  final int kecerahan;
  final String timestamp;

  Measurement({
    required this.idx,
    required this.suhu,
    required this.humid,
    required this.kecerahan,
    required this.timestamp,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      idx: json['idx'],
      suhu: json['suhu'],
      humid: json['humid'],
      kecerahan: json['kecerahan'],
      timestamp: json['timestamp'],
    );
  }
}

// Model for month-year data
class MonthYearMax {
  final String monthYear;

  MonthYearMax({required this.monthYear});

  factory MonthYearMax.fromJson(Map<String, dynamic> json) {
    return MonthYearMax(
      monthYear: json['month_year'],
    );
  }
}

// Main app
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Temperature Summary',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: SummaryScreen(),
    );
  }
}

class SummaryScreen extends StatefulWidget {
  @override
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late Future<SummaryData> futureSummaryData;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    futureSummaryData = fetchSummaryData();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      setState(() {
        futureSummaryData = fetchSummaryData();
      });
    });
  }

  Future<SummaryData> fetchSummaryData() async {
    final response = await http.get(Uri.parse("http://10.0.2.2:3000/data")); // or use IP address here

    if (response.statusCode == 200) {
      return SummaryData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IoT Temperature Summary'),
      ),
      body: FutureBuilder<SummaryData>(
        future: futureSummaryData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No data found.'));
          } else {
            final data = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Temperature summary
                    Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text('Ringkasan Suhu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text('Suhu Max\n${data.suhumax}°C', style: TextStyle(color: Colors.red, fontSize: 16)),
                              Text('Suhu Min\n${data.suhumin}°C', style: TextStyle(color: Colors.blue, fontSize: 16)),
                              Text('Suhu Rata\n${data.suhurata}°C', style: TextStyle(color: Colors.green, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Measurement details
                    Column(
                      children: data.nilaiSuhuMaxHumidMax.map((measurement) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${measurement.idx}'),
                              Text(measurement.timestamp),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.thermostat, color: Colors.red),
                                      Text('Suhu\n${measurement.suhu}°C', textAlign: TextAlign.center),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.water_drop, color: Colors.blue),
                                      Text('Kelembaban\n${measurement.humid}%', textAlign: TextAlign.center),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.wb_sunny, color: Colors.orange),
                                      Text('Kecerahan\n${measurement.kecerahan}', textAlign: TextAlign.center),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    // Month-Year data
                    Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Periode Waktu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),
                          Column(
                            children: data.monthYearMax.map((monthYear) {
                              return ListTile(
                                leading: Icon(Icons.calendar_today),
                                title: Text(monthYear.monthYear),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
