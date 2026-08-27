import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _blue = Color(0xFF065BC8);
  static const _ink = Color(0xFF17171A);
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _signUp = false,
      _loading = false,
      _hidePassword = true,
      _hideConfirm = true;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_signUp) {
        await ApiService().signUp(
          _email.text.trim(),
          _password.text,
          fullName: _name.text,
        );
      } else {
        await ApiService().login(_email.text.trim(), _password.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _signUp
              ? 'Unable to create account. Check your details and try again.'
              : 'Invalid email or password. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleMode() => setState(() {
    _signUp = !_signUp;
    _error = null;
    _formKey.currentState?.reset();
  });

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: Color(0xFFD9DCE5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 22, 26, 25),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _WNovelMark(),
                        const SizedBox(height: 13),
                        Text(
                          _signUp ? 'Create an account' : 'Welcome back',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _signUp
                              ? 'Start translating your novels with AI'
                              : 'Sign in to continue your translations',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF555861),
                            fontSize: 12,
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 13),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFB3261E),
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        if (_signUp) ...[
                          _label('Full Name'),
                          const SizedBox(height: 5),
                          _field(
                            _name,
                            'Jane Doe',
                            icon: Icons.person_outline,
                            action: TextInputAction.next,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter your name.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _label('Email address'),
                        const SizedBox(height: 5),
                        _field(
                          _email,
                          'name@example.com',
                          icon: Icons.mail_outline,
                          keyboard: TextInputType.emailAddress,
                          action: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your email.';
                            }
                            if (!v.contains('@')) return 'Enter a valid email.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _label('Password'),
                            if (!_signUp)
                              GestureDetector(
                                onTap: () => ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Password recovery is not configured yet.',
                                        ),
                                      ),
                                    ),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(color: _blue, fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        _field(
                          _password,
                          '••••••••',
                          icon: Icons.lock_outline,
                          obscure: _hidePassword,
                          suffix: IconButton(
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 16,
                            ),
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                          ),
                          action: _signUp
                              ? TextInputAction.next
                              : TextInputAction.done,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your password.';
                            }
                            if (_signUp && v.length < 8) {
                              return 'Use at least 8 characters.';
                            }
                            return null;
                          },
                          onSubmitted: (_) {
                            if (!_signUp) _submit();
                          },
                        ),
                        if (_signUp) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Must be at least 8 characters.',
                            style: TextStyle(
                              color: Color(0xFF6D7078),
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _label('Confirm Password'),
                          const SizedBox(height: 5),
                          _field(
                            _confirm,
                            '••••••••',
                            icon: Icons.lock_outline,
                            obscure: _hideConfirm,
                            suffix: IconButton(
                              icon: Icon(
                                _hideConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 16,
                              ),
                              onPressed: () =>
                                  setState(() => _hideConfirm = !_hideConfirm),
                            ),
                            action: TextInputAction.done,
                            validator: (v) => v != _password.text
                                ? 'Passwords do not match.'
                                : null,
                            onSubmitted: (_) => _submit(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _blue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _signUp ? 'Create Account' : 'Sign In',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            const Expanded(child: Divider(height: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                              ),
                              child: Text(
                                _signUp
                                    ? 'Or sign up with'
                                    : 'Or continue with',
                                style: const TextStyle(
                                  color: Color(0xFF777A82),
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(height: 1)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _providerButton('Google', 'G'),
                            const SizedBox(width: 9),
                            _providerButton('GitHub', '◉'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _signUp
                                  ? 'Already have an account? '
                                  : 'Don’t have an account? ',
                              style: const TextStyle(
                                color: Color(0xFF777A82),
                                fontSize: 10,
                              ),
                            ),
                            GestureDetector(
                              onTap: _toggleMode,
                              child: Text(
                                _signUp ? 'Log in' : 'Sign up',
                                style: const TextStyle(
                                  color: _blue,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: _ink,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    ),
  );
  Widget _field(
    TextEditingController controller,
    String hint, {
    IconData? icon,
    Widget? suffix,
    bool obscure = false,
    TextInputType? keyboard,
    TextInputAction? action,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) => TextFormField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboard,
    textInputAction: action,
    onFieldSubmitted: onSubmitted,
    validator: validator,
    style: const TextStyle(fontSize: 11),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB2B5BD), fontSize: 10),
      prefixIcon: Icon(icon, size: 14, color: const Color(0xFF9A9DA6)),
      suffixIcon: suffix,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      border: _border(),
      enabledBorder: _border(),
      focusedBorder: _border(color: _blue),
      errorStyle: const TextStyle(fontSize: 9),
      errorBorder: _border(color: const Color(0xFFB3261E)),
    ),
  );
  OutlineInputBorder _border({Color color = const Color(0xFFD4D7DF)}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: color),
      );
  Widget _providerButton(String name, String glyph) => Expanded(
    child: OutlinedButton.icon(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name sign-in is not configured yet.')),
      ),
      icon: Text(
        glyph,
        style: TextStyle(
          color: name == 'Google' ? const Color(0xFF4285F4) : _ink,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      label: Text(name, style: const TextStyle(color: _ink, fontSize: 10)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(30),
        padding: EdgeInsets.zero,
        side: const BorderSide(color: Color(0xFFD4D7DF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
  );
}

class _WNovelMark extends StatelessWidget {
  const _WNovelMark();
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(1),
      ),
      child: const Icon(
        Icons.auto_stories_outlined,
        size: 25,
        color: Colors.black,
      ),
    ),
  );
}
