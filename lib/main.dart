import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/contact.dart';
import 'data/education.dart';
import 'data/experience.dart';
import 'data/personal_info.dart';
import 'data/skills.dart';
import 'models/family_member.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'widgets/member_photo.dart';

void main() => runApp(const CvApp());

class CvApp extends StatelessWidget {
  const CvApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CV Bella',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const LoginScreen(),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    _api.close();
    super.dispose();
  }

  final _api = ApiService();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.login(_user.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRegistration() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const RegisterScreen()),
    );
    if (!mounted || email == null) return;
    setState(() {
      _user.text = email;
      _password.clear();
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compte créé. Vous pouvez maintenant vous connecter.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xfff4f7fa), Color(0xffe7eef6)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 22,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppTheme.ink, Color(0xff28567f)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 34,
                                backgroundColor: Color(0xffdce8f3),
                                child: Icon(
                                  Icons.person_outline,
                                  size: 36,
                                  color: AppTheme.ink,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                "Bienvenue",
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Espace personnel",
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: const Color(0xffdce8f3),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: .4,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Connectez-vous pour d\u00E9couvrir mon univers",
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _user,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Adresse e-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Saisissez une adresse e-mail valide.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _hidden,
                          onFieldSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _hidden
                                  ? 'Afficher le mot de passe'
                                  : 'Masquer le mot de passe',
                              onPressed: () =>
                                  setState(() => _hidden = !_hidden),
                              icon: Icon(
                                _hidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Saisissez votre mot de passe.'
                              : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _loading ? null : _login,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward),
                          label: Text(_loading ? 'Connexion…' : 'Se connecter'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loading ? null : _openRegistration,
                          child: const Text('Créer un compte'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _api = ApiService();
  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.register(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pop(_email.text.trim());
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Créer un compte')),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xfff4f7fa), Color(0xffe7eef6)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundColor: Color(0xffe7eef6),
                          child: Icon(
                            Icons.person_add_alt_1,
                            size: 32,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Rejoindre votre espace',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Créez vos identifiants pour accéder à l’application.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newUsername],
                          decoration: const InputDecoration(
                            labelText: 'Adresse e-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty ||
                                !email.contains('@') ||
                                !email.contains('.') ||
                                email.length > 100) {
                              return 'Saisissez une adresse e-mail valide.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            helperText: '6 caractères minimum',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _hidePassword
                                  ? 'Afficher le mot de passe'
                                  : 'Masquer le mot de passe',
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => (value?.length ?? 0) < 6
                              ? 'Le mot de passe doit contenir au moins 6 caractères.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmation,
                          obscureText: _hideConfirmation,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _register(),
                          decoration: InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _hideConfirmation
                                  ? 'Afficher le mot de passe'
                                  : 'Masquer le mot de passe',
                              onPressed: () => setState(
                                () => _hideConfirmation = !_hideConfirmation,
                              ),
                              icon: Icon(
                                _hideConfirmation
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => value != _password.text
                              ? 'Les mots de passe ne correspondent pas.'
                              : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _loading ? null : _register,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.person_add_alt_1),
                          label: Text(
                            _loading ? 'Création…' : 'Créer mon compte',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _pages = const [
    HomeScreen(),
    CvScreen(),
    FamilyScreen(),
    ContactScreen(),
  ];
  final _titles = const ['Accueil', 'Mon CV', 'Ma famille', 'Contact'];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wideLayout = constraints.maxWidth >= 900;
      final extendedRail = constraints.maxWidth >= 1200;
      void selectPage(int index) => setState(() => _index = index);
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 76,
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xffdce8f3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  [
                    Icons.home_rounded,
                    Icons.badge_rounded,
                    Icons.family_restroom_rounded,
                    Icons.mail_rounded,
                  ][_index],
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_titles[_index]),
                  Text(
                    'CV • Bella',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.muted,
                      letterSpacing: .3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: const Border(bottom: BorderSide(color: Color(0xffe8eef5))),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton.filledTonal(
                tooltip: 'Se déconnecter',
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                  (_) => false,
                ),
                icon: const Icon(Icons.logout_rounded),
              ),
            ),
          ],
        ),
        body: Row(
          children: [
            if (wideLayout)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 0, 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xffe8eef5)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.ink.withValues(alpha: .08),
                        blurRadius: 22,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.ink, AppTheme.blue],
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              if (extendedRail) ...[
                                const SizedBox(width: 12),
                                const Text(
                                  'MON ESPACE',
                                  style: TextStyle(
                                    color: AppTheme.ink,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Divider(height: 1, indent: 14, endIndent: 14),
                        Expanded(
                          child: NavigationRail(
                            extended: extendedRail,
                            selectedIndex: _index,
                            onDestinationSelected: selectPage,
                            labelType: extendedRail
                                ? null
                                : NavigationRailLabelType.all,
                            groupAlignment: -0.72,
                            minWidth: 76,
                            minExtendedWidth: 220,
                            backgroundColor: Colors.transparent,
                            indicatorColor: const Color(0xffdce8f3),
                            destinations: const [
                              NavigationRailDestination(
                                icon: Icon(Icons.home_outlined),
                                selectedIcon: Icon(Icons.home_rounded),
                                label: Text('Accueil'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.badge_outlined),
                                selectedIcon: Icon(Icons.badge_rounded),
                                label: Text('Mon CV'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.family_restroom_outlined),
                                selectedIcon: Icon(
                                  Icons.family_restroom_rounded,
                                ),
                                label: Text('Famille'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.mail_outline_rounded),
                                selectedIcon: Icon(Icons.mail_rounded),
                                label: Text('Contact'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: _pages[_index],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: wideLayout
            ? null
            : SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Material(
                  color: Colors.white,
                  elevation: 12,
                  shadowColor: AppTheme.ink.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(28),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: NavigationBar(
                      height: 70,
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.onlyShowSelected,
                      indicatorShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      selectedIndex: _index,
                      onDestinationSelected: selectPage,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home_rounded),
                          label: 'Accueil',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.badge_outlined),
                          selectedIcon: Icon(Icons.badge_rounded),
                          label: 'Mon CV',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.family_restroom_outlined),
                          selectedIcon: Icon(Icons.family_restroom_rounded),
                          label: 'Famille',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.mail_outline_rounded),
                          selectedIcon: Icon(Icons.mail_rounded),
                          label: 'Contact',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      );
    },
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.ink, Color(0xff28567f)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xffd8e7f4),
              child: Icon(Icons.person, size: 42, color: AppTheme.ink),
            ),
            const SizedBox(height: 18),
            Text(
              personName,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              personTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: const Color(0xffb7cde2)),
            ),
            const SizedBox(height: 16),
            Text(
              personSummary,
              style: const TextStyle(color: Colors.white, height: 1.5),
            ),
            const SizedBox(height: 18),
            const Text(
              '« Apprendre, créer et contribuer avec intention. »',
              style: TextStyle(
                color: Color(0xffd8e7f4),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const SectionHeading(
        'En quelques mots',
        icon: Icons.auto_awesome_outlined,
      ),
      InfoCard(
        icon: Icons.school_outlined,
        title: 'Formation',
        subtitle: educationItems.first.degree,
      ),
      const InfoCard(
        icon: Icons.code,
        title: 'Domaine',
        subtitle: 'Développement logiciel • applications mobiles',
      ),
      const InfoCard(
        icon: Icons.place_outlined,
        title: 'Localisation',
        subtitle: contactLocation,
      ),
    ],
  );
}

class CvScreen extends StatelessWidget {
  const CvScreen({super.key});
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const SectionHeading('Formation', icon: Icons.school_outlined),
      for (final item in educationItems)
        TimelineCard(
          title: item.degree,
          subtitle: '${item.institution} • ${item.years}',
          body: item.description,
          icon: Icons.school_outlined,
        ),
      const SizedBox(height: 12),
      const SectionHeading('Expériences & projets', icon: Icons.work_outline),
      for (final item in experienceItems)
        TimelineCard(
          title: item.title,
          subtitle: '${item.organization} • ${item.period}',
          body: item.description,
          icon: Icons.work_outline,
        ),
      const SizedBox(height: 12),
      const SectionHeading('Compétences techniques', icon: Icons.code),
      for (final skill in technicalSkills) SkillTile(skill: skill),
      const SizedBox(height: 12),
      const SectionHeading('Langues', icon: Icons.translate),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: languageSkills.map((s) => Chip(label: Text(s))).toList(),
      ),
      const SizedBox(height: 12),
      const SectionHeading('Centres d’intérêt', icon: Icons.favorite_border),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: interestItems
            .map(
              (s) => Chip(avatar: Icon(s.icon, size: 18), label: Text(s.label)),
            )
            .toList(),
      ),
    ],
  );
}

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});
  @override
  Widget build(BuildContext context) => const _FamilyScreenBody();
}

class _FamilyScreenBody extends StatefulWidget {
  const _FamilyScreenBody();
  @override
  State<_FamilyScreenBody> createState() => _FamilyScreenBodyState();
}

class _FamilyScreenBodyState extends State<_FamilyScreenBody> {
  final _api = ApiService();
  late Future<List<FamilyMember>> _members;

  @override
  void initState() {
    super.initState();
    _members = _api.getFamilyMembers();
  }

  void _reload() {
    setState(() {
      _members = _api.getFamilyMembers();
    });
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editMember([FamilyMember? member]) async {
    final result = await showDialog<(FamilyMember, XFile?)>(
      context: context,
      builder: (_) => _FamilyMemberDialog(member: member),
    );
    if (result == null || !mounted) return;
    try {
      if (member == null) {
        await _api.createFamilyMember(result.$1, image: result.$2);
      } else {
        await _api.updateFamilyMember(result.$1, image: result.$2);
      }
      if (!mounted) return;
      _reload();
      _message(member == null ? 'Membre ajouté.' : 'Membre modifié.');
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _deleteMember(FamilyMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce membre ?'),
        content: Text(
          'Voulez-vous supprimer ${member.name} ? Cette action sera enregistrée sur le serveur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _api.deleteFamilyMember(member.id);
      if (mounted) {
        _reload();
        _message('Membre supprimé.');
      }
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<FamilyMember>>(
    future: _members,
    builder: (context, snapshot) {
      final children = <Widget>[
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Les personnes qui comptent',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Text(
                    'Membres de famille enregistrés dans votre espace.',
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Actualiser',
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _editMember(),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Ajouter un membre'),
          ),
        ),
        const SizedBox(height: 12),
      ];
      if (snapshot.connectionState == ConnectionState.waiting) {
        children.add(
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      } else if (snapshot.hasError) {
        children.add(
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_off),
              title: const Text('Impossible de charger la famille'),
              subtitle: Text('${snapshot.error}'),
              trailing: IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
            ),
          ),
        );
      } else if (snapshot.data!.isEmpty) {
        children.add(
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Aucun membre enregistré. Ajoutez le premier membre de votre famille.',
                ),
              ),
            ),
          ),
        );
      } else {
        children.add(
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 820
                  ? 3
                  : constraints.maxWidth >= 520
                  ? 2
                  : 1;
              final spacing = 14.0;
              final cardWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: snapshot.data!.map((member) {
                  return SizedBox(
                    width: cardWidth,
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        leading: member.imageUrl == null
                            ? CircleAvatar(
                                backgroundColor: const Color(0xffe7eef6),
                                child: Text(
                                  member.initials,
                                  style: const TextStyle(
                                    color: AppTheme.ink,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : MemberPhoto(
                                url: member.imageUrl!,
                                size: 48,
                                placeholder: CircleAvatar(
                                  backgroundColor: const Color(0xffe7eef6),
                                  child: Text(
                                    member.initials,
                                    style: const TextStyle(
                                      color: AppTheme.ink,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                        title: Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${member.parente}\n${member.lieuNaissance} • ${member.dateNaissance}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) => action == 'edit'
                              ? _editMember(member)
                              : _deleteMember(member),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Modifier'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Supprimer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      }
      return PageBody(children: children);
    },
  );

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }
}

class _FamilyMemberDialog extends StatefulWidget {
  const _FamilyMemberDialog({this.member});

  final FamilyMember? member;

  @override
  State<_FamilyMemberDialog> createState() => _FamilyMemberDialogState();
}

class _FamilyMemberDialogState extends State<_FamilyMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nom;
  late final TextEditingController _postnom;
  late final TextEditingController _prenom;
  late final TextEditingController _lieu;
  late final TextEditingController _parente;
  DateTime? _date;
  String? _dateError;
  XFile? _image;
  Uint8List? _imageBytes;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    _nom = TextEditingController(text: member?.nom ?? '');
    _postnom = TextEditingController(text: member?.postnom ?? '');
    _prenom = TextEditingController(text: member?.prenom ?? '');
    _lieu = TextEditingController(text: member?.lieuNaissance ?? '');
    _parente = TextEditingController(text: member?.parente ?? '');
    _date = member == null ? null : DateTime.tryParse(member.dateNaissance);
  }

  @override
  void dispose() {
    _nom.dispose();
    _postnom.dispose();
    _prenom.dispose();
    _lieu.dispose();
    _parente.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _date = picked;
      _dateError = null;
    });
  }

  Future<void> _chooseImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (image == null) return;
      if (!mounted) return;

      final extension = image.name.contains('.')
          ? image.name.split('.').last.toLowerCase()
          : '';
      if (!const {'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(extension)) {
        setState(() => _imageError = 'Format accepté : JPG, PNG, GIF ou WebP.');
        return;
      }

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 2 * 1024 * 1024) {
        setState(() => _imageError = 'La photo ne doit pas dépasser 2 Mo.');
        return;
      }
      setState(() {
        _image = image;
        _imageBytes = bytes;
        _imageError = null;
      });
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _imageError = 'Impossible de lire la photo : $error');
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      setState(() => _dateError = 'Choisissez une date.');
      return;
    }
    final member = widget.member;
    Navigator.of(context).pop((
      FamilyMember(
        id: member?.id ?? 0,
        nom: _nom.text.trim(),
        postnom: _postnom.text.trim(),
        prenom: _prenom.text.trim(),
        lieuNaissance: _lieu.text.trim(),
        dateNaissance: _date!.toIso8601String().substring(0, 10),
        parente: _parente.text.trim(),
        imageUrl: member?.imageUrl,
      ),
      _image,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final fields = <(String, TextEditingController)>[
      ('Nom', _nom),
      ('Postnom', _postnom),
      ('Prénom', _prenom),
      ('Lieu de naissance', _lieu),
      ('Parenté', _parente),
    ];
    return AlertDialog(
      title: Text(
        widget.member == null ? 'Ajouter un membre' : 'Modifier un membre',
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: field.$2,
                      decoration: InputDecoration(labelText: field.$1),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Champ obligatoire.'
                          : null,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Row(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 68,
                          height: 68,
                          child: _imageBytes != null
                              ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                              : widget.member?.imageUrl != null
                              ? MemberPhoto(
                                  url: widget.member!.imageUrl!,
                                  size: 68,
                                  placeholder: _emptyPhoto(),
                                )
                              : _emptyPhoto(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _chooseImage,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: Text(
                            _image != null || widget.member?.imageUrl != null
                                ? 'Changer la photo'
                                : 'Ajouter une photo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_imageError != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _imageError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _date == null
                        ? 'Date de naissance'
                        : 'Né(e) le ${_date!.toIso8601String().substring(0, 10)}',
                  ),
                  trailing: const Icon(Icons.calendar_month),
                  subtitle: _dateError == null
                      ? null
                      : Text(
                          _dateError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                  onTap: _selectDate,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Enregistrer')),
      ],
    );
  }

  Widget _emptyPhoto() => ColoredBox(
    color: const Color(0xffe7eef6),
    child: Icon(
      Icons.person_outline,
      color: AppTheme.ink.withValues(alpha: .7),
    ),
  );
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir cette application ou ce lien.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      Text(
        'Restons en contact',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      Text(
        'Choisissez un moyen de me joindre.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 12),
      ContactTile(
        icon: Icons.phone_outlined,
        title: 'Téléphone',
        value: contactPhone,
        onTap: () => _open(
          context,
          Uri(scheme: 'tel', path: contactPhone.replaceAll(' ', '')),
        ),
      ),
      ContactTile(
        icon: Icons.email_outlined,
        title: 'E-mail',
        value: contactEmail,
        onTap: () => _open(context, Uri(scheme: 'mailto', path: contactEmail)),
      ),
      ContactTile(
        icon: Icons.location_on_outlined,
        title: 'Adresse',
        value: contactAddress,
        onTap: () => _open(
          context,
          Uri.https('maps.google.com', '/', {'q': contactLocation}),
        ),
      ),
      ContactTile(
        icon: Icons.link,
        title: 'LinkedIn',
        value: contactLinkedIn,
        onTap: () => _open(context, Uri.parse(contactLinkedIn)),
      ),
      ContactTile(
        icon: Icons.code,
        title: 'GitHub',
        value: contactGitHub,
        onTap: () => _open(context, Uri.parse(contactGitHub)),
      ),
    ],
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: children,
        ),
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {required this.icon, super.key});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, color: AppTheme.blue),
        const SizedBox(width: 9),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    ),
  );
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: AppTheme.blue),
      title: Text(title),
      subtitle: Text(subtitle),
    ),
  );
}

class TimelineCard extends StatelessWidget {
  const TimelineCard({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.icon,
    super.key,
  });
  final String title;
  final String subtitle;
  final String body;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.blue),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.blue),
                ),
                const SizedBox(height: 7),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class SkillTile extends StatelessWidget {
  const SkillTile({required this.skill, super.key});
  final SkillItem skill;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(skill.name)),
              Text('${(skill.level * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 9),
          LinearProgressIndicator(
            value: skill.level,
            minHeight: 6,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    ),
  );
}

class ContactTile extends StatelessWidget {
  const ContactTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color(0xffe7eef6),
        child: Icon(icon, color: AppTheme.ink),
      ),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.open_in_new, size: 18),
    ),
  );
}
