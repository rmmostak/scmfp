import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scmfp/common/constants.dart';
import 'package:scmfp/models/decision.dart';

import '../common/user_service.dart';

class History extends StatefulWidget {
  const History({Key? key}) : super(key: key);

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  bool loading = false;
  List<dynamic> historyList = [];

  Widget buildList(List<dynamic> data) {
/*    return Drawer(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                  return prepareList(data[index]);
                }
              )
            ],
          ),
        ),
      ),
    );*/


    /*ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          historyList[index].isExpanded = !isExpanded;
        });
      },
      children: historyList.map<ExpansionPanel>((DecisionModel model) {
        return ExpansionPanel(
            headerBuilder: (BuildContext context, bool isExpanded) {
              return ListTile(
                title: Text(model.dateTime.toString()),
              );
            },
            body: ListTile(
              title: Text('${model.ph} \t${model.temp}\t${model.salinity}'),
              subtitle: Text('Result:\t${model.decision}'),
              onTap: () {
                print('${model.decision}');
              },
            ));
      }),
    );*/
    return const Text('data');
  }

  Future<void> loadHistory() async {
      String token = await getToken();
      final response = await http.get(Uri.parse(historyURL), headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      });
      print('$historyURL, \t${response.statusCode}');
      switch (response.statusCode) {
        case 200:
          setState(() {
            historyList = jsonDecode(response.body)['history'].map((p) => DecisionModel.fromJson(p)).toList() as List<dynamic>;
            print('Data: $historyURL, \t$historyList');
            loading = false;
          });
          break;
        case 401:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(unAuthError)),
          );
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(somethingWrong)),
          );
          break;
      }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width,
      child: const Padding(
        padding: EdgeInsets.all(10),
        child: ExpansionTile(
          title: Text('DateTime'),
          subtitle: Text('pH, DO, Salt'),
          children: [
            ListTile(
              title: Text('List item'),
              subtitle: Text('List subtitle'),
            )
          ],
        )
      ),
    );
  }

  @override
  void initState() {
    loadHistory();
    super.initState();
  }
}
