import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RealtimeNiftyCard extends StatefulWidget {
  final Function(double)? onNiftyUpdate;

  const RealtimeNiftyCard({Key? key, this.onNiftyUpdate}) : super(key: key);

  @override
  _RealtimeNiftyCardState createState() => _RealtimeNiftyCardState();
}

class _RealtimeNiftyCardState extends State<RealtimeNiftyCard> {
  double? _nifty;
  String _status = 'Loading';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadNifty();
    _timer = Timer.periodic(Duration(seconds: 30), (_) => _loadNifty());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadNifty() async {
    setState(() {
      _status = 'Fetching';
    });

    try {
      final nseUrl =
          'https://www.nseindia.com/api/equity-stockIndices?index=NIFTY%2050';

      final nseRes = await http.get(
        Uri.parse(nseUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 15));

      if (nseRes.statusCode == 200) {
        final data = jsonDecode(nseRes.body);
        final result = data['data'];

        if (result != null && result.isNotEmpty) {
          final price = result[0]['lastPrice'];

          if (price != null) {
            final fetched = (price as num).toDouble();

            setState(() {
              _nifty = fetched;
              _status = 'Realtime';
            });

            // 👇 Send value to HomeScreen
            widget.onNiftyUpdate?.call(fetched);

            return;
          }
        }
      }

      throw Exception('NSE API failed');
    } catch (e) {
      setState(() {
        _status = 'Offline';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = _nifty?.toStringAsFixed(2) ?? '--';

    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Realtime Nifty',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text('Value: $display',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Status: $_status',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            Icon(Icons.show_chart, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}