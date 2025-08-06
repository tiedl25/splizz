import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:splizz/models/transaction.model.dart';

class TransactionPieChart extends StatelessWidget {
  const TransactionPieChart({
    super.key,
    required this.context,
    required this.members,
    required this.transaction,
    required this.textColor,
  });

  final BuildContext context;
  final dynamic members;
  final Transaction transaction;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('pieChart'),
      decoration: BoxDecoration(
        color: textColor.withAlpha(96),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(10),
      child: PieChart(
        dataMap: Map.fromIterable(
          members, 
          key: (m) => m.id,
          value: (m) => transaction.operations.sublist(1).firstWhere((o) => o.memberId == m.id).value.abs()
        ),
        legendOptions: LegendOptions(
          legendPosition: LegendPosition.right,
          showLegends: true,
          legendTextStyle: TextStyle(
            color: textColor,
          ),
        ),
        legendLabels: Map.fromIterable(
          members, 
          key: (m) => m.id,
          value: (m) => m.name
        ),
        chartType: ChartType.disc,
        ringStrokeWidth: 20,
        animationDuration: const Duration(milliseconds: 700),
        chartLegendSpacing: 32,
        chartRadius: MediaQuery.of(context).size.width / 2.5,
        colorList: members.map<Color>((e) => Color(e.color)).toList(),
        initialAngleInDegree: 0,
        formatChartValues: (value) => "${value.toStringAsFixed(2)}€",
        chartValuesOptions: const ChartValuesOptions(
          showChartValues: true,
          showChartValuesInPercentage: false,
          showChartValuesOutside: false,
          decimalPlaces: 2,
          chartValueStyle: TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          chartValueBackgroundColor: Colors.transparent,
        )
      )
    );
  }
}