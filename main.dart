import 'package:flutter/material.dart';
import 'security/pin_security.dart';
import 'services/local_store.dart';
import 'screens_ussd.dart';

void main() => runApp(const QanotApp());

const navy = Color(0xFF071426);
const panel = Color(0xFF10243B);
const cyan = Color(0xFF43D9F5);
const muted = Color(0xFF9CB0C8);

class Operator {
  final String name;
  final String subtitle;
  final Color color;
  const Operator(this.name, this.subtitle, this.color);
}

const operators = <Operator>[
  Operator('Beeline', 'Mobil aloqa', Color(0xFFFFD21F)),
  Operator('Ucell', 'Mobil aloqa', Color(0xFF9D6BFF)),
  Operator('UzMobile', 'Mobil aloqa', Color(0xFF35C9A5)),
  Operator('Mobiuz', 'Mobil aloqa', Color(0xFFFF626C)),
  Operator('Humans', 'Raqamli xizmatlar', Color(0xFFFF9D52)),
];

class QanotApp extends StatelessWidget {
  const QanotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QANOT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: navy,
        colorScheme: ColorScheme.fromSeed(
          seedColor: cyan,
          brightness: Brightness.dark,
          surface: panel,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
      ),
      home: const PinSecurityGate(child: MainScreen()),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int tab = 0;
  String? selectedOperator;
  String phone = '';

  @override
  void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    final saved = await QanotLocalStore.loadProfile();
    if (!mounted) return;
    setState(() { selectedOperator = saved.operatorName; phone = saved.phone; });
  }

  void openUssd() { Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UssdScreen())); }

  void showAddNumber() {
    final controller = TextEditingController(text: phone);
    String chosen = selectedOperator ?? operators.first.name;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: panel,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20, 20, 20, 24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Raqam qo‘shish',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Operatorni tanlang va telefon raqamingizni kiriting.',
                  style: TextStyle(color: muted)),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: chosen,
                decoration: const InputDecoration(
                  labelText: 'Mobil operator',
                  border: OutlineInputBorder(),
                ),
                items: operators.map((o) => DropdownMenuItem(
                  value: o.name, child: Text(o.name),
                )).toList(),
                onChanged: (v) => setSheetState(() => chosen = v ?? chosen),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon raqami',
                  hintText: '+998 90 123 45 67',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_android),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final value = controller.text.trim();
                    if (value.replaceAll(RegExp(r'\D'), '').length < 9) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Telefon raqamini to‘g‘ri kiriting.')),
                      );
                      return;
                    }
                    await QanotLocalStore.saveProfile(operatorName: chosen, phone: value);
                    if (!mounted) return;
                    setState(() { selectedOperator = chosen; phone = value; });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Operator va raqam ushbu telefonda saqlandi. SMS orqali egalik tasdiqlanmagan.')),
                    );
                  },
                  child: const Text('Raqamni saqlash'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homePage(),
      operatorsPage(),
      tariffsPage(),
      profilePage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [cyan, Color(0xFF658BFF)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.air, color: navy, size: 24),
            ),
            const SizedBox(width: 10),
            const Text('QANOT', style: TextStyle(
              fontWeight: FontWeight.w900, letterSpacing: 2,
            )),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Bildirishnomalar',
            onPressed: openUssd,
            icon: const Icon(Icons.dialpad_rounded),
          ),
        ],
      ),
      body: SafeArea(child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: pages[tab],
      )),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0B1B2E),
        indicatorColor: cyan.withOpacity(.16),
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Bosh sahifa'),
          NavigationDestination(icon: Icon(Icons.sim_card_rounded), label: 'Operatorlar'),
          NavigationDestination(icon: Icon(Icons.local_offer_outlined), label: 'Tariflar'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
        ],
      ),
    );
  }

  Widget homePage() => ListView(
    key: const ValueKey('home'),
    padding: const EdgeInsets.all(18),
    children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF123B5A), Color(0xFF1D3564), Color(0xFF312B70)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: cyan.withOpacity(.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ALOQANGIZ — BIR JOYDA',
              style: TextStyle(color: cyan, fontSize: 11, letterSpacing: 1.5,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Mobil hayotingizni\noson boshqaring',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, height: 1.15)),
            const SizedBox(height: 12),
            const Text('Operatorlar, tariflar va xizmatlar — QANOT bilan.',
              style: TextStyle(color: Color(0xFFD0DDED))),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: showAddNumber,
              icon: const Icon(Icons.add),
              label: Text(phone.isEmpty ? 'Raqam qo‘shish' : 'Raqamni boshqarish'),
              style: FilledButton.styleFrom(
                backgroundColor: cyan, foregroundColor: navy,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const SectionTitle('Tezkor xizmatlar'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: QuickAction(
          icon: Icons.account_balance_wallet_outlined, title: 'Balans',
          subtitle: 'Integratsiya kerak',
          onTap: () => info('Balansni real tekshirish operator API ruxsati bilan ulanadi.'),
        )),
        const SizedBox(width: 12),
        Expanded(child: QuickAction(
          icon: Icons.wifi_rounded, title: 'Internet',
          subtitle: 'Paketlar',
          onTap: () => setState(() => tab = 2),
        )),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: QuickAction(
          icon: Icons.dialpad_rounded, title: 'USSD-kodlar',
          subtitle: 'Saqlash va terish', onTap: openUssd,
        )),
        const SizedBox(width: 12),
        Expanded(child: QuickAction(
          icon: Icons.payments_outlined, title: 'To‘lovlar',
          subtitle: 'Rasmiy hamkor kerak',
          onTap: () => info('To‘lovni ulash uchun rasmiy to‘lov provayderi bilan shartnoma va API kerak.'),
        )),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: QuickAction(
          icon: Icons.receipt_long_outlined, title: 'Tariflar',
          subtitle: 'Katalog', onTap: () => setState(() => tab = 2),
        )),
        const SizedBox(width: 12),
        Expanded(child: QuickAction(
          icon: Icons.support_agent, title: 'Yordam',
          subtitle: 'Ma’lumot', onTap: () => info('QANOT yordam: operator hisobiga bevosita ulanish va to‘lovlar uchun rasmiy integratsiya talab qilinadi.'),
        )),
      ]),
      const SizedBox(height: 24),
      const SectionTitle('Operatorlar'),
      const SizedBox(height: 12),
      ...operators.map((o) => OperatorTile(
        operator: o,
        onTap: () {
          setState(() {
            selectedOperator = o.name;
            tab = 1;
          });
        },
      )),
      const SizedBox(height: 18),
      const PrototypeNote(),
    ],
  );

  Widget operatorsPage() => ListView(
    key: const ValueKey('operators'),
    padding: const EdgeInsets.all(18),
    children: [
      const Text('Operatorlar', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      const Text('Operatorni tanlang va telefon raqamingizni ushbu qurilmada saqlang.',
        style: TextStyle(color: muted)),
      const SizedBox(height: 18),
      ...operators.map((o) => OperatorTile(
        operator: o,
        selected: selectedOperator == o.name,
        onTap: () => setState(() => selectedOperator = o.name),
      )),
      if (selectedOperator != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$selectedOperator tanlandi',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(phone.isEmpty ? 'Raqamingizni ulash uchun pastdagi tugmani bosing.' : 'Ulangan raqam: $phone',
              style: const TextStyle(color: muted)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: showAddNumber,
              icon: const Icon(Icons.add_call),
              label: const Text('Raqamni ulash'),
            ),
          ]),
        ),
      ],
      const SizedBox(height: 16),
      const PrototypeNote(),
    ],
  );

  Widget tariffsPage() => ListView(
    key: const ValueKey('tariffs'),
    padding: const EdgeInsets.all(18),
    children: [
      const Text('Tariflar va paketlar',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      const Text('Tariflarning nomi, narxi va amal qilish shartlarini rasmiy manbadan tekshirmasdan ko‘rsatmaymiz. Katalogga tasdiqlangan ma’lumotlar keyingi bosqichda ulanadi.',
        style: TextStyle(color: muted)),
      const SizedBox(height: 18),
      const PlanCard(name: 'Internet paketlari', detail: 'Operator bo‘yicha GB paketlarini ko‘rish', icon: Icons.wifi),
      const PlanCard(name: 'Daqiqalar', detail: 'Qo‘ng‘iroq paketlari va limitlar', icon: Icons.call_outlined),
      const PlanCard(name: 'SMS paketlari', detail: 'Mavjud SMS takliflarini solishtirish', icon: Icons.sms_outlined),
      const PlanCard(name: 'Oylik tariflar', detail: 'Narx, internet va daqiqalarni taqqoslash', icon: Icons.calendar_month_outlined),
      const SizedBox(height: 12),
      const PrototypeNote(),
    ],
  );

  Widget profilePage() => ListView(
    key: const ValueKey('profile'),
    padding: const EdgeInsets.all(18),
    children: [
      const Text('Profil', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          const CircleAvatar(radius: 28, backgroundColor: Color(0xFF1D4562),
            child: Icon(Icons.person, color: cyan, size: 30)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('QANOT foydalanuvchisi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(phone.isEmpty ? 'Hali raqam ulanmagan' : phone,
              style: const TextStyle(color: muted)),
          ])),
        ]),
      ),
      const SizedBox(height: 12),
      ProfileRow(icon: Icons.sim_card_outlined, title: 'Raqamlarim', onTap: showAddNumber),
      ProfileRow(icon: Icons.dialpad_rounded, title: 'USSD-kodlarim', onTap: openUssd),
      ProfileRow(icon: Icons.history, title: 'To‘lovlar tarixi', onTap: () => info('To‘lov tarixi faqat rasmiy to‘lov integratsiyasi va server sozlangandan keyin ishlaydi.')),
      ProfileRow(icon: Icons.security_outlined, title: 'Xavfsizlik', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PinSettingsScreen()))),
      ProfileRow(icon: Icons.support_agent, title: 'Yordam markazi', onTap: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('QANOT yordam'), content: const Text('Muammo bo‘lsa, operatoringizning rasmiy qo‘llab-quvvatlash xizmatiga murojaat qiling. QANOT hozircha operator hisoblariga bevosita ulanmagan.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Yopish'))]))),
      const SizedBox(height: 16),
      const PrototypeNote(),
    ],
  );

  void info(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Text(title,
    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800));
}

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const QuickAction({super.key, required this.icon, required this.title,
    required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: cyan, size: 25),
        const SizedBox(height: 15),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 11)),
      ]),
    ),
  );
}

class OperatorTile extends StatelessWidget {
  final Operator operator;
  final VoidCallback onTap;
  final bool selected;
  const OperatorTile({super.key, required this.operator, required this.onTap, this.selected = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: selected ? const Color(0xFF17324B) : panel,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: operator.color.withOpacity(.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.cell_tower_rounded, color: operator.color),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(operator.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 3),
              Text(operator.subtitle, style: const TextStyle(color: muted, fontSize: 12)),
            ])),
            Icon(selected ? Icons.check_circle : Icons.chevron_right,
              color: selected ? cyan : muted),
          ]),
        ),
      ),
    ),
  );
}

class PlanCard extends StatelessWidget {
  final String name;
  final String detail;
  final IconData icon;
  const PlanCard({super.key, required this.name, required this.detail, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18)),
    child: Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: cyan.withOpacity(.12), borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: cyan),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(detail, style: const TextStyle(color: muted, fontSize: 12)),
      ])),
      const Icon(Icons.chevron_right, color: muted),
    ]),
  );
}

class ProfileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const ProfileRow({super.key, required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    leading: Icon(icon, color: cyan),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right, color: muted),
  );
}

class PrototypeNote extends StatelessWidget {
  const PrototypeNote({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF182A3D),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(.07)),
    ),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline, color: cyan, size: 20),
      SizedBox(width: 10),
      Expanded(child: Text(
        'QANOT hozirda raqamni qurilmada saqlash va foydalanuvchi kiritgan USSD-kodlarni boshqarishni qo‘llab-quvvatlaydi. Haqiqiy balans, SMS tasdiqlash, tariflar va to‘lovlar uchun tasdiqlangan ma’lumot manbalari hamda rasmiy integratsiyalar kerak.',
        style: TextStyle(color: Color(0xFFC4D1E0), fontSize: 12, height: 1.4),
      )),
    ]),
  );
}
