import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, AuthResult, GoogleAuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignIn;

import 'package:flt_keep/styles.dart';

/// Login screen.
class LoginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

/// State for [LoginScreen].
class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  final _loginForm = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loggingIn = false;
  String _errorMessage;
  bool _useEmailSignIn = false;

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
          textTheme: ButtonTextTheme.primary,
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
                  if (_useEmailSignIn) ..._buildEmailSignInFields(),
                  if (!_useEmailSignIn) ..._buildGoogleSignInFields(),
                  if (_errorMessage != null) _buildLoginMessage(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> _buildGoogleSignInFields() => [
    RaisedButton(
      padding: const EdgeInsets.all(0),
      onPressed: _signInWithGoogle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset('assets/images/google.png', width: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40 / 1.618),
            child: const Text('Continue with Google'),
          ),
        ],
      ),
    ),
    FlatButton(
      child: Text('Sign in with email'),
      onPressed: () => setState(() {
        _useEmailSignIn = true;
      }),
    ),
    if (_loggingIn) Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(top: 12),
      child: const CircularProgressIndicator(),
    ),
  ];

  List<Widget> _buildEmailSignInFields() => [
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
    _buildEmailSignInButton(),
    if (_loggingIn) const LinearProgressIndicator(),
    FlatButton(
      child: Text('Use Google Sign In'),
      onPressed: () => setState(() {
        _useEmailSignIn = false;
      }),
    ),
  ];

  Widget _buildEmailSignInButton() => RaisedButton(
    onPressed: _signInWithEmail,
    child: Container(
      height: 40,
      alignment: Alignment.center,
      child: const Text('Sign in / Sign up'),
    ),
  );

  Widget _buildLoginMessage() => Container(
    alignment: Alignment.center,
    padding: const EdgeInsets.only(top: 18),
    child: Text(_errorMessage,
      style: const TextStyle(
        fontSize: 14,
        color: kErrorColorLight,
      ),
    ),
  );

  void _signInWithGoogle() async {
    _setLoggingIn();
    String errMsg;

    try {
      final googleUser = await _googleSignIn.signIn();
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.getCredential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      await _auth.signInWithCredential(credential);
    } catch (e, s) {
      debugPrint('google signIn failed: $e. $s');
      errMsg = 'Login failed, please try again later.';
    } finally {
      _setLoggingIn(false, errMsg);
    }
  }

  void _signInWithEmail() async {
    if (_loginForm.currentState?.validate() != true) return;

    FocusScope.of(context).unfocus();
    String errMsg;
    try {
      _setLoggingIn();
      final result = await _doEmailSignIn(_emailController.text, _passwordController.text);
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

  Future<AuthResult> _doEmailSignIn(String email, String password, {bool signUp = false}) => (signUp
    ? _auth.createUserWithEmailAndPassword(email: email, password: password)
    : _auth.signInWithEmailAndPassword(email: email, password: password)
  ).catchError((e) {
    if (e is PlatformException && e.code == 'ERROR_USER_NOT_FOUND') {
      return _doEmailSignIn(email, password, signUp: true);
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
