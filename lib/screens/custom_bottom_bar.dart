import 'package:flutter/material.dart';
import 'package:secureconnect/screens/calls.dart';
import 'package:secureconnect/screens/home.dart';
import 'package:secureconnect/screens/settings.dart';

class CustomBottomBar extends StatefulWidget {
  const CustomBottomBar({Key? key}) : super(key: key);

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  int _selectedIndex = 0;

  // List of screens to be displayed
  final List<Widget> _screens = [
    const Home(),     // Replace with your Home screen
    const Calls(),    // Replace with your Calls screen
    const Center(child: Text('Stats')),    // Replace with your Statistics screen
    Settings(), // Replace with your Settings screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIcon(0, Icons.home),
                _buildIcon(1, Icons.phone),
                _buildIcon(2, Icons.bar_chart),
                _buildIcon(3, Icons.settings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1FAAEA) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFF1FAAEA),
          size: 28,
        ),
      ),
    );
  }
}