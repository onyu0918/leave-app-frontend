import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminLeaveListScreen extends StatefulWidget {
  const AdminLeaveListScreen({Key? key}) : super(key: key);

  @override
  State<AdminLeaveListScreen> createState() => _AdminLeaveListScreenState();
}

class _AdminLeaveListScreenState extends State<AdminLeaveListScreen> {
  List<Map<String, dynamic>> leaves = [];
  int currentPage = 0;
  final int pageSize = 10;
  String selectedStatus = 'ALL';
  String nameQuery = '';
  int monthRange = 6;

  final TextEditingController nameController = TextEditingController();
  int? openedRejectId;
  Map<int, TextEditingController> reasonControllers = {};
  Map<int, bool> isLoadingMap = {};

  Future<void> _fetchLeaves() async {
    final response = await ApiService.getFilteredLeaveRequests(
      page: currentPage,
      size: pageSize,
      status: selectedStatus == 'ALL' ? null : selectedStatus,
      name: nameQuery,
      months: monthRange,
    );
    setState(() {
      leaves = List<Map<String, dynamic>>.from(response);
      reasonControllers = {
        for (var leave in response) leave['id']: TextEditingController(),
      };
      isLoadingMap = {
        for (var leave in response) leave['id']: false,
      };
      openedRejectId = null;
    });
  }

  Future<void> _updateLeaveStatus(int id, String status, [String? rejectReason]) async {
    setState(() {
      isLoadingMap[id] = true;
    });

    try {
      await ApiService.updateLeaveStatus(id, status, rejectReason: rejectReason);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('신청이 $status 처리되었습니다.'),
      ));
      if (status == 'REJECTED') {
        setState(() {
          openedRejectId = null;
        });
      }
      await _fetchLeaves();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('처리에 실패했습니다.'),
      ));
    } finally {
      setState(() {
        isLoadingMap[id] = false;
      });
    }
  }

  Future<void> _deleteLeave(int id) async {
    setState(() {
      isLoadingMap[id] = true;
    });

    try {
      await ApiService.deleteLeave(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('신청이 삭제되었습니다.'),
      ));
      await _fetchLeaves();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('삭제에 실패했습니다.'),
      ));
    } finally {
      setState(() {
        isLoadingMap[id] = false;
      });
    }
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Row(
          children: [
            DropdownButton<String>(
              value: selectedStatus,
              items: ['ALL', 'APPROVED', 'PENDING', 'REJECTED']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                  currentPage = 0;
                });
                _fetchLeaves();
              },
            ),
            const SizedBox(width: 16),
            DropdownButton<int>(
              value: monthRange,
              items: [
                DropdownMenuItem(value: 0, child: Text('전체')),
                ...[1, 3, 6, 12]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m개월')))
                    .toList(),
              ],
              onChanged: (value) {
                setState(() {
                  monthRange = value!;
                  currentPage = 0;
                });
                _fetchLeaves();
              },
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '이름 검색'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  nameQuery = nameController.text;
                  currentPage = 0;
                });
                _fetchLeaves();
              },
            )
          ],
        ),
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
          child: const Text('이전'),
        ),
        Text('Page ${currentPage + 1}'),
        TextButton(
          onPressed: leaves.length == pageSize
              ? () {
            setState(() {
              currentPage++;
            });
            _fetchLeaves();
          }
              : null,
          child: const Text('다음'),
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
      appBar: AppBar(title: const Text('연차 신청 목록')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildFilters(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: leaves.length,
                itemBuilder: (context, index) {
                  final leave = leaves[index];
                  final id = leave['id'];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text('${leave['username']} | ${leave['startDate']} ~ ${leave['endDate']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('사유: ${leave['reason']}'),
                              Text('상태: ${leave['status']}'),
                            ],
                          ),
                        ),
                        if (leave['status'] == 'PENDING' || true) // 삭제는 항상 노출
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                            child: Row(
                              children: [
                                if (leave['status'] == 'PENDING') ...[
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.check),
                                      label: const Text('승인'),
                                      style: ElevatedButton.styleFrom(
                                        // backgroundColor: Colors.green,
                                      ),
                                      onPressed: isLoadingMap[id] == true
                                          ? null
                                          : () => _updateLeaveStatus(id, 'APPROVED'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.close),
                                      label: const Text('거절'),
                                      style: ElevatedButton.styleFrom(
                                        // backgroundColor: Colors.red,
                                      ),
                                      onPressed: isLoadingMap[id] == true
                                          ? null
                                          : () {
                                        setState(() {
                                          openedRejectId = openedRejectId == id ? null : id;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.delete),
                                    label: const Text('삭제'),
                                    style: ElevatedButton.styleFrom(
                                      // backgroundColor: Colors.grey,
                                    ),
                                    onPressed: isLoadingMap[id] == true
                                        ? null
                                        : () => _deleteLeave(id),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState: (openedRejectId == id)
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              children: [
                                TextField(
                                  controller: reasonControllers[id],
                                  decoration: const InputDecoration(labelText: '거절 사유'),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: isLoadingMap[id] == true
                                      ? null
                                      : () {
                                    final reason =
                                        reasonControllers[id]?.text ?? '';
                                    _updateLeaveStatus(id, 'REJECTED', reason);
                                  },
                                  child: isLoadingMap[id] == true
                                      ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                      : const Text('거절 제출'),
                                ),
                              ],
                            ),
                          ),
                          secondChild: const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
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
