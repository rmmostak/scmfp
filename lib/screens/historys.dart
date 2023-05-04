import 'dart:convert';

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
  List<dynamic> data = [];

  Future<void> loadHistory() async {
    String token = await getToken();
    final response = await http.get(Uri.parse(historyURL), headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    });
    switch (response.statusCode) {
      case 200:
        setState(() {
          data = jsonDecode(response.body)['history']
              .map((h) => DecisionModel.fromJson(h))
              .toList() as List<dynamic>;
          loading = false;
        });
        break;
      case 401:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(unAuthError)),
        );
        throw Exception(serverError);
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(somethingWrong)),
        );
        throw Exception(serverError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: (!loading)
          ? ListView.separated(
              itemCount: data.length,
              itemBuilder: (BuildContext context, int index) {
                DecisionModel model = data[index];
                return ExpansionTile(
                  collapsedBackgroundColor: Colors.green.shade50,
                  collapsedTextColor: Colors.blue,
                  iconColor: Colors.green,
                  backgroundColor: Colors.blue.shade50,
                  title: Text(
                    'পরীক্ষণের সময়: \t\t${model.dateTime}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const SizedBox(
                          width: 15,
                        ),
                        Expanded(
                          flex: 10,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            color: Colors.white60,
                            child: Column(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 10, 0, 5),
                                  child: const Text(
                                    'পিএইচ',
                                    style: TextStyle(
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 5),
                                  child: Text(
                                    '${model.ph}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const Spacer(
                          flex: 1,
                        ),
                        Expanded(
                          flex: 10,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            color: Colors.white60,
                            child: Column(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 10, 0, 5),
                                  child: const Text(
                                    'তাপমাত্রা',
                                    style: TextStyle(
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(5, 0, 10, 5),
                                  child: Text(
                                    '${model.temp} °সেঃ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const Spacer(
                          flex: 1,
                        ),
                        Expanded(
                          flex: 10,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            color: Colors.white60,
                            child: Column(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 10, 0, 5),
                                  child: const Text(
                                    'লবণাক্ততা',
                                    style: TextStyle(
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(5, 0, 5, 5),
                                  child: Text(
                                    '${model.salinity} পিপিএম',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const Spacer(
                          flex: 1,
                        ),
                        Expanded(
                          flex: 10,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            color: Colors.white60,
                            child: Column(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 10, 0, 5),
                                  child: const Text(
                                    'ডিও',
                                    style: TextStyle(
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 5),
                                  child: Text(
                                    '${model.d0}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const Spacer(
                          flex: 1,
                        ),
                        Expanded(
                          flex: 10,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            color: Colors.white60,
                            child: Column(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 10, 0, 5),
                                  child: const Text(
                                    'অ্যামোনিয়া',
                                    style: TextStyle(
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(5, 0, 10, 5),
                                  child: Text(
                                    '${model.ammonia}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const Spacer(
                          flex: 1,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
                      child: Column(
                        children: [
                          SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: const Text(
                                'ফলাফল:',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              )),
                          const Divider(
                            indent: 10,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Text(
                              '${model.decision}',
                              textAlign: TextAlign.start,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                );
              },
              separatorBuilder: (context, index) => const Divider(
                height: 2,
                color: Colors.white,
              ),
            )
          : Container(
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              child: const SizedBox(
                height: 30,
                width: 30,
                child: CircularProgressIndicator(),
              )),
    );
  }

  @override
  void initState() {
    loadHistory();
    loading = true;
    super.initState();
  }
}
