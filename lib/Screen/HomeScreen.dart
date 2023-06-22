import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String ipaddress = '';
  String ipdisplay = 'Server off, tap here to run';
  String ins = '';
  ServerSocket? serverSocket;
  List<String> messages = [];

  getDeviceIP() async {
    serverSocket != null ? serverSocket!.close() : null;
    print('Refresh');
    try {
      var net = await NetworkInterface.list();
      var result = await Connectivity().checkConnectivity();

      if (result == ConnectivityResult.mobile) {
        ins = net[1].toString().split(' ')[1];
      }else if(result == ConnectivityResult.wifi){
        ins = net[0].toString().split(' ')[1];
      }else{
        print('Tidak dalam jaringan apapun');
        setState(() {
          ipdisplay = 'no internet, tap to reconnect';
        });
        serverSocket!.close();
        return;
      }

      int startIndex = ins.indexOf("('") + 2;
      int endIndex = ins.lastIndexOf("',");
      
      setState(() {
        ipaddress = ins.substring(startIndex, endIndex);
        ipdisplay = 'Running on: '+ins.substring(startIndex, endIndex)+':8000';
      });
      
      if (ipaddress != 'Unknown') {
        startServer();
      }else{
        print('Tidak bisa menjalankan server');
      }
    } catch (e) {
      print(e);
    }
  }

  //Runnin local server
  startServer() async {
    try{
      serverSocket = await ServerSocket.bind('${ipaddress}', 8000);
      print('Server Started');
      print('Listening on ${serverSocket!.address} on port: ${serverSocket!.port}');
      serverSocket!.listen((socket) {
        handleClient(socket);
      });
    }catch(e){
      print('Socket ERROR: ${e.toString()}');
    }
  }

  handleClient(Socket socket){
    socket.listen((data) {
      var message = String.fromCharCodes(data).trim();
      if (message == 'TambahKiri') {
        _addScoreKiri('+');
      }
      if (message == 'KurangKiri') {
        _addScoreKiri('-');
      }
      if (message == 'TambahKanan') {
        _addScoreKanan('+');
      }
      if (message == 'KurangKanan') {
        _addScoreKanan('-');
      }
      if (message == 'reset') {
        setState(() {
          scoreKanan = 0;
          scoreKiri = 0;
        });
      }
      if (message == 'tukar') {
        setState(() {
          int temp = scoreKiri;
          scoreKiri = scoreKanan;
          scoreKanan = temp;
        });
      }
    },
    onError: (error){
      print('Socket Error: $error');
      socket.destroy();
    },
    onDone: (){
      print('Client Disconnected!');
      socket.destroy();
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        serverSocket!.close();
        setState(() {
          ipdisplay = 'no internet, tap to reconnect';
        });
      }
    });
  }
  

  @override
  void dispose() {
    serverSocket?.close();
    super.dispose();
  }

  int scoreKiri = 0;
  int scoreKanan = 0;

  _addScoreKiri(String score){
    if (score == '+') {
      scoreKiri++;
      setState(() {});
    }
    if (score == '-') {
      scoreKiri--;
      setState(() {});
    }
  }

  _addScoreKanan(String score){
    if (score == '+') {
      scoreKanan++;
      setState(() {});
    }
    if (score == '-') {
      scoreKanan--;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.amber
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: (){
                    HapticFeedback.vibrate();
                    _addScoreKiri('+');
                  },
                  child: Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width/2,
                    decoration: BoxDecoration(
                      color: Colors.red
                    ),
                    child: Text(scoreKiri.toString(), style: TextStyle(fontSize: MediaQuery.of(context).size.height/1.5, color: Colors.white),),
                  ),
                ),
                GestureDetector(
                  onTap: (){
                    HapticFeedback.vibrate();
                    _addScoreKanan('+');
                  },
                  child: Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width/2,
                    decoration: BoxDecoration(
                      color: Colors.blue
                    ),
                    child: Text(scoreKanan.toString(), style: TextStyle(fontSize: MediaQuery.of(context).size.height/1.5, color: Colors.white),),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width/3,
              padding: EdgeInsets.only(left: 10, right: 10),
              height: 50,
              decoration: BoxDecoration(
                color: Color.fromARGB(61, 0, 0, 0)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: (){
                      HapticFeedback.vibrate();
                      _addScoreKiri('-');
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 40,
                      width: 35,
                      color: Colors.transparent,
                      child: Text('-1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                    ),
                  ),
                  GestureDetector(
                    onTap: (){
                      HapticFeedback.vibrate();
                      showDialog(
                        context: context, 
                        builder: (context){
                          return AlertDialog(
                            title: Center(child: Text('Apakah anda yakin ingin mengatur ulang skor?', style: TextStyle(fontSize: 14),)),
                            actions: [
                              TextButton(
                                onPressed: (){
                                  Navigator.of(context).pop();
                                }, 
                                child: Text('Tidak')
                              ),
                              TextButton(
                                onPressed: (){
                                  setState(() {
                                    scoreKanan = 0;
                                    scoreKiri = 0;
                                  });
                                  Navigator.of(context).pop();
                                }, 
                                child: Text('Ya')
                              )
                            ],
                          );
                        }
                      );
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 40,
                      width: 35,
                      color: Colors.transparent,
                      child: Icon(Icons.replay_outlined, color: Colors.white,),
                    ),
                  ),
                  GestureDetector(
                    onTap: (){
                      HapticFeedback.vibrate();
                      _addScoreKanan('-');
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 40,
                      width: 35,
                      color: Colors.transparent,
                      child: Text('-1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 30,
            left: 10,
            child: GestureDetector(
              onTap: (){
                getDeviceIP();
              },
              child: Container(
                padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withAlpha(50),
                ),
                child: Text(ipdisplay, style: TextStyle(color: Colors.white),),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// class _HomeScreenState extends State<HomeScreen> {

//   int scoreKiri = 0;
//   int scoreKanan = 0;

//   _addScoreKiri(String score){
//     if (score == '+') {
//       scoreKiri++;
//       setState(() {});
//     }
//     if (score == '-') {
//       scoreKiri--;
//       setState(() {});
//     }
//   }

//   _addScoreKanan(String score){
//     if (score == '+') {
//       scoreKanan++;
//       setState(() {});
//     }
//     if (score == '-') {
//       scoreKanan--;
//       setState(() {});
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         alignment: Alignment.center,
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.amber
//             ),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   onTap: (){
//                     HapticFeedback.vibrate();
//                     _addScoreKiri('+');
//                   },
//                   child: Container(
//                     alignment: Alignment.center,
//                     width: MediaQuery.of(context).size.width/2,
//                     decoration: BoxDecoration(
//                       color: Colors.red
//                     ),
//                     child: Text(scoreKiri.toString(), style: TextStyle(fontSize: MediaQuery.of(context).size.height/1.5, color: Colors.white),),
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: (){
//                     HapticFeedback.vibrate();
//                     _addScoreKanan('+');
//                   },
//                   child: Container(
//                     alignment: Alignment.center,
//                     width: MediaQuery.of(context).size.width/2,
//                     decoration: BoxDecoration(
//                       color: Colors.blue
//                     ),
//                     child: Text(scoreKanan.toString(), style: TextStyle(fontSize: MediaQuery.of(context).size.height/1.5, color: Colors.white),),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Positioned(
//             bottom: 0,
//             child: Container(
//               width: MediaQuery.of(context).size.width/3,
//               padding: EdgeInsets.only(left: 10, right: 10),
//               height: 50,
//               decoration: BoxDecoration(
//                 color: Color.fromARGB(61, 0, 0, 0)
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   GestureDetector(
//                     onTap: (){
//                       HapticFeedback.vibrate();
//                       _addScoreKiri('-');
//                     },
//                     child: Container(
//                       alignment: Alignment.center,
//                       height: 40,
//                       width: 35,
//                       color: Colors.transparent,
//                       child: Text('-1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: (){
//                       HapticFeedback.vibrate();
//                       showDialog(
//                         context: context, 
//                         builder: (context){
//                           return AlertDialog(
//                             title: Center(child: Text('Apakah anda yakin ingin mengatur ulang skor?', style: TextStyle(fontSize: 14),)),
//                             actions: [
//                               TextButton(
//                                 onPressed: (){
//                                   Navigator.of(context).pop();
//                                 }, 
//                                 child: Text('Tidak')
//                               ),
//                               TextButton(
//                                 onPressed: (){
//                                   setState(() {
//                                     scoreKanan = 0;
//                                     scoreKiri = 0;
//                                   });
//                                   Navigator.of(context).pop();
//                                 }, 
//                                 child: Text('Ya')
//                               )
//                             ],
//                           );
//                         }
//                       );
//                     },
//                     child: Container(
//                       alignment: Alignment.center,
//                       height: 40,
//                       width: 35,
//                       color: Colors.transparent,
//                       child: Icon(Icons.replay_outlined, color: Colors.white,),
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: (){
//                       HapticFeedback.vibrate();
//                       _addScoreKanan('-');
//                     },
//                     child: Container(
//                       alignment: Alignment.center,
//                       height: 40,
//                       width: 35,
//                       color: Colors.transparent,
//                       child: Text('-1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }