import 'package:flutter/material.dart';
import 'team_code_service.dart';
import 'shared_quiz_screen.dart'; // <-- make sure this path is correct

class JoinTeamScreen extends StatefulWidget {
  final String userId;

  const JoinTeamScreen({super.key, required this.userId});

  @override
  State<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends State<JoinTeamScreen> {
  final TeamService _teamService = TeamService();
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  Future<void> _joinTeam() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a team code')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final success = await _teamService.joinTeam(code, widget.userId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined team successfully')),
        );

        // ✅ Navigate to real-time shared quiz screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SharedQuizScreen(
              teamCode: code,
              isHost: false, userId: '', // this is the joiner
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid team code')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Team')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter Team Code',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _joinTeam,
                    child: const Text('Join Team'),
                  ),
          ],
        ),
      ),
    );
  }
}
