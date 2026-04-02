import 'package:flutter/material.dart';
import '../widgets/realtime_nifty_card.dart';
import '../widgets/market_card.dart';
import '../widgets/market_banner.dart';
import '../widgets/strategy_card.dart';
import '../widgets/trade_setup.dart';
import '../widgets/rules.dart';
import '../widgets/decision_table.dart';
import '../widgets/stop_loss.dart';
import '../widgets/income_plan.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? nifty; // 🔥 dynamic value
  final double vix = 18;
  final String trend = "Bullish";

  String getMarketType() {
    if (vix > 20 && trend == "Bearish") return "Bearish";
    if (vix < 20 && trend == "Bullish") return "Bullish";
    return "Sideways";
  }

  @override
  Widget build(BuildContext context) {
    String marketType = getMarketType();

    return Scaffold(
      appBar: AppBar(title: Text("📊 Options Strategy")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            MarketBanner(type: marketType),

            // 🔥 Pass callback here
            RealtimeNiftyCard(
              onNiftyUpdate: (value) {
                setState(() {
                  nifty = value;
                });
              },
            ),

            // 🔥 Use live nifty (fallback if null)
            MarketCard(
              nifty: nifty ?? 0,
              vix: vix,
              trend: trend,
            ),

            Row(
              children: [
                Expanded(
                  child: StrategyCard(type: marketType),
                ),
                Expanded(
                  child: TradeSetup(
                    type: marketType,
                    nifty: nifty ?? 0, // 🔥 dynamic
                  ),
                ),
              ],
            ),

            Rules(type: marketType),
            DecisionTable(type: marketType),
            StopLoss(type: marketType),
            IncomePlan(),
          ],
        ),
      ),
    );
  }
}