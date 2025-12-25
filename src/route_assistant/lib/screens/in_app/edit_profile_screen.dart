import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final String? initialUsername;

  const EditProfileScreen({super.key, this.initialUsername});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _client = Supabase.instance.client;

  late final TextEditingController _usernameCtrl;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.initialUsername ?? '');
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  bool _isValidUsername(String s) {
    // 3-30 karakter, harf/rakam/._  (senin eski reg ile uyumlu)
    final reg = RegExp(r'^[A-Za-z0-9_.]{3,30}$');
    return reg.hasMatch(s);
  }

  Future<void> _save() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      setState(() => _error = 'Oturum yok.');
      return;
    }

    final newName = _usernameCtrl.text.trim();

    if (!_isValidUsername(newName)) {
      setState(() {
        _error =
            'Kullanıcı adı 3-30 karakter olmalı ve sadece harf, rakam, _ . içermeli.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // ✅ UPDATE profiles.username
      await _client
          .from('profiles')
          .update({'username': newName})
          .eq('id', user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı adı güncellendi!')),
      );

      // ✅ ProfileScreen’e "değişti" diye dön
      Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      setState(() {
        _error = e.message.isNotEmpty ? e.message : 'Veritabanı hatası.';
      });
    } catch (e) {
      setState(() => _error = 'Hata: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profili Düzenle')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Kullanıcı Adı', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameCtrl,
            textInputAction: TextInputAction.done,
            enabled: !_saving,
            decoration: const InputDecoration(
              hintText: 'örn: erkan_48',
              prefixText: '@ ',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 10),

          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
          ],

          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
          ),

          const SizedBox(height: 12),
          Text(
            'Kural: 3-30 karakter, sadece A-Z a-z 0-9 _ .',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
