import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class KryptoInfoPage extends StatefulWidget {
  KryptoInfoPage({Key? key}) : super(key: key);

  @override
  _KryptoInfoPageState createState() => _KryptoInfoPageState();
}

class _KryptoInfoPageState extends State<KryptoInfoPage> {
  late Future<List> futureKryptoData;
  var searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureKryptoData = fetchKryptoData();
    searchController.addListener(() {
      setState(() {});
    });
  }

  Future<List> fetchKryptoData() async {
    final response = await http.get(Uri.parse('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=false'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load krypto data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Krypto Informator'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Szukaj',
                labelStyle: TextStyle(color: Colors.white70),
                fillColor: Colors.white10,
                filled: true,
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List>(
              future: futureKryptoData,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data?.length,
                    itemBuilder: (context, index) {
                      return snapshot.data![index]['name'].toLowerCase().contains(searchController.text.toLowerCase())
                          ? Card(
                              color: Colors.grey[900],
                              child: ListTile(
                                leading: Image.network(snapshot.data![index]['image']),
                                title: Text(snapshot.data![index]['name'], style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white)),
                                subtitle: Text("\$${snapshot.data![index]['current_price']}", style: TextStyle(fontSize: 16.0, color: Colors.white70)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => KryptoDetailPage(
                                        snapshot.data![index]['id'],
                                        snapshot.data![index]['name'],
                                        snapshot.data![index]['image'],
                                        snapshot.data![index]['current_price'].toString(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container();
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }
                return CircularProgressIndicator();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class KryptoDetailPage extends StatefulWidget {
  final String id;
  final String name;
  final String image;
  final String price;

  KryptoDetailPage(this.id, this.name, this.image, this.price);

  @override
  _KryptoDetailPageState createState() => _KryptoDetailPageState();
}

class _KryptoDetailPageState extends State<KryptoDetailPage> {
  String? description;
  List<double>? prices;

  @override
  void initState() {
    super.initState();
    fetchDescription();
    fetchPrices();
  }

  fetchDescription() async {
    final response = await http.get(Uri.parse('https://api.coingecko.com/api/v3/coins/${widget.id}'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        description = json['description']['en'] ?? 'No description available';
      });
    } else {
      throw Exception('Failed to load krypto data');
    }
  }

  fetchPrices() async {
    final response = await http.get(Uri.parse('https://api.coingecko.com/api/v3/coins/${widget.id}/market_chart?vs_currency=usd&days=1&interval=hourly'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        prices = List<double>.from(json['prices'].map((item) => item[1]));
      });
    } else {
      throw Exception('Failed to load krypto data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: prices == null
          ? CircularProgressIndicator()
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    Image.network(widget.image),
                    Text(widget.name, style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("\$${widget.price}", style: TextStyle(fontSize: 24.0, color: Colors.white70)),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(description ?? '', style: TextStyle(fontSize: 16.0, color: Colors.white70)),
                    ),
                    Container(
                      height: 200, // specifying the height of the container
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(prices!.length, (index) => FlSpot(index.toDouble(), prices![index])),
                                isCurved: true,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(show: false),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
