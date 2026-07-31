import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('students');
  await Hive.openBox('finance');
  await Hive.openBox('attendance');
  runApp(SnterKareemApp());
}

class SnterKareemApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سنتر مستر كريم الطواب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Cairo', scaffoldBackgroundColor: Color(0xFFF5F5F5)),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final pages = [StudentsScreen(), AttendanceScreen(), FinanceScreen(), MessagesScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('سنتر مستر كريم الطواب'), backgroundColor: Colors.white, foregroundColor: Colors.black, centerTitle: true),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'الطلاب'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'الغياب'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'المالية'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'الرسائل'),
        ],
      ),
    );
  }
}

class StudentsScreen extends StatefulWidget { @override _StudentsScreenState createState() => _StudentsScreenState(); }
class _StudentsScreenState extends State<StudentsScreen> {
  final box = Hive.box('students');
  final nameController = TextEditingController(); final phoneController = TextEditingController(); final priceController = TextEditingController();
  void _addStudent() {
    if(nameController.text.isEmpty) return;
    box.add({'name': nameController.text, 'phone': phoneController.text, 'price': int.tryParse(priceController.text)?? 250, 'paidMonths': 0});
    nameController.clear(); phoneController.clear(); priceController.clear(); setState(() {});
  }
  void _showStudentCard(int index) {
    var student = box.getAt(index); int due = (student['price'] * 3) - (student['price'] * student['paidMonths']);
    showDialog(context: context, builder: (_) => AlertDialog(title: Text('كارت الطالب', textAlign: TextAlign.right),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('الاسم: ${student['name']}'), Text('رقم ولي الأمر: ${student['phone']}'), Text('سعر الشهر: ${student['price']} جنيه'),
        Text('شهور مدفوعة: ${student['paidMonths']}'), Text('المستحق 3 شهور: $due جنيه', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ]), actions: [TextButton(onPressed: (){ Navigator.pop(context);}, child: Text('إغلاق'))],));
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(children: [
      Card(child: Padding(padding: EdgeInsets.all(16), child: Column(children: [
        Text('إضافة طالب جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(height: 15),
        TextFormField(controller: nameController, decoration: InputDecoration(labelText: 'الاسم رباعي', border: OutlineInputBorder())), SizedBox(height: 10),
        TextFormField(controller: phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'رقم ولي الأمر', border: OutlineInputBorder())), SizedBox(height: 10),
        TextFormField(controller: priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'سعر الشهر', border: OutlineInputBorder())), SizedBox(height: 15),
        ElevatedButton(onPressed: _addStudent, child: Text('حفظ الطالب'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], minimumSize: Size(double.infinity, 50))),
      ]))), SizedBox(height: 20),
   ...List.generate(box.length, (index){ var student = box.getAt(index);
        return Card(child: ListTile(onTap: () => _showStudentCard(index), title: Text(student['name'], textAlign: TextAlign.right),
          subtitle: Text('دافع ${student['paidMonths']} شهور', textAlign: TextAlign.right), trailing: Icon(Icons.card_membership, color: Colors.blue))); })
    ],));
  }
}

class AttendanceScreen extends StatefulWidget { @override _AttendanceScreenState createState() => _AttendanceScreenState(); }
class _AttendanceScreenState extends State<AttendanceScreen> {
  final studentsBox = Hive.box('students'); final attendanceBox = Hive.box('attendance'); Map<int, bool> attendanceMap = {};
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(children: [
      Card(child: Padding(padding: EdgeInsets.all(16), child: Column(children: [
        Text('تسجيل الغياب ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(height: 15),
     ...List.generate(studentsBox.length, (index){ var student = studentsBox.getAt(index); attendanceMap[index] = attendanceMap[index]?? true;
          return CheckboxListTile(title: Text(student['name'], textAlign: TextAlign.right), value: attendanceMap[index], onChanged: (val){ setState(()=> attendanceMap[index] = val!); }, controlAffinity: ListTileControlAffinity.leading); }),
        SizedBox(height: 15),
        ElevatedButton(onPressed: (){ attendanceBox.add({'date': DateTime.now().toString(), 'data': attendanceMap}); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ الغياب'))); },
          child: Text('حفظ الغياب'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: Size(double.infinity, 50))),
      ])))
    ],));
  }
}

class FinanceScreen extends StatefulWidget { @override _FinanceScreenState createState() => _FinanceScreenState(); }
class _FinanceScreenState extends State<FinanceScreen> {
  final studentsBox = Hive.box('students'); final financeBox = Hive.box('finance');
  void _payMonth(int index) { var student = studentsBox.getAt(index); student['paidMonths'] = student['paidMonths'] + 1; studentsBox.putAt(index, student); financeBox.add({'type': 'إيراد', 'amount': student['price'], 'name': student['name'], 'date': DateTime.now().toString()}); setState(() {}); }
  @override
  Widget build(BuildContext context) {
    double totalIncome = financeBox.values.where((e)=>e['type']=='إيراد').fold(0, (sum, item) => sum + item['amount']);
    return SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(children: [
      Card(color: Colors.green[50], child: Padding(padding: EdgeInsets.all(16), child: Column(children: [
        Text('الملخص المالي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(height: 10),
        Text('إجمالي الإيرادات: $totalIncome جنيه', style: TextStyle(fontSize: 16, color: Colors.green[800], fontWeight: FontWeight.bold)),
      ]))), SizedBox(height: 20), Text('تحصيل من الطلاب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
   ...List.generate(studentsBox.length, (index){ var student = studentsBox.getAt(index); int due = (student['price'] * 3) - (student['price'] * student['paidMonths']);
        return Card(child: ListTile(title: Text(student['name'], textAlign: TextAlign.right), subtitle: Text('عليه: $due جنيه', textAlign: TextAlign.right, style: TextStyle(color: due > 0? Colors.red : Colors.green)),
          trailing: ElevatedButton(onPressed: ()=> _payMonth(index), child: Text('دفع شهر'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green)))); })
    ],));
  }
}

class MessagesScreen extends StatelessWidget {
  final box = Hive.box('students');
  _sendWhatsApp(String phone, String name) async { String msg = "تنبيه من سنتر مستر كريم الطواب: $name غاب عن حصة الرياضيات اليوم ${DateTime.now().day}/${DateTime.now().month}"; String url = "https://wa.me/2$phone?text=${Uri.encodeComponent(msg)}"; if (await canLaunch(url)) await launch(url); }
  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemCount: box.length, itemBuilder: (context, index){ var student = box.getAt(index);
      return Card(child: ListTile(title: Text(student['name'], textAlign: TextAlign.right), subtitle: Text(student['phone'], textAlign: TextAlign.right),
        trailing: IconButton(icon: Icon(Icons.whatsapp, color: Colors.green, size: 30), onPressed: () => _sendWhatsApp(student['phone'], student['name']))); });
  }
                            }
