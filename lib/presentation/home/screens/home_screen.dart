import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/safety/entities/emergency_contact.dart';
import '../../auth/viewmodels/auth_state_provider.dart';
import '../viewmodels/home_state_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthStateProvider>().currentUser?.uid;
      if (uid != null) {
        context.read<HomeStateProvider>().bindUser(uid);
      }
    });
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  void _showKeywordDialog(HomeStateProvider home) {
    _keywordController.text = home.customKeyword;
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Custom Emergency Keyword'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: _keywordController,
            placeholder: 'e.g. Code Red',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Save'),
            onPressed: () {
              home.setCustomKeyword(_keywordController.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();
    final home = context.watch<HomeStateProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Safety.',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D1D1F),
            letterSpacing: -0.8,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(
              CupertinoIcons.square_arrow_right,
              color: Color(0xFF1D1D1F),
            ),
            onPressed: () async {
              await home.toggleVoiceSafety(false);
              await auth.signOut();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // 1. Monitoring Status & Voice Safety Activation Card
            _VoiceSafetyCard(
              isActive: home.isVoiceMonitoringActive,
              phrases: home.activePhrases,
              onToggle: home.toggleVoiceSafety,
              onEditKeyword: () => _showKeywordDialog(home),
            ),

            if (home.statusMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: Text(
                  home.statusMessage!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 2. Manual Emergency SOS Button
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: home.isTriggeringSos
                    ? null
                    : () => home.triggerSos(phrase: 'Manual SOS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B30),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: home.isTriggeringSos
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Icon(CupertinoIcons.exclamationmark_triangle_fill),
                label: Text(
                  home.isTriggeringSos ? 'Sending SOS...' : 'Trigger SOS Now',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // 3. Emergency Contacts Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D1F),
                    letterSpacing: -0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: home.pickAndAddContact,
                  icon: const Icon(
                    CupertinoIcons.add_circled_solid,
                    size: 20,
                    color: Color(0xFF0071E3),
                  ),
                  label: const Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0071E3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 4. Saved Contacts List
            if (home.contacts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Icon(
                      CupertinoIcons.person_2,
                      size: 36,
                      color: Color(0xFF86868B),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No emergency contacts yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap Add to choose trusted people from your phone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF6E6E73)),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: home.contacts.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 72,
                    color: Color(0xFFF5F5F7),
                  ),
                  itemBuilder: (_, index) {
                    final contact = home.contacts[index];
                    return _ContactTile(
                      contact: contact,
                      onRemove: () => home.removeContact(contact.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VoiceSafetyCard extends StatelessWidget {
  final bool isActive;
  final List<String> phrases;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEditKeyword;

  const _VoiceSafetyCard({
    required this.isActive,
    required this.phrases,
    required this.onToggle,
    required this.onEditKeyword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? const Color(0xFF34C759)
                      : const Color(0xFFAEAEB2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? 'Voice Monitoring Active' : 'Monitoring Inactive',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? const Color(0xFF248A3D)
                      : const Color(0xFF6E6E73),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activate Voice Safety',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Listens on-device for panic phrases. No audio is saved.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6E6E73)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CupertinoSwitch(
                value: isActive,
                activeTrackColor: const Color(0xFF0071E3),
                onChanged: onToggle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF5F5F7)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: phrases
                      .map(
                        (p) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '"$p"',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              TextButton(
                onPressed: onEditKeyword,
                child: const Text(
                  'Keyword',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0071E3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onRemove;

  const _ContactTile({required this.contact, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final initials = contact.name.isNotEmpty
        ? contact.name
              .trim()
              .split(' ')
              .map((e) => e[0])
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFF5F5F7),
        backgroundImage: contact.photoBase64 != null
            ? MemoryImage(base64Decode(contact.photoBase64!))
            : null,
        child: contact.photoBase64 == null
            ? Text(
                initials,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              )
            : null,
      ),
      title: Text(
        contact.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1D1D1F),
        ),
      ),
      subtitle: Text(
        contact.phoneNumber,
        style: const TextStyle(fontSize: 14, color: Color(0xFF6E6E73)),
      ),
      trailing: IconButton(
        icon: const Icon(
          CupertinoIcons.minus_circle_fill,
          color: Color(0xFFFF3B30),
          size: 22,
        ),
        onPressed: onRemove,
      ),
    );
  }
}
