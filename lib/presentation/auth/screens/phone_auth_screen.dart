import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_state_provider.dart';
import '../widgets/country_code.dart';
import 'otp_verification_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showCountryPicker(BuildContext context, AuthStateProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD2D2D7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Select Region',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: supportedCountryCodes.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: Color(0xFFF5F5F7),
                ),
                itemBuilder: (context, index) {
                  final country = supportedCountryCodes[index];
                  final isSelected = country == auth.selectedCountry;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(
                      country.name,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1D1D1F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+${country.dialCode}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF86868B),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            CupertinoIcons.check_mark,
                            size: 18,
                            color: Color(0xFF0071E3),
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      auth.selectCountry(country);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onContinue(AuthStateProvider auth) async {
    FocusScope.of(context).unfocus();
    final success = await auth.sendOtp(_phoneController.text);
    if (!mounted) return;

    if (success && auth.status == AuthFlowStatus.codeSent) {
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => const OtpVerificationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),
              const Text(
                'Sign in.',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your phone number to keep your safety network connected.',
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFF6E6E73),
                  height: 1.4,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 36),

              // Apple-style clean white card input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: auth.errorMessage != null
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFFE5E5EA),
                  ),
                ),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                      onTap: () => _showCountryPicker(context, auth),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            Text(
                              auth.selectedCountry.flag,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '+${auth.selectedCountry.dialCode}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1D1D1F),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              CupertinoIcons.chevron_down,
                              size: 14,
                              color: Color(0xFF86868B),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: const Color(0xFFE5E5EA),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        onChanged: (_) => auth.clearError(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1D1D1F),
                          letterSpacing: 0.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Phone number',
                          hintStyle: TextStyle(
                            color: Color(0xFFAEAEB2),
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (auth.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  auth.errorMessage!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFF3B30),
                  ),
                ),
              ],

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : () => _onContinue(auth),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0071E3),
                    disabledBackgroundColor: const Color(0xFF0071E3)
                        .withOpacity(0.4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: auth.isLoading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Standard SMS rates may apply.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF86868B)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
