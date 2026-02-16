import 'package:flutter/material.dart';

class loginScreen extends StatefulWidget {
  const loginScreen({super.key});

  @override
  State<loginScreen> createState() => _loginScreenState();
}

class _loginScreenState extends State<loginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,

        title: const Text(
          "ShadowCV",

          style: TextStyle(
            fontSize: 25,
            fontFamily: 'Federant',
            color: const Color.fromARGB(255, 6, 1, 63),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Icon(
          Icons.supervised_user_circle_outlined,
          size: 40,
          color: const Color.fromARGB(255, 6, 1, 63),
          // actionsPadding: EdgeInsets.only(left: 10),
        ),
      ),
      backgroundColor: Colors.blueGrey,
      body: Stack(
        children: [
          Positioned(
            top: 40,
            left: 110,
            height: 190,
            width: 190,

            child: Image.asset('assets/images/ShadowCV-Logo.png'),
          ),
          Positioned(
            top: 230,
            left: 80,

            child: Text(
              'Welcome to ShadowCV!',
              style: TextStyle(
                fontSize: 25,
                color: const Color.fromARGB(255, 6, 1, 63),
                fontFamily: 'Federant',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: 350,
            left: 30,
            width: 360,

            child: TextField(
              decoration: InputDecoration(
                hintText: 'Enter your email',
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                icon: Icon(
                  Icons.email_outlined,
                  color: const Color.fromARGB(255, 6, 1, 63),
                ),
                hintStyle: TextStyle(
                  color: const Color.fromARGB(255, 6, 1, 63),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),

                  borderSide: BorderSide(
                    color: const Color.fromARGB(255, 6, 1, 63),
                    width: 4,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 440,
            left: 30,
            width: 360,

            child: TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter your password',
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                icon: Icon(
                  Icons.lock_outline,
                  color: const Color.fromARGB(255, 6, 1, 63),
                ),
                hintStyle: TextStyle(
                  color: const Color.fromARGB(255, 6, 1, 63),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),

                  borderSide: BorderSide(
                    color: const Color.fromARGB(255, 6, 1, 63),
                    width: 4,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 550,
            left: 30,
            width: 360,

            child: ElevatedButton(
              onPressed: () {
                // Handle login logic here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 6, 1, 63),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(vertical: 20),
              ),
              child: Text(
                'Login',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontFamily: 'Federant',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            top: 630,
            left: 150,
            child: InkWell(
              onTap: () {},
              child: const Text(
                "Forgot Password?",
                style: TextStyle(
                  color: const Color.fromARGB(255, 6, 1, 63),
                  fontFamily: 'Federant',
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          Positioned(
            top: 670,
            left: 120,
            width: 60,
            height: 60,
            child: InkWell(
              onTap: () {},
              child: Image.asset('assets/images/google1.png'),
            ),
          ),
          Positioned(
            top: 665,
            left: 220,
            width: 95,
            height: 95,
            child: InkWell(
              onTap: () {},
              child: Image.asset('assets/images/facebook.png'),
            ),
          ),
          Positioned(
            top: 745,
            left: 107,
            child: InkWell(
              onTap: () {
                // Handle sign up logic here
              },
              child: Text(
                "Don't have an account? Sign Up",
                style: TextStyle(
                  color: const Color.fromARGB(255, 6, 1, 63),
                  fontFamily: 'Federant',
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          Positioned(
            top: 690,
            left: 197,
            child: Text(
              'or',
              style: TextStyle(
                color: const Color.fromARGB(255, 6, 1, 63),
                fontFamily: 'Federant',
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
