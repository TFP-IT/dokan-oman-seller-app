import 'package:active_ecommerce_seller_app/data_model/chart_response.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/shop_repository.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MChart extends StatefulWidget {
  const MChart({super.key});

  @override
  State<MChart> createState() => _MChartState();
}

class _MChartState extends State<MChart> {
  List<ChartResponse> chartList = [];

  List<CartesianSeries<OrdinalSales, String>> _createSampleData() {
    final data = List.generate(chartList.length, (index) {
      return OrdinalSales(
        chartList[index].date,
        int.parse(chartList[index].total!.round().toString()),
      );
    });

    return [
      StackedColumnSeries<OrdinalSales, String>(
        dataSource: data,
        xValueMapper: (OrdinalSales sales, _) => sales.year,
        yValueMapper: (OrdinalSales sales, _) => sales.sales,
        color: MyTheme.royal,
        width: 0.55,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        enableTooltip: true,
      ),
    ];
  }

  getChart() async {
    var response = await ShopRepository().chartRequest();
    chartList.addAll(response.values);
    setState(() {});
  }

  @override
  void initState() {
    getChart();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(color: MyTheme.hairline),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: const TextStyle(color: MyTheme.grey_153, fontSize: 11),
      ),
      primaryYAxis: NumericAxis(
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: const MajorGridLines(color: MyTheme.hairline, dashArray: [3, 4]),
        labelStyle: const TextStyle(color: MyTheme.grey_153, fontSize: 11),
      ),
      tooltipBehavior: TooltipBehavior(enable: true, color: MyTheme.navy_deep),
      legend: const Legend(isVisible: false),
      series: _createSampleData(),
      // tooltipBehavior: _tooltipBehavior,
    ));
  }
}

class OrdinalSales {
  final String? year;
  final int sales;

  OrdinalSales(this.year, this.sales);
}
