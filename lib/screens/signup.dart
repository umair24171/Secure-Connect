import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:secureconnect/controllers/userprovider.dart';
import 'package:secureconnect/models/usermodel.dart';
import 'package:secureconnect/screens/login.dart';

class Signup extends StatelessWidget {
  Signup({super.key, required this.selectedAge});
  final String selectedAge;

  final String fontFamily = 'Roboto';
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController pass = TextEditingController();

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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height,
              ),
              child: Container(
                color: const Color(0xffffffff),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: size.height * 0.35,
                          decoration: const BoxDecoration(
                            color: Color(0xff66C7F4),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(250),
                              bottomRight: Radius.circular(250),
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: EdgeInsets.only(top: size.height * 0.05),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/person.png',
                                    height: size.height * 0.1,
                                  ),
                                  Text(
                                    'Signup',
                                    style: TextStyle(
                                      color: const Color(0xffffffff),
                                      fontFamily: fontFamily,
                                      fontSize: size.width * 0.07,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.07),
                          child: Column(
                            children: [
                              SizedBox(height: size.height * 0.04),
                              _buildTextField(
                                controller: name,
                                hintText: 'Name',
                                prefixIcon: Icons.person,
                              ),
                              SizedBox(height: size.height * 0.02),
                              _buildTextField(
                                controller: phone,
                                hintText: 'Phone number',
                                prefixIcon: Icons.phone,
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: size.height * 0.02),
                              _buildTextField(
                                controller: email,
                                hintText: 'Email',
                                prefixIcon: Icons.email_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              SizedBox(height: size.height * 0.02),
                              Consumer<UserProvider>(
                                builder: (context,userpro,_) {
                                  return _buildTextField(
                                    controller: pass,
                                    hintText: 'Password',
                                    prefixIcon: Icons.lock_rounded,
                                    suffixIcon: Icons.visibility_off,
                                    isPassword: userpro.isPassVisible,
                                  );
                                }
                              ),
                              SizedBox(height: size.height * 0.03),
                              _buildButton(
                                text: 'Sign up',
                                color: const Color(0xff004FB9),
                                onPressed: userPro.isLoading
                                    ? null
                                    : () async {
                                        final success = await userPro.signup(
                                          email: email.text,
                                          password: pass.text,
                                          userName: name.text,
                                          phoneNumber: phone.text,
                                          age:
                                              selectedAge, // Add the age parameter
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
                              SizedBox(height: size.height * 0.02),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: fontFamily,
                                    fontSize: size.width * 0.035,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  children: const [
                                    TextSpan(
                                        text:
                                            'By signing up you agree to our '),
                                    TextSpan(
                                      text: 'Terms of Services',
                                      style: TextStyle(
                                        color: Color(0xff66C7F4),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: Color(0xff66C7F4),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: size.height * 0.02,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: size.width * 0.07),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: fontFamily,
                                fontSize: size.width * 0.037,
                                fontWeight: FontWeight.w400,
                              ),
                              children: const [
                                TextSpan(text: 'Already have an account? '),
                                TextSpan(
                                  text: 'Sign in',
                                  style: TextStyle(
                                    color: Color(0xff66C7F4),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (userPro.isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: SpinKitThreeBounce(
                  color: Color(0xff66C7F4),
                ),
              ),
            ),
        ],
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
            borderRadius: BorderRadius.circular(20),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
    bool isPassword = false,
    TextInputType? keyboardType,
    // bool? isPasVisible
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
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
}
