import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'road_works.dart';
import 'metro_updates.dart';
import 'traffic_blocks.dart';
import 'report_problem.dart';
import 'my_reports.dart';
import 'best_route.dart';
import 'user_profile.dart';

class UserHome extends StatelessWidget {
  const UserHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final items = [
      _Item('Road Works', Icons.construction, Colors.orange, const RoadWorks()),
      _Item('Metro Updates', Icons.subway, Colors.blue, const MetroUpdates()),
      _Item('Traffic Blocks', Icons.traffic, Colors.red, const TrafficBlocks()),
      _Item('Report Problem', Icons.report_problem, Colors.purple,
          const ReportProblem()),
      _Item('My Reports', Icons.list_alt, Colors.teal, const MyReports()),
      _Item('Best Route', Icons.alt_route, Colors.green, const BestRoute()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.name ?? "User"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const UserProfile())),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.1,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final it = items[i];
          return InkWell(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => it.page)),
            borderRadius: BorderRadius.circular(14),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: it.color.withOpacity(0.15),
                    child: Icon(it.icon, size: 30, color: it.color),
                  ),
                  const SizedBox(height: 10),
                  Text(it.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Item {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;
  _Item(this.title, this.icon, this.color, this.page);
}