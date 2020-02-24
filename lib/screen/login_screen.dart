import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, AuthResult;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flt_keep/styles.dart';

/// Login screen.
class LoginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

/// State for [LoginScreen].
class _LoginScreenState extends State<LoginScreen> {
  final _loginForm = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loggingIn = false;
  String _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Theme(
      data: ThemeData(primarySwatch: kAccentColorLight).copyWith(
        buttonTheme: ButtonTheme.of(context).copyWith(
          buttonColor: kAccentColorLight,
        ),
      ),
      child: Container(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 560,
            ),
            padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 48),
            child: Form(
              key: _loginForm,
              child: Column(
                children: <Widget>[
                  Image.asset('assets/images/thumbtack_intro.png'),
                  const SizedBox(height: 32),
                  const Text('Capture anything',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeights.medium,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                    ),
                    validator: (value) => value.isEmpty ? 'Please input your email' : null,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      hintText: 'Password',
                    ),
                    validator: (value) => value.isEmpty ? 'Please input your password' : null,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _buildLoginButton(),
                        if (_loggingIn) const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                  if (_errorMessage != null) _buildLoginMessage(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildLoginButton() => RaisedButton(
    // color: kHighlightColorLight,
    onPressed: _onSubmit,
    child: const Text('Login / Sign up',
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
    ),
  );

  Widget _buildLoginMessage() => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 18),
    child: Text(_errorMessage,
      style: const TextStyle(
        fontSize: 14,
        color: kErrorColorLight,
      ),
    ),
  );

  void _onSubmit() async {
    if (_loginForm.currentState?.validate() != true) return;

    FocusScope.of(context).unfocus();
    String errMsg;
    try {
      _setLoggingIn();
      final result = await _auth(_emailController.text, _passwordController.text);
      debugPrint('Login result: $result');
    } on PlatformException catch (e) {
      errMsg = e.message;
    } catch (e, s) {
      debugPrint('login failed: $e. $s');
      errMsg = 'Login failed, please try again later.';
    } finally {
      _setLoggingIn(false, errMsg);
    }
  }

  Future<AuthResult> _auth(String email, String password, {bool signUp = false}) => (signUp
    ? FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password)
    : FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password)
  ).catchError((e) {
    if (e is PlatformException && e.code == 'ERROR_USER_NOT_FOUND') {
      return _auth(email, password, signUp: true);
    } else {
      throw e;
    }
  });

  void _setLoggingIn([bool loggingIn = true, String errMsg]) {
    if (mounted) {
      setState(() {
        _loggingIn = loggingIn;
        _errorMessage = errMsg;
      });
    }
  }
}
