import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  String selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Profile'),
              subtitle: const Text('View or edit your profile'),
              onTap: () {
                // Navigate to profile editing screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              onTap: () {
                // Navigate to password changing screen
              },
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enable Dark Mode'),
              value: darkModeEnabled,
              onChanged: (bool value) {
                setState(() {
                  darkModeEnabled = value;
                  // Logic to apply dark mode
                });
              },
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Language Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: Text(selectedLanguage),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Select Language'),
                    content: SizedBox(
                      height: 150,
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('English'),
                            onTap: () {
                              setState(() {
                                selectedLanguage = 'English';
                              });
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text('Spanish'),
                            onTap: () {
                              setState(() {
                                selectedLanguage = 'Spanish';
                              });
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text('French'),
                            onTap: () {
                              setState(() {
                                selectedLanguage = 'French';
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Handle logout logic
                },
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
