import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart' hide LegendPosition;
import 'package:pie_chart/pie_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final String fontFamily = 'Roboto';
  Map<String, double> spamCallProceedData = {};
  Map<String, double> spamCallBlockedData = {};
  List<_AgeCallData> ageCallData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final firestore = FirebaseFirestore.instance;

    if (userId == null) return;

    try {
      // Spam Call Proceed Percentage
      final spamCallSnapshot = await firestore
          .collection('spam_calls')
          .where('userId', isEqualTo: userId)
          .get();

      final totalSpamCalls = spamCallSnapshot.docs.length;
      final proceedCalls = spamCallSnapshot.docs
          .where((doc) => doc.data()['status'] == 'proceeded')
          .length;

      spamCallProceedData = {
        'Proceeded': proceedCalls.toDouble(),
        'Blocked': (totalSpamCalls - proceedCalls).toDouble(),
      };

      // Blocked Calls
      final blockedCallSnapshot = await firestore
          .collection('blockedContacts')
          .where('userId', isEqualTo: userId)
          .get();

      spamCallBlockedData = {
        '': blockedCallSnapshot.docs.length.toDouble(),
        '': totalSpamCalls.toDouble() - blockedCallSnapshot.docs.length,
      };

      // Age-based Call Data (Simulated for demonstration)
      ageCallData = [
        _AgeCallData('13-20', 10, 5),
        _AgeCallData('21-25', 25, 15),
        _AgeCallData('26-30', 40, 30),
        _AgeCallData('31-35', 35, 25),
        _AgeCallData('36-40', 20, 10),
      ];

      setState(() => isLoading = false);
    } catch (e) {
      print('Statistics fetch error: $e');
      setState(() => isLoading = false);
    }
  }

  Widget SettingsContainer(
  IconData? icon, 
  String text, 
  String? image, 
  bool hasSwitch, 
  {bool? switchValue, 
  ValueChanged<bool>? onSwitchChanged}
) {
  return Builder(builder: (context) {
    final size = MediaQuery.of(context).size;

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color(0xffDFF6FF), 
        borderRadius: BorderRadius.circular(13)
      ),
      padding: EdgeInsets.symmetric(
        vertical: size.height * 0.02,
        horizontal: size.width * 0.04,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (icon != null)
                Icon(
                  icon,
                  color: Color(0xff1FAAEA),
                  size: size.width * 0.06,
                )
              else if (image != null)
                Image.asset(
                  image,
                  width: size.width * 0.06,
                  height: size.width * 0.06,
                ),
              SizedBox(width: size.width * 0.03),
              Text(
                text,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Roboto', // Replace with your font
                  fontSize: size.width * 0.045,
                  fontWeight: FontWeight.w500
                ),
              ),
            ],
          ),
         
        ],
      ),
    );
  });
}



  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double paddingScale = size.width * 0.05;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: size.height * 0.1,
        backgroundColor: const Color(0xff66C7F4),
        centerTitle: true,
        title: Text(
          'Statistics',
          style: TextStyle(
            color: Colors.white,
            fontFamily: fontFamily,
            fontSize: size.width * 0.058,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xffffffff),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(13),
                  topRight: Radius.circular(13),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: paddingScale,
                  vertical: paddingScale * 0.75,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SettingsContainer(null, '(0) Total scam calls detected', null, false),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                        child: Text(
                                    'Scam call detection analytics',
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff1FAAEA),
                                      fontSize: 18
                                    ),
                                  ),
                      ),
                      // First Row: Circle Graphs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPieChart(
                            'Proceeded',
                            spamCallProceedData,
                            true
                          ),
                          _buildPieChart(
                            'Blocked',
                            spamCallBlockedData,
                            false
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.07),
                       Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0,horizontal: 10),
                        child: Text(
                                    'Age-based call flaged',
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff1FAAEA),
                                      fontSize: 18
                                    ),
                                  ),
                      ),
                      // Line Graph
                      _buildLineGraph(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPieChart(String title, Map<String, double> data,bool isProceed) {
    return Card(
      color: Color(0xffDFF6FF),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
        
        // mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 0),
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            PieChart(
              dataMap: data,
              emptyColor: Color(0xffDFDFDF),
              animationDuration: const Duration(milliseconds: 800),
              chartLegendSpacing: 20,
            
              chartRadius: 80,
              colorList:  const [
            // if(isProceed) 
             Color(0xffD20D0D),
               Color(0xff058B1E),
          //  if(!isProceed) 
              
              ],
              initialAngleInDegree: 0,
              chartType: ChartType.ring,
              ringStrokeWidth: 10,
              legendOptions:  const LegendOptions(
                showLegendsInRow: false,
                legendPosition: LegendPosition.right,
                showLegends: false,
              ),
              chartValuesOptions: const ChartValuesOptions(
                showChartValueBackground: true,
                showChartValues: true,
                showChartValuesInPercentage: true,
                showChartValuesOutside: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineGraph() {
    return Column(
      children: [
        // Text(
        //   'Calls by Age Group',
        //   style: TextStyle(
        //     fontFamily: fontFamily,
        //     fontWeight: FontWeight.bold,
        //   ),
        // ),
       SfCartesianChart(
  primaryXAxis: const CategoryAxis(),
  series: [
    ColumnSeries<_AgeCallData, String>(
      name: 'Proceeded Calls',
      dataSource: ageCallData,
      xValueMapper: (_AgeCallData data, _) => data.ageGroup,
      yValueMapper: (_AgeCallData data, _) => data.proceededCalls,
      color: const Color(0xff058B1E), // Use withOpacity instead
    ),
    ColumnSeries<_AgeCallData, String>(
      name: 'Blocked Calls',
      dataSource: ageCallData,
      xValueMapper: (_AgeCallData data, _) => data.ageGroup,
      yValueMapper: (_AgeCallData data, _) => data.blockedCalls,
      color: const Color(0xffD20D0D), // Use withOpacity instead
    ),
  ],
  legend: const Legend(
    isVisible: true,
    // position: LegendPosition.bottom,
  ),
)
      ],
    );
  }
}

class _AgeCallData {
  final String ageGroup;
  final int proceededCalls;
  final int blockedCalls;

  _AgeCallData(this.ageGroup, this.proceededCalls, this.blockedCalls);
}