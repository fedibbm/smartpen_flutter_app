import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _schoolController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isEditing = false;
  String _selectedReadingLevelKey = 'readingLevelBeginner';
  String _selectedFontSizeKey = 'fontSizeMedium';
  List<String> _selectedDifficultyKeys = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    _nameController.text = 'sami ben salah';
    _ageController.text = '16';
    _emailController.text = 'bensalah.sami@email.com';
    _schoolController.text = 'Lycée 18 janvier';
    _notesController.text = 'Works best with simplified text and audio support.';
    _selectedReadingLevelKey = 'readingLevelIntermediate';
    _selectedFontSizeKey = 'fontSizeLarge';
    _selectedDifficultyKeys = ['difficultyLetterReversals', 'difficultyReadingSpeed'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readingLevelKeys = ['readingLevelBeginner', 'readingLevelIntermediate', 'readingLevelAdvanced'];
    final fontSizeKeys = ['fontSizeSmall', 'fontSizeMedium', 'fontSizeLarge', 'fontSizeExtraLarge'];
    final difficultyKeys = [
      'difficultyLetterReversals',
      'difficultyWordRecognition',
      'difficultyReadingSpeed',
      'difficultyComprehension',
      'difficultySpelling',
      'difficultyWritingOrg',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('userProfile')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  _saveProfile();
                }
                _isEditing = !_isEditing;
              });
            },
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            tooltip: _isEditing ? context.tr('saveChanges') : context.tr('editProfile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(context.tr('photoSelectionComingSoon')),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _nameController.text.isEmpty ? context.tr('userName') : _nameController.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              _buildSectionCard(
                title: context.tr('personalInformation'),
                icon: Icons.person_outline,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: context.tr('fullName'),
                    icon: Icons.person,
                    enabled: _isEditing,
                    context: context,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ageController,
                    label: context.tr('age'),
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                    enabled: _isEditing,
                    context: context,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: context.tr('email'),
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    enabled: _isEditing,
                    context: context,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _schoolController,
                    label: context.tr('schoolInstitution'),
                    icon: Icons.school,
                    enabled: _isEditing,
                    context: context,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildSectionCard(
                title: context.tr('readingPreferences'),
                icon: Icons.auto_stories,
                children: [
                  _buildDropdownField(
                    label: context.tr('readingLevel'),
                    value: _selectedReadingLevelKey,
                    items: readingLevelKeys,
                    onChanged: _isEditing ? (value) {
                      setState(() {
                        _selectedReadingLevelKey = value!;
                      });
                    } : null,
                    context: context,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: context.tr('preferredFontSize'),
                    value: _selectedFontSizeKey,
                    items: fontSizeKeys,
                    onChanged: _isEditing ? (value) {
                      setState(() {
                        _selectedFontSizeKey = value!;
                      });
                    } : null,
                    context: context,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildSectionCard(
                title: context.tr('learningChallenges'),
                icon: Icons.psychology,
                children: [
                  Text(
                    context.tr('selectChallengingAreas'),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ...difficultyKeys.map((difficultyKey) {
                    return CheckboxListTile(
                      title: Text(context.tr(difficultyKey)),
                      value: _selectedDifficultyKeys.contains(difficultyKey),
                      onChanged: _isEditing ? (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedDifficultyKeys.add(difficultyKey);
                          } else {
                            _selectedDifficultyKeys.remove(difficultyKey);
                          }
                        });
                      } : null,
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildSectionCard(
                title: context.tr('additionalNotes'),
                icon: Icons.note_outlined,
                children: [
                  _buildTextField(
                    controller: _notesController,
                    label: context.tr('notesHint'),
                    icon: Icons.note,
                    maxLines: 4,
                    enabled: _isEditing,
                    context: context,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _loadUserProfile();
                          });
                        },
                        child: Text(context.tr('cancel')),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(context.tr('saveChanges')),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(context.tr('editProfile')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required BuildContext context,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade100,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return context.tr('thisFieldIsRequired');
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required BuildContext context,
    ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: onChanged == null,
        fillColor: onChanged == null ? Colors.grey.shade100 : null,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(context.tr(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('profileSaved')),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _isEditing = false;
      });
    }
  }
}
