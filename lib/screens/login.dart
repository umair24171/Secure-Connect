import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:secureconnect/controllers/userprovider.dart';
import 'package:secureconnect/screens/home.dart';
import 'package:secureconnect/screens/signup.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final String fontFamily = 'Roboto';
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  void _showErrorDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userPro = Provider.of<UserProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xff66C7F4),
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              color: const Color(0xff66C7F4),
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.07),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: size.height * 0.03),
                          SizedBox(
                            height: size.height * 0.08,
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: size.height * 0.09),
                          Text(
                            'Login',
                            style: TextStyle(
                              color: const Color(0xffffffff),
                              fontSize: size.width * 0.07,
                              fontFamily: fontFamily,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: size.height * 0.04),
                          _buildTextField(
                            controller: email,
                            hintText: 'Your email',
                            prefixIcon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: size.height * 0.02),
                          Consumer<UserProvider>(
                            builder: (context,userPro,_) {
                              return _buildTextField(
                                controller: password,
                                hintText: 'Password',
                                prefixIcon: Icons.lock_rounded,
                                suffixIcon: Icons.visibility_off,
                                isPassword: userPro.isPassVisible,
                              );
                            }
                          ),
                          SizedBox(height: size.height * 0.04),
                          _buildButton(
                            text: 'Login',
                            color: const Color(0xff004FB9),
                            onPressed: userPro.isLoading
                                ? null
                                : () async {
                                    final success = await userPro.signin(
                                      email: email.text,
                                      password: password.text,
                                      context: context,
                                    );

                                    if (!success &&
                                        context.mounted &&
                                        userPro.errorMessage != null) {
                                      _showErrorDialog(
                                          context, userPro.errorMessage!);
                                    }
                                  },
                          ),
                          SizedBox(height: size.height * 0.08),
                          _buildButton(
                            text: 'Continue without login',
                            color: const Color(0xff004095),
                            onPressed: userPro.isLoading
                                ? null
                                : () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Home()),
                                    );
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: size.height * 0.02),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Signup(
                                    selectedAge: '',
                                  )),
                        );
                      },
                      child: Text(
                        "Don't have an account? Sign up",
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontWeight: FontWeight.w400,
                          fontSize: size.width * 0.04,
                          color: const Color(0xffffffff),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (userPro.isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: SpinKitThreeBounce(
                  color: Color(0xffDFF6FF),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xff429AFF),
          fontFamily: fontFamily,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        fillColor: const Color(0xffDFF6FF),
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xff429AFF),
        ),
        suffixIcon: suffixIcon != null
            ? Consumer<UserProvider>(
              builder: (context,userPro,_) {
                return InkWell(
                  onTap: (){
                    if(userPro.isPassVisible){
                      userPro.setIsPassValue(false);
                    }else{
 userPro.setIsPassValue(true);
                    }
                  },
                  child: Icon(
                  userPro.isPassVisible?Icons.visibility   : Icons.visibility_off,
                      color: const Color(0xff429AFF),
                    ),
                );
              }
            )
            : null,
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: const Color(0xffffffff),
            fontFamily: fontFamily,
            fontSize: 19,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
