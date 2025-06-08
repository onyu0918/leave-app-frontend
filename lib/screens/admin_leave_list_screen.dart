import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/leave_service.dart';
import 'package:intl/intl.dart';

class AdminLeaveListScreen extends StatefulWidget {
  const AdminLeaveListScreen({Key? key}) : super(key: key);

  @override
  State<AdminLeaveListScreen> createState() => _AdminLeaveListScreenState();
}

class _AdminLeaveListScreenState extends State<AdminLeaveListScreen> {
  List<Map<String, dynamic>> leaves = [];
  int currentPage = 0;
  final int pageSize = 10;
  int selectedStatus = 3;
  String nameQuery = '';
  int monthRange = 6;
  int? openedCommentId;
  int? openedStatus;

  final TextEditingController nameController = TextEditingController();
  int? openedRejectId;
  Map<int, TextEditingController> reasonControllers = {};
  Map<int, bool> isLoadingMap = {};

  Future<void> _fetchLeaves() async {
    final response = await ApiService.getFilteredLeaveRequests(
      page: currentPage,
      size: pageSize,
      status: selectedStatus == 3 ? null : selectedStatus,
      name: nameQuery,
      months: monthRange,
    );

    final leaveService = LeaveService();

    final usernames = response
        .map((leave) => leave['username'] as String)
        .toSet()
        .toList();

    final leaveDataMap = <String, Map<String, dynamic>>{};

    await Future.wait(usernames.map((username) async {
      try {
        final data = await leaveService.userLeaveData(username);
        leaveDataMap[username] = data;
      } catch (e) {
        leaveDataMap[username] = {'availableLeaves': null};
      }
    }));
    setState(() {
      leaves = List<Map<String, dynamic>>.from(response.map((leave) {
        final username = leave['username'] as String;
        final userLeaveData = leaveDataMap[username];
        return {
          ...leave,
          'availableLeaves': userLeaveData?['availableLeaves'],
        };
      }));
      reasonControllers = {
        for (var leave in response) leave['id']: TextEditingController(),
      };
      isLoadingMap = {
        for (var leave in response) leave['id']: false,
      };
      openedRejectId = null;
    });
  }

  Future<void> _updateLeaveStatus(int id, int status, [String? comment]) async {
    setState(() {
      isLoadingMap[id] = true;
    });

    try {
      await ApiService.updateLeaveStatus(id, status, comment: comment);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('申請は$statusされました。'),
      ));

      setState(() {
        openedCommentId = null;
      });

      if (status == 2) {
        setState(() {
          openedRejectId = null;
        });
      }
      await _fetchLeaves();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('処理が正常に行われませんでした。'),
      ));
    } finally {
      setState(() {
        isLoadingMap[id] = false;
      });
    }
  }


  final Map<int, String> statusLabels = {
    3: 'すべて',
    1: '承認済み',
    0: '申請中',
    2: '却下済み',
  };
  String getStatusText(int status) {
    switch (status) {
      case 0:
        return '申請中';
      case 1:
        return '承認済み';
      case 2:
        return '却下済み';
      default:
        return 'Error';
    }
  }
  Widget _styledButton(String label, IconData icon, VoidCallback? onPressed, {Color? color}) {
    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.grey.shade800,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text(
                      'ステータス: ',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedStatus,
                          items: statusLabels.entries
                              .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedStatus = value!;
                              currentPage = 0;
                            });
                            _fetchLeaves();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text(
                      '期間: ',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: monthRange,
                          items: [
                            DropdownMenuItem(value: 0, child: Text('すべて')),
                            ...[1, 3, 6, 12, 24].map(
                                  (m) => DropdownMenuItem(value: m, child: Text('$mヶ月')),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              monthRange = value!;
                              currentPage = 0;
                            });
                            _fetchLeaves();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '氏名検索',
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                nameQuery = nameController.text;
                currentPage = 0;
              });
              _fetchLeaves();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(Icons.search),
          ),
          ],
        )
      ],
    );
  }


  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: currentPage > 0
              ? () {
            setState(() {
              currentPage--;
            });
            _fetchLeaves();
          }
              : null,
          child: const Text('前へ'),
        ),
        Text('ページ ${currentPage + 1}'),
        TextButton(
          onPressed: leaves.length == pageSize
              ? () {
            setState(() {
              currentPage++;
            });
            _fetchLeaves();
          }
              : null,
          child: const Text('次へ'),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('有給休暇申請一覧')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(


              child: ListView.builder(
                itemCount: leaves.length,
                itemBuilder: (context, index) {
                  final leave = leaves[index];
                  final id = leave['id'];
                  final date = DateTime.parse(leave['createdDate']);
                  final formatted = DateFormat('yyyy-MM-dd').format(date);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('氏名 : ${leave['name']}'),
                        Text('申請日 : $formatted'),
                        Text('状態 : ${getStatusText(leave['status'])}'),
                        const SizedBox(height: 8),
                        Text('申請期間 : ${leave['startDate']} ~ ${leave['endDate']} (${leave['days']}日)'),
                        if (leave['availableLeaves'] != null)
                          Text('残り有給 : ${leave['availableLeaves']}日'),
                        Text('理由 : ${leave['reason']}'),
                        const SizedBox(height: 12),

                        // status != 2일 때만 코멘트 입력창 표시
                        if (leave['status'] != 2) ...[
                          TextField(
                            controller: reasonControllers[id],
                            decoration: const InputDecoration(
                              labelText: 'コメント',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // status == 0 (신청 대기): 신청, 거절 버튼 표시
                        if (leave['status'] == 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: isLoadingMap[id] == true
                                    ? null
                                    : () {
                                  final comment = reasonControllers[id]?.text.trim() ?? '';
                                  if (comment.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('コメントを入力してください。')),
                                    );
                                    return;
                                  }
                                  _updateLeaveStatus(id, 1, comment); // 승인
                                },
                                icon: isLoadingMap[id] == true
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Icon(Icons.check),
                                label: const Text('承認'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: isLoadingMap[id] == true
                                    ? null
                                    : () {
                                  final comment = reasonControllers[id]?.text.trim() ?? '';
                                  if (comment.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('コメントを入力してください。')),
                                    );
                                    return;
                                  }
                                  _updateLeaveStatus(id, 2, comment); // 거절
                                },
                                icon: isLoadingMap[id] == true
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Icon(Icons.close),
                                label: const Text('差し戻し'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ],
                          ),

                        // status == 1 (승인됨): 거절(取り消し) 버튼만 표시
                        if (leave['status'] == 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: isLoadingMap[id] == true
                                    ? null
                                    : () {
                                  final comment = reasonControllers[id]?.text.trim() ?? '';
                                  if (comment.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('コメントを入力してください。')),
                                    );
                                    return;
                                  }
                                  _updateLeaveStatus(id, 2, comment); // 거절
                                },
                                icon: isLoadingMap[id] == true
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Icon(Icons.close),
                                label: const Text('取り消し'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // child: Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     // Text(
                    //     //   '氏名 : ${leave['name']}',
                    //     //   style: const TextStyle(fontWeight: FontWeight.bold),
                    //     // ),
                    //
                    //     Text('氏名 : ${leave['name']}'),
                    //     Text('申請日 : $formatted'),
                    //     Text('状態 : ${getStatusText(leave['status'])}'),
                    //     const SizedBox(height: 8),
                    //     Text('申請期間 : ${leave['startDate']} ~ ${leave['endDate']} (${leave['days']}日)'),
                    //     if (leave['availableLeaves'] != null)
                    //       Text('残り有給 : ${leave['availableLeaves']}日'),
                    //     Text('理由 : ${leave['reason']}'),
                    //     const SizedBox(height: 12),
                    //     Row(
                    //       children: [
                    //         if (leave['status'] == 0) ...[
                    //           _styledButton(
                    //             '承認',
                    //             Icons.check,
                    //             isLoadingMap[id] == true
                    //                 ? null
                    //                 : () {
                    //               setState(() {
                    //                 openedCommentId = id;
                    //                 openedStatus = 1;
                    //               });
                    //             },
                    //             color: Colors.grey.shade800,
                    //           ),
                    //           const SizedBox(width: 8),
                    //           _styledButton(
                    //             '差し戻し',
                    //             Icons.close,
                    //                 () {
                    //               setState(() {
                    //                 openedCommentId = id;
                    //                 openedStatus = 2;
                    //               });
                    //             },
                    //             color: Colors.grey.shade800,
                    //           ),
                    //           const SizedBox(width: 8),
                    //         ],
                    //         if (leave['status'] == 1) ...[
                    //           _styledButton(
                    //             '取り消し',
                    //             Icons.close,
                    //                 () {
                    //               setState(() {
                    //                 openedCommentId = id;
                    //                 openedStatus = 2;
                    //               });
                    //             },
                    //             color: Colors.grey.shade800,
                    //           ),
                    //           const SizedBox(width: 8),
                    //         ],
                    //       ],
                    //     ),
                    //     if (openedCommentId == id) ...[
                    //       const SizedBox(height: 12),
                    //       TextField(
                    //         controller: reasonControllers[id],
                    //         decoration: const InputDecoration(
                    //           labelText: 'コメント',
                    //           border: OutlineInputBorder(),
                    //         ),
                    //         maxLines: 3,
                    //       ),
                    //       const SizedBox(height: 8),
                    //       Row(
                    //         mainAxisAlignment: MainAxisAlignment.end,
                    //         children: [
                    //           ElevatedButton.icon(
                    //             onPressed: isLoadingMap[id] == true
                    //                 ? null
                    //                 : () {
                    //               final comment = reasonControllers[id]?.text.trim() ?? '';
                    //               if (comment.isEmpty) {
                    //                 ScaffoldMessenger.of(context).showSnackBar(
                    //                   const SnackBar(content: Text('コメントを入力してください。')),
                    //                 );
                    //                 return;
                    //               }
                    //               _updateLeaveStatus(id, openedStatus!, comment);
                    //             },
                    //             icon: isLoadingMap[id] == true
                    //                 ? const SizedBox(
                    //               width: 16,
                    //               height: 16,
                    //               child: CircularProgressIndicator(
                    //                 strokeWidth: 2,
                    //                 color: Colors.white,
                    //               ),
                    //             )
                    //                 : const Icon(Icons.send),
                    //             label: Text(openedStatus == 1 ? '承認を提出' : '差し戻しを提出'),
                    //             style: ElevatedButton.styleFrom(
                    //               backgroundColor: openedStatus == 1 ? Colors.grey.shade800 : Colors.grey.shade800,
                    //               foregroundColor: Colors.white,
                    //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    //             ),
                    //           ),
                    //           const SizedBox(width: 8),
                    //           TextButton(
                    //             onPressed: () {
                    //               setState(() {
                    //                 openedCommentId = null;
                    //                 reasonControllers[id]?.clear();
                    //               });
                    //             },
                    //             child: const Text('キャンセル'),
                    //           ),
                    //         ],
                    //       ),
                    //     ],
                    //   ],
                    // ),
                  );
                },
              ),

            ),
            _buildPagination(),
          ],
        ),
      ),
    );
  }
}
