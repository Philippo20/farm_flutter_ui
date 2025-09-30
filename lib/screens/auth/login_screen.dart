// Login screen
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../onboarding/introduction_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _isDark = false; 

Color get background => _isDark ? AppColors.darkBackground : AppColors.background;
Color get card => _isDark ? AppColors.darkCard : AppColors.card;
Color get text => _isDark ? AppColors.darkText : AppColors.text;

  void _login() async {
  setState(() {
    _loading = true;
    _error = null;
  });
  // TODO: Replace this with real login logic

  await Future.delayed(Duration(seconds: 4));

  setState(() {
    _loading = false;
  });

  // On successful login, navigate to onboarding
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => OnboardingScreen(isDark: _isDark)),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: Text(""),
        actions: [
          Row(
            children: [
              Icon(_isDark ? Icons.dark_mode : Icons.light_mode, color: AppColors.primary),
              Switch(
                value: _isDark,
                onChanged: (v) => setState(() => _isDark = v),
                activeColor: AppColors.primary,
              ),
              SizedBox(width: 12),
            ],
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: 370),
            width: MediaQuery.of(context).size.width * 0.98,
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 34.0),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  _isDark ? 'assets/logos/logo_white.png' : 'assets/logos/logo_black.png',
                  height: 54,
                  width: 54,
                  fit: BoxFit.contain,
                ),

                SizedBox(height: 32),
                Text(
                  "AI Dashboard",
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 7),
                Text(
                  "Growing the Future of Agriculture",
                  style: GoogleFonts.roboto(
                    color: text.withOpacity(0.82),
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 28),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: text.withOpacity(0.25), width: 1.2),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: text.withOpacity(0.18), width: 1.1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary, width: 2.1),
                    ),
                    labelStyle: TextStyle(color: text.withOpacity(0.7)),
                    contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 0),
                  ),
                  style: GoogleFonts.roboto(fontSize: 15, color: text),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: text.withOpacity(0.25), width: 1.2),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: text.withOpacity(0.18), width: 1.1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary, width: 2.1),
                    ),
                    labelStyle: TextStyle(color: text.withOpacity(0.7)),
                    contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 0),
                  ),
                  style: GoogleFonts.roboto(fontSize: 15, color: text),
                  obscureText: true,
                ),
                SizedBox(height: 25),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: 0.1,
                      ),
                    ),
                    child: _loading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text("Login"),
                  ),
                ),
                SizedBox(height: 13),
                TextButton(
                  onPressed: () {},
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.hovered) ||
                            states.contains(WidgetState.pressed) ||
                            states.contains(WidgetState.focused)) {
                          return AppColors.primary;
                        }
                        return _isDark ? AppColors.darkText : Colors.black;
                      },
                    ),
                    textStyle: WidgetStateProperty.all(
                      GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                  child: Text("Forgot Password?"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}
