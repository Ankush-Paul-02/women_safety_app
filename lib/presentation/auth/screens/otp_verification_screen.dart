import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_state_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitOtp(AuthStateProvider auth, String code) async {
    if (code.length != 6) return;
    FocusScope.of(context).unfocus();
    final success = await auth.verifyOtp(code);
    if (success && mounted) {
      // Pop back to root; AuthGate in main.dart will switch to Home
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF1D1D1F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Verification.',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to ${auth.formattedPhone}.',
                style: const TextStyle(
                  fontSize: 17,
                  color: Color(0xFF6E6E73),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),

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
                child: TextField(
                  controller: _otpController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (value) {
                    auth.clearError();
                    if (value.length == 6) {
                      _submitOtp(auth, value);
                    }
                  },
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 12,
                    color: Color(0xFF1D1D1F),
                  ),
                  decoration: const InputDecoration(
                    hintText: '••••••',
                    hintStyle: TextStyle(
                      color: Color(0xFFD2D2D7),
                      letterSpacing: 12,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 18),
                  ),
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

              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: auth.canResend && !auth.isLoading
                      ? () => auth.resendOtp()
                      : null,
                  child: Text(
                    auth.canResend
                        ? 'Resend Code'
                        : 'Resend code in ${auth.resendSecondsRemaining}s',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: auth.canResend
                          ? const Color(0xFF0071E3)
                          : const Color(0xFF86868B),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () => _submitOtp(auth, _otpController.text),
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
                          'Verify',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
